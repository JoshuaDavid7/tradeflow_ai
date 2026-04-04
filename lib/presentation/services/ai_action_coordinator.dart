import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/voice_repository.dart';
import '../../data/services/ai_command_service.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/job.dart';
import '../../screens/draft_review_screen.dart';
import '../../screens/project_notes_screen.dart';
import '../../screens/settings_screen.dart';
import '../providers/analytics_provider.dart';
import '../providers/customer_ledger_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/job_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/customer_ledger/customer_detail_screen.dart';
import '../screens/customer_ledger/note_editor_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../widgets/record_payment_sheet.dart';

final aiActionCoordinatorProvider = Provider<AiActionCoordinator>((ref) {
  return AiActionCoordinator(ref);
});

class AiActionCoordinator {
  final Ref _ref;

  const AiActionCoordinator(this._ref);

  Future<void> execute(
    BuildContext context,
    AiCommandResult result,
  ) async {
    switch (result.action) {
      case 'navigate':
        _handleNavigate(context, result.params);
        break;
      case 'create_invoice':
        await _handleCreateInvoice(context, result);
        break;
      case 'create_expense':
        _handleCreateExpense(context, result.params);
        break;
      case 'record_payment':
        await _handleRecordPayment(context, result.params);
        break;
      case 'update_settings':
        await _handleUpdateSettings(result.params);
        break;
      case 'create_note':
        _handleCreateNote(context, result.params);
        break;
      case 'answer':
        break;
    }
  }

  void _handleNavigate(BuildContext context, Map<String, dynamic> params) {
    final screen = params['screen']?.toString().trim() ?? '';
    final clientName = params['clientName']?.toString().trim() ?? '';
    const tabMap = {
      'home': 0,
      'jobs': 1,
      'expenses': 2,
      'clients': 3,
      'analytics': 4,
    };

    if (tabMap.containsKey(screen)) {
      _ref.read(bottomNavIndexProvider.notifier).state = tabMap[screen]!;
      if (screen == 'clients' && clientName.isNotEmpty) {
        _openClientIfKnown(context, clientName);
      }
      return;
    }

    if (screen == 'drafts') {
      _ref.read(historyInitialTabProvider.notifier).state = 1;
      _ref.read(bottomNavIndexProvider.notifier).state = 1;
      return;
    }

    if (screen == 'sent') {
      _ref.read(historyInitialTabProvider.notifier).state = 2;
      _ref.read(bottomNavIndexProvider.notifier).state = 1;
      return;
    }

    if (screen == 'paid') {
      _ref.read(historyInitialTabProvider.notifier).state = 3;
      _ref.read(bottomNavIndexProvider.notifier).state = 1;
      return;
    }

    if (screen == 'settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }

    if (screen == 'notes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectNotesScreen()),
      );
    }
  }

  Future<void> _handleCreateInvoice(
    BuildContext context,
    AiCommandResult result,
  ) async {
    final params = result.params;
    final fallback = <String, dynamic>{
      'clientName': _resolveKnownCustomerName(
        params['clientName']?.toString() ?? '',
      ),
      'type': params['type'] ?? 'invoice',
      'description': params['description'] ?? '',
      'laborHours': params['laborHours'] ?? 1.0,
      'laborType': params['laborType'] ?? 'profile',
      'materials': _normalizeVoiceMaterials(
        params['materials'],
        params['description']?.toString() ?? '',
      ),
    };

    if (params['laborRate'] != null) {
      fallback['laborRate'] = params['laborRate'];
    }
    if (params['laborAmount'] != null) {
      fallback['laborAmount'] = params['laborAmount'];
    }

    Map<String, dynamic> jobData = fallback;
    final transcript = result.transcript?.trim() ?? '';
    if (transcript.isNotEmpty) {
      try {
        final extracted = await _ref.read(voiceRepositoryProvider).extractJobData(
              transcript,
              knownCustomers: _knownCustomerNames(),
            );
        jobData = _mergeInvoiceDrafts(
          fallback: fallback,
          extracted: extracted,
        );
      } catch (_) {
        jobData = fallback;
      }
    }

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DraftReviewScreen(jobData: jobData),
      ),
    );
  }

  void _handleCreateExpense(BuildContext context, Map<String, dynamic> params) {
    final category = _resolveExpenseCategory(params['category']?.toString());
    final shouldLinkToJob = params['linkToJob'] == true ||
        (params['clientName']?.toString().trim().isNotEmpty ?? false) ||
        (params['jobName']?.toString().trim().isNotEmpty ?? false);
    final matchedJob = shouldLinkToJob
        ? _findBestJobMatch(
            clientName: params['clientName']?.toString() ?? '',
            jobName: params['jobName']?.toString() ?? '',
          )
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          jobId: matchedJob?.id,
          initialData: {
            'amount': params['amount'],
            'description': params['description'],
            'vendor': params['vendor'],
            'category': category.name,
            'taxDeductible': params.containsKey('taxDeductible')
                ? params['taxDeductible'] == true
                : category.taxDeductible,
          },
        ),
      ),
    );
  }

  Future<void> _handleRecordPayment(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    _ref.read(historyInitialTabProvider.notifier).state = 2;
    _ref.read(historyOutstandingFilterProvider.notifier).state = true;
    _ref.read(bottomNavIndexProvider.notifier).state = 1;

    final client = _resolveKnownCustomerName(
      params['clientName']?.toString() ?? '',
    );
    final amount = _asDouble(params['amount']);
    final method = _normalizePaymentMethod(params['method']?.toString());
    final messenger = ScaffoldMessenger.of(context);

    final match = _findBestOutstandingJob(
      clientName: client,
      amount: amount,
    );

    if (match != null && context.mounted) {
      final recorded = await showRecordPaymentSheet(
        context,
        jobId: match.id,
        totalAmount: match.totalAmount,
        amountPaid: match.amountPaid,
        clientName: match.clientName,
        initialAmount: amount > 0 ? amount : null,
        initialMethod: method,
      );

      if (!context.mounted) {
        return;
      }

      if (recorded == true) {
        _invalidateProviders();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Recorded \$${amount > 0 ? amount.toStringAsFixed(2) : match.amountDue.toStringAsFixed(2)} '
              'payment for ${match.clientName}.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          client.isEmpty
              ? 'Open an outstanding invoice to record this payment.'
              : 'Open $client from Sent invoices to record '
                  '${amount > 0 ? '\$${amount.toStringAsFixed(2)} ' : ''}'
                  '${method.isNotEmpty ? '$method ' : ''}payment.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleUpdateSettings(Map<String, dynamic> params) async {
    try {
      final profileState = _ref.read(profileProvider);
      final current = profileState.profile;
      if (current == null) {
        return;
      }

      final updated = current.copyWith(
        defaultHourlyRate: params['hourlyRate'] != null
            ? (params['hourlyRate'] as num).toDouble()
            : null,
        defaultTaxRate: params['taxRate'] != null
            ? (params['taxRate'] as num).toDouble()
            : null,
        defaultMarkupPercent: params['markupPercent'] != null
            ? (params['markupPercent'] as num).toDouble()
            : null,
      );

      await _ref.read(profileProvider.notifier).updateProfile(updated);
    } catch (_) {
      // Provider handles the surfaced error state.
    }
  }

  void _handleCreateNote(BuildContext context, Map<String, dynamic> params) {
    final requestedClientName = params['clientName']?.toString().trim() ?? '';
    final matchedCustomer = requestedClientName.isEmpty
        ? null
        : _findBestCustomerMatch(requestedClientName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          customerId: matchedCustomer?['id']?.toString() ?? '',
          customerName: matchedCustomer?['name']?.toString() ??
              (requestedClientName.isNotEmpty
                  ? requestedClientName
                  : 'General note'),
          initialTitle: params['title']?.toString(),
          initialContent: params['content']?.toString(),
        ),
      ),
    );
  }

  void _openClientIfKnown(BuildContext context, String clientName) {
    final match = _findBestCustomerMatch(clientName);
    if (match == null || !context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: match),
      ),
    );
  }

  Map<String, dynamic> _mergeInvoiceDrafts({
    required Map<String, dynamic> fallback,
    required Map<String, dynamic> extracted,
  }) {
    final merged = <String, dynamic>{...fallback, ...extracted};
    if ((merged['clientName']?.toString().trim().isEmpty ?? true)) {
      merged['clientName'] = fallback['clientName'];
    }
    if (merged['type'] == null) {
      merged['type'] = fallback['type'];
    }
    if (merged['description'] == null) {
      merged['description'] = fallback['description'];
    }
    if (merged['laborHours'] == null) {
      merged['laborHours'] = fallback['laborHours'];
    }
    if (merged['laborType'] == null) {
      merged['laborType'] = fallback['laborType'];
    }
    if (merged['materials'] is! List) {
      merged['materials'] = fallback['materials'];
    }
    return merged;
  }

  List<String> _knownCustomerNames() {
    final customers = _ref.read(customerLedgerListProvider);
    return customers.whenOrNull(
          data: (list) => list
              .map((customer) => customer['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(),
        ) ??
        const <String>[];
  }

  ExpenseCategory _resolveExpenseCategory(String? rawCategory) {
    final category = (rawCategory ?? '').trim();
    return ExpenseCategory.values.firstWhere(
      (value) => value.name == category,
      orElse: () => ExpenseCategory.materials,
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final costs = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      var previous = costs[0];
      costs[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final current = costs[j];
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        costs[j] = [
          costs[j] + 1,
          costs[j - 1] + 1,
          previous + substitutionCost,
        ].reduce((left, right) => left < right ? left : right);
        previous = current;
      }
    }
    return costs[b.length];
  }

  int _scoreTextMatch(String query, Iterable<String> candidates) {
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) {
      return 99;
    }

    var bestScore = 99;
    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeText(candidate);
      if (normalizedCandidate.isEmpty) {
        continue;
      }

      var score = 99;
      if (normalizedCandidate == normalizedQuery) {
        score = 0;
      } else if (normalizedCandidate.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedCandidate)) {
        score = 1;
      } else {
        final distance =
            _levenshteinDistance(normalizedCandidate, normalizedQuery);
        final maxLength = normalizedCandidate.length > normalizedQuery.length
            ? normalizedCandidate.length
            : normalizedQuery.length;
        if (distance <= 2 || distance <= (maxLength / 4).round()) {
          score = 3 + distance;
        }
      }

      if (score < bestScore) {
        bestScore = score;
      }
    }

    return bestScore;
  }

  Map<String, dynamic>? _findBestCustomerMatch(String rawQuery) {
    final query = _normalizeText(rawQuery);
    if (query.isEmpty) {
      return null;
    }

    final customers = _ref.read(customerLedgerListProvider);
    final items = customers.whenOrNull(data: (list) => list);
    if (items == null || items.isEmpty) {
      return null;
    }

    Map<String, dynamic>? bestMatch;
    var bestScore = 999;

    for (final customer in items) {
      final score =
          _scoreTextMatch(query, [(customer['name'] ?? '').toString()]);
      if (score < bestScore) {
        bestScore = score;
        bestMatch = customer;
      }
    }

    return bestScore <= 4 ? bestMatch : null;
  }

  String _resolveKnownCustomerName(String rawName) {
    final match = _findBestCustomerMatch(rawName);
    if (match == null) {
      return rawName.trim();
    }
    return (match['name'] ?? rawName).toString().trim();
  }

  String _normalizePaymentMethod(String? rawMethod) {
    final method = (rawMethod ?? '').trim().toLowerCase();
    switch (method) {
      case 'cash':
      case 'card':
      case 'check':
      case 'zelle':
      case 'venmo':
      case 'cash_app':
      case 'paypal':
      case 'bank_transfer':
      case 'stripe':
      case 'other':
        return method;
      default:
        return method.isEmpty ? '' : 'other';
    }
  }

  List<Map<String, dynamic>> _normalizeVoiceMaterials(
    dynamic rawMaterials,
    String description,
  ) {
    if (rawMaterials is! List) {
      return const <Map<String, dynamic>>[];
    }

    final descriptionLower = description.toLowerCase();
    return rawMaterials.map<Map<String, dynamic>>((item) {
      final material =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final rawName = (material['item'] ?? '').toString().trim();
      final normalized = _normalizeText(rawName);

      if ({
        'filling',
        'fillings',
        'fizzing',
        'fizzings',
        'quidding',
        'quiddings',
      }.contains(normalized)) {
        material['item'] = 'Fittings';
      } else if ({
        'keter',
        'keater',
        'heeter',
        'heater',
        'heaters',
      }.contains(normalized)) {
        material['item'] = normalized.endsWith('s') ? 'Heaters' : 'Heater';
      } else if (normalized == 'people' &&
          (descriptionLower.contains('hot water system') ||
              descriptionLower.contains('water heater'))) {
        material['item'] = 'Heater';
      }

      return material;
    }).toList();
  }

  Job? _findBestJobMatch({
    required String clientName,
    required String jobName,
  }) {
    final jobs = _ref.read(jobListProvider).jobs;
    if (jobs.isEmpty) {
      return null;
    }

    final hasClientQuery = clientName.trim().isNotEmpty;
    final hasJobQuery = jobName.trim().isNotEmpty;
    if (!hasClientQuery && !hasJobQuery) {
      return null;
    }

    final candidates = <({Job job, int score})>[];
    for (final job in jobs) {
      var score = job.status.isActive ? 0 : 3;
      if (hasClientQuery) {
        score += _scoreTextMatch(
          clientName,
          [job.clientName, job.title],
        );
      }
      if (hasJobQuery) {
        score += _scoreTextMatch(
          jobName,
          [job.title, job.description ?? '', job.trade ?? '', job.clientName],
        );
      }
      candidates.add((job: job, score: score));
    }

    candidates.sort((left, right) {
      final scoreCompare = left.score.compareTo(right.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      if (left.job.status.isActive != right.job.status.isActive) {
        return left.job.status.isActive ? -1 : 1;
      }
      return right.job.createdAt.compareTo(left.job.createdAt);
    });

    final best = candidates.first;
    return best.score <= (hasClientQuery && hasJobQuery ? 8 : 4)
        ? best.job
        : null;
  }

  Job? _findBestOutstandingJob({
    required String clientName,
    required double amount,
  }) {
    final jobs = _ref.read(jobListProvider).jobs.where((job) {
      return job.isAwaitingPayment;
    }).toList();

    if (jobs.isEmpty) {
      return null;
    }

    final query = _normalizeText(clientName);
    final candidates = <({Job job, int score, double amountDelta})>[];

    for (final job in jobs) {
      final name = _normalizeText(job.clientName);
      final title = _normalizeText(job.title);

      var score = 99;
      if (query.isEmpty) {
        score = jobs.length == 1 ? 0 : 50;
      } else if (name == query || title == query) {
        score = 0;
      } else if (name.contains(query) || query.contains(name)) {
        score = 1;
      } else if (title.contains(query) || query.contains(title)) {
        score = 2;
      } else {
        final distance = _levenshteinDistance(name, query);
        final maxLength = name.length > query.length ? name.length : query.length;
        if (distance <= 2 || distance <= (maxLength / 4).round()) {
          score = 3 + distance;
        }
      }

      if (score >= 50) {
        continue;
      }

      final due =
          job.amountDue > 0 ? job.amountDue : job.totalAmount - job.amountPaid;
      final amountDelta = amount > 0 ? (due - amount).abs() : due;
      candidates.add((job: job, score: score, amountDelta: amountDelta));
    }

    if (candidates.isEmpty) {
      if (query.isEmpty && jobs.length == 1) {
        return jobs.first;
      }
      return null;
    }

    candidates.sort((left, right) {
      final scoreCompare = left.score.compareTo(right.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return left.amountDelta.compareTo(right.amountDelta);
    });

    final best = candidates.first;
    return best.score <= 5 ? best.job : null;
  }

  void _invalidateProviders() {
    _ref.invalidate(jobStatsProvider);
    _ref.invalidate(jobListProvider);
    _ref.invalidate(customerLedgerListProvider);
    _ref.invalidate(expenseStatsProvider);
    _ref.read(analyticsProvider.notifier).refresh();
  }
}
