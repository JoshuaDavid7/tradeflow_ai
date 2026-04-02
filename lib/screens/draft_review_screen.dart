import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/pdf_service.dart';
import '../services/payment_service.dart';
import '../services/template_service.dart';
import '../models/business_profile.dart';
import '../models/invoice_template.dart';
import '../domain/models/receipt.dart' as domain_receipt;
import '../data/services/receipt_ai_service.dart';
import '../presentation/screens/receipts/receipt_scanner_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/errors/app_exception.dart' as app_exceptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/job_provider.dart';
import '../presentation/providers/analytics_provider.dart';
import '../presentation/providers/customer_ledger_provider.dart';
import '../presentation/providers/voice_provider.dart';
import '../data/services/voice_capture_service.dart';
import '../data/repositories/material_cost_repository.dart';
import '../domain/models/expense.dart';
import '../presentation/providers/expense_provider.dart';
import 'pdf_preview_screen.dart';

class DraftReviewScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const DraftReviewScreen({super.key, required this.jobData});

  @override
  State<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _DraftReviewScreenState extends State<DraftReviewScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _editableData;
  bool _isSaving = false;
  bool _isGeneratingSecurePdf = false;
  bool _invoiceNumberEditedByUser = false;
  bool _isDirty = false;
  BusinessProfile? _profile;

  // Markup
  double _markupPercent = 0.0;
  final _markupCtrl = TextEditingController(text: '0');

  // Stripe payment toggle
  bool _includeStripePayment = false;
  bool _stripeOverrideActive = false;
  String? _stripeAvailability; // null = available, or error code

  late TextEditingController _clientCtrl;
  late TextEditingController _clientAddressCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _clientEmailCtrl;
  late TextEditingController _invoiceNumberCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _laborHoursCtrl;

  @override
  void initState() {
    super.initState();
    _editableData = Map<String, dynamic>.from(widget.jobData);
    _editableData['clientName'] = (_editableData['clientName'] ??
            _editableData['client_name'] ??
            _editableData['title'] ??
            '')
        .toString();
    _editableData['laborHours'] =
        (_editableData['laborHours'] ?? _editableData['labor_hours'] ?? 1.0);
    // Ensure 'type' always has a valid string value — Gemini may omit it
    _editableData['type'] = (widget.jobData['type'] as String?) ?? 'invoice';
    _editableData['materials'] = List<Map<String, dynamic>>.from(
        (widget.jobData['materials'] as List? ?? []).map((m) {
      final mat = Map<String, dynamic>.from(m as Map);
      // Ensure every material has a stable UUID for cost tracking.
      mat['id'] ??= const Uuid().v4();
      return mat;
    }));

    _clientCtrl =
        TextEditingController(text: _editableData['clientName'] ?? '');
    _clientAddressCtrl = TextEditingController(
      text: (_editableData['clientAddress'] ??
              _editableData['client_address'] ??
              '')
          .toString(),
    );
    _clientPhoneCtrl = TextEditingController(
      text:
          (_editableData['clientPhone'] ?? _editableData['client_phone'] ?? '')
              .toString(),
    );
    _clientEmailCtrl = TextEditingController(
      text:
          (_editableData['clientEmail'] ?? _editableData['client_email'] ?? '')
              .toString(),
    );
    final initialInvoiceNumber = (_editableData['invoiceNumber'] ??
            _editableData['invoice_number'] ??
            '')
        .toString()
        .trim();
    final displayInvoiceNumber = initialInvoiceNumber.isNotEmpty
        ? initialInvoiceNumber
        : _fallbackInvoiceNumberFromId(_editableData['id']?.toString());
    _invoiceNumberCtrl = TextEditingController(text: displayInvoiceNumber);
    if (displayInvoiceNumber.isNotEmpty) {
      _editableData['invoiceNumber'] = displayInvoiceNumber;
      _editableData['invoice_number'] = displayInvoiceNumber;
    }
    _descCtrl = TextEditingController(text: _editableData['description'] ?? '');
    _laborHoursCtrl = TextEditingController(
        text: _editableData['laborHours']?.toString() ?? '1.0');
    _primeInvoiceNumberPreview();
    _loadProfile();
    _loadTemplate();
    _loadCustomers();

    // Track unsaved changes
    void markDirty() {
      if (!_isDirty) setState(() => _isDirty = true);
    }

    _clientCtrl.addListener(markDirty);
    _clientAddressCtrl.addListener(markDirty);
    _clientPhoneCtrl.addListener(markDirty);
    _clientEmailCtrl.addListener(markDirty);
    _descCtrl.addListener(markDirty);
    _laborHoursCtrl.addListener(markDirty);
    _markupCtrl.addListener(markDirty);
  }

  List<Map<String, dynamic>> _customers = [];

  Future<void> _loadCustomers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('name');
      if (mounted) {
        final customers = List<Map<String, dynamic>>.from(data as List)
          ..sort((a, b) => (a['name']?.toString().trim().toLowerCase() ?? '')
              .compareTo(b['name']?.toString().trim().toLowerCase() ?? ''));
        setState(() {
          _customers = customers;
        });
        // Auto-match existing customer if client name matches
        _autoMatchCustomer();
      }
    } catch (e) {
      debugPrint('Worksheet: customer list fetch failed: $e');
    }
  }

  void _autoMatchCustomer() {
    final clientName = _clientCtrl.text.trim().toLowerCase();
    if (clientName.isEmpty) return;
    // Already linked?
    final existingId =
        (_editableData['customer_id'] ?? _editableData['customerId'])
            ?.toString()
            .trim();
    if (existingId != null && existingId.isNotEmpty) return;

    for (final c in _customers) {
      if ((c['name'] ?? '').toString().trim().toLowerCase() == clientName) {
        _editableData['customer_id'] = c['id'];
        _editableData['customerId'] = c['id'];
        break;
      }
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _editableData['customer_id'] = customer['id'];
      _editableData['customerId'] = customer['id'];
      _clientCtrl.text = customer['name'] ?? '';
      if (customer['address'] != null &&
          customer['address'].toString().isNotEmpty &&
          _clientAddressCtrl.text.trim().isEmpty) {
        _clientAddressCtrl.text = customer['address'];
      }
      if (customer['phone'] != null &&
          customer['phone'].toString().isNotEmpty &&
          _clientPhoneCtrl.text.trim().isEmpty) {
        _clientPhoneCtrl.text = customer['phone'];
      }
      if (customer['email'] != null &&
          customer['email'].toString().isNotEmpty &&
          _clientEmailCtrl.text.trim().isEmpty) {
        _clientEmailCtrl.text = customer['email'];
      }
    });
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientEmailCtrl.dispose();
    _invoiceNumberCtrl.dispose();
    _descCtrl.dispose();
    _laborHoursCtrl.dispose();
    _markupCtrl.dispose();
    super.dispose();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  String _sanitizeInvoicePrefix(String? rawPrefix) {
    final isQuote = (_editableData['type']?.toString() ?? 'invoice') == 'quote';
    final fallback = isQuote
        ? (_profile?.quotePrefix ?? 'QUO')
        : (_profile?.invoicePrefix ?? 'INV');
    final cleaned = (rawPrefix ?? '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _formatInvoiceNumber({
    required int sequence,
    String prefix = 'INV',
  }) {
    return '$prefix-${sequence.toString().padLeft(4, '0')}';
  }

  String _fallbackInvoiceNumberFromId(String? rawId) {
    final id = (rawId ?? '').trim();
    if (id.length < 8) return '';
    final isQuote = (_editableData['type']?.toString() ?? 'invoice') == 'quote';
    final prefix = isQuote
        ? (_profile?.quotePrefix ?? 'QUO')
        : (_profile?.invoicePrefix ?? 'INV');
    return '$prefix-${id.substring(0, 6).toUpperCase()}';
  }

  Future<void> _primeInvoiceNumberPreview() async {
    final hasExistingJobId =
        (_editableData['id']?.toString().trim().isNotEmpty ?? false);
    final hasExistingInvoice = _invoiceNumberCtrl.text.trim().isNotEmpty;
    if (hasExistingJobId || hasExistingInvoice) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    try {
      final row = await _supabase
          .from('profiles')
          .select('invoice_prefix, quote_prefix, next_invoice_number')
          .eq('id', userId)
          .maybeSingle();

      final nextNumber = _toInt(row?['next_invoice_number']) ?? 1;
      final isQuote =
          (_editableData['type']?.toString() ?? 'invoice') == 'quote';
      final prefix = isQuote
          ? _sanitizeInvoicePrefix(row?['quote_prefix']?.toString())
          : _sanitizeInvoicePrefix(row?['invoice_prefix']?.toString());
      final previewNumber =
          _formatInvoiceNumber(sequence: nextNumber, prefix: prefix);

      if (!mounted) return;
      setState(() {
        _invoiceNumberCtrl.text = previewNumber;
        _editableData['invoiceNumber'] = previewNumber;
        _editableData['invoice_number'] = previewNumber;
      });
    } catch (e) {
      // Non-blocking: if migration isn't applied yet, user can still type manually.
      debugPrint('Invoice number preview failed (non-blocking): $e');
    }
  }

  Future<void> _reserveInvoiceSequenceIfNeeded({required String userId}) async {
    final existingSequence = _toInt(
      _editableData['invoiceSequence'] ?? _editableData['invoice_sequence'],
    );
    if (existingSequence != null) return;

    final hasExistingJobId =
        (_editableData['id']?.toString().trim().isNotEmpty ?? false);
    if (hasExistingJobId) return;

    try {
      final rpcResult = await _supabase.rpc('reserve_invoice_sequence');
      Map<String, dynamic>? payload;

      if (rpcResult is Map<String, dynamic>) {
        payload = rpcResult;
      } else if (rpcResult is List &&
          rpcResult.isNotEmpty &&
          rpcResult.first is Map) {
        payload = Map<String, dynamic>.from(rpcResult.first as Map);
      }
      if (payload == null) return;

      final sequence = _toInt(payload['invoice_sequence']);
      if (sequence == null) return;

      final isQuote =
          (_editableData['type']?.toString() ?? 'invoice') == 'quote';
      final prefix = isQuote
          ? _sanitizeInvoicePrefix(payload['quote_prefix']?.toString())
          : _sanitizeInvoicePrefix(payload['invoice_prefix']?.toString());
      final generatedNumber =
          _formatInvoiceNumber(sequence: sequence, prefix: prefix);

      _editableData['invoiceSequence'] = sequence;
      _editableData['invoice_sequence'] = sequence;

      if (!_invoiceNumberEditedByUser ||
          _invoiceNumberCtrl.text.trim().isEmpty) {
        _invoiceNumberCtrl.text = generatedNumber;
      }

      final chosenNumber = _invoiceNumberCtrl.text.trim();
      if (chosenNumber.isNotEmpty) {
        _editableData['invoiceNumber'] = chosenNumber;
        _editableData['invoice_number'] = chosenNumber;
      }
    } catch (e) {
      throw Exception(
        'Unable to reserve next invoice number. Run the latest Supabase migration, then try again. ($e)',
      );
    }
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data != null && mounted) {
      final profile = BusinessProfile.fromJson(data);
      setState(() {
        _profile = profile;
        // Apply default markup from profile if user hasn't changed it
        if (_markupPercent == 0.0 && profile.defaultMarkupPercent > 0) {
          _markupPercent = profile.defaultMarkupPercent;
          _markupCtrl.text = profile.defaultMarkupPercent.toString();
        }
      });
    }
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await TemplateService.loadTemplate();
      if (mounted && !_stripeOverrideActive) {
        setState(() {
          _includeStripePayment = _isStripeEnabledInTemplate(template);
        });
      }
    } catch (e) {
      debugPrint('Template load failed, keeping defaults: $e');
    }
    // Check Stripe availability in background
    _checkStripeAvailability();
  }

  Future<void> _checkStripeAvailability() async {
    try {
      final result = await PaymentService.checkStripeAvailability();
      if (mounted) setState(() => _stripeAvailability = result);
    } catch (e) {
      debugPrint('Stripe availability check failed: $e');
      if (mounted) setState(() => _stripeAvailability = 'unknown_error');
    }
  }

  double _calculateLabor() {
    final type = _editableData['laborType'] ?? 'profile';
    final hours = double.tryParse(_laborHoursCtrl.text) ?? 0.0;

    if (type == 'flat') {
      return (double.tryParse(
              _editableData['laborAmount']?.toString() ?? '0.0') ??
          0.0);
    } else if (type == 'hourly') {
      final rate =
          (double.tryParse(_editableData['laborRate']?.toString() ?? '0.0') ??
              0.0);
      return hours * rate;
    }
    return hours * (_profile?.hourlyRate ?? 85.0);
  }

  /// Returns the hourly rate actually used for this job — custom rate for
  /// 'hourly' type, profile rate for 'profile' type, or the profile rate
  /// as a fallback for 'flat' (flat-rate jobs don't use hourly rate, but we
  /// persist the profile rate for historical reference).
  double _effectiveHourlyRate() {
    final type = _editableData['laborType'] ?? 'profile';
    if (type == 'hourly') {
      return double.tryParse(_editableData['laborRate']?.toString() ?? '0') ??
          (_profile?.hourlyRate ?? 85.0);
    }
    return _profile?.hourlyRate ?? 85.0;
  }

  double _calculateTotal() {
    final labor = _calculateLabor();
    double materialsTotal = 0;
    final materials = _editableData['materials'];
    if (materials is List) {
      for (var m in materials) {
        if (m is Map) {
          materialsTotal +=
              (double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0);
        }
      }
    }
    final sub = labor + materialsTotal;
    final tax = sub * ((_profile?.taxRate ?? 0) / 100);
    return sub + tax;
  }

  void _syncEditableFromControllers() {
    _editableData['clientName'] = _clientCtrl.text.trim();
    _editableData['clientAddress'] = _clientAddressCtrl.text.trim();
    _editableData['clientPhone'] = _clientPhoneCtrl.text.trim();
    _editableData['clientEmail'] = _clientEmailCtrl.text.trim();
    _editableData['invoiceNumber'] = _invoiceNumberCtrl.text.trim();
    _editableData['invoice_number'] = _invoiceNumberCtrl.text.trim();
    _editableData['description'] = _descCtrl.text.trim();
    _editableData['laborHours'] = double.tryParse(_laborHoursCtrl.text) ?? 0.0;
  }

  Map<String, dynamic> _buildCurrentPdfData() {
    _syncEditableFromControllers();
    final data = Map<String, dynamic>.from(_editableData);
    // Pass default due days so PDF uses the configured payment term
    data['default_due_days'] = _profile?.defaultDueDays ?? 14;
    return data;
  }

  Map<String, dynamic> _buildJobPayload({required String userId}) {
    _syncEditableFromControllers();
    final total = _calculateTotal();
    final normalizedClientName =
        _editableData['clientName'].toString().trim().isNotEmpty
            ? _editableData['clientName'].toString().trim()
            : (_editableData['title']?.toString().trim().isNotEmpty ?? false)
                ? _editableData['title'].toString().trim()
                : 'Client';
    final invoiceSequence = _toInt(
      _editableData['invoiceSequence'] ?? _editableData['invoice_sequence'],
    );
    final invoiceNumber = (_editableData['invoiceNumber'] ??
            _editableData['invoice_number'] ??
            '')
        .toString()
        .trim();

    final customerId =
        (_editableData['customer_id'] ?? _editableData['customerId'])
            ?.toString()
            .trim();

    return {
      'user_id': userId,
      'client_name': normalizedClientName,
      'client_address': _editableData['clientAddress'],
      'client_phone': _editableData['clientPhone'],
      'client_email': _editableData['clientEmail'],
      if (customerId != null && customerId.isNotEmpty)
        'customer_id': customerId,
      'title': normalizedClientName,
      'description': _editableData['description'],
      'labor_hours': _editableData['laborHours'],
      'hourly_rate_at_time': _effectiveHourlyRate(),
      'tax_rate_at_time': _profile?.taxRate ?? 0,
      'materials': _editableData['materials'],
      'total_amount': total,
      // Carry-forward payments from a replaced original invoice.
      if ((_editableData['amount_paid'] as num?) != null &&
          (_editableData['amount_paid'] as num) > 0.01)
        'amount_paid': _editableData['amount_paid'],
      if ((_editableData['amount_paid'] as num?) != null &&
          (_editableData['amount_paid'] as num) > 0.01)
        'amount_due': total - (_editableData['amount_paid'] as num).toDouble(),
      'status': (_editableData['status']?.toString().trim().isNotEmpty ?? false)
          ? _editableData['status']
          : 'draft',
      'type': _editableData['type'],
      if (invoiceSequence != null) 'invoice_sequence': invoiceSequence,
      if (invoiceNumber.isNotEmpty) 'invoice_number': invoiceNumber,
      if ((_editableData['payment_provider']?.toString().isNotEmpty ?? false))
        'payment_provider': _editableData['payment_provider'],
      if ((_editableData['payment_checkout_url']?.toString().isNotEmpty ??
          false))
        'payment_checkout_url': _editableData['payment_checkout_url'],
      if ((_editableData['payment_checkout_session_id']
              ?.toString()
              .isNotEmpty ??
          false))
        'payment_checkout_session_id':
            _editableData['payment_checkout_session_id'],
      if ((_editableData['payment_status']?.toString().isNotEmpty ?? false))
        'payment_status': _editableData['payment_status'],
      if ((_editableData['payment_currency']?.toString().isNotEmpty ?? false))
        'payment_currency': _editableData['payment_currency'],
      if (_editableData['payment_amount_minor'] is int)
        'payment_amount_minor': _editableData['payment_amount_minor'],
      if ((_editableData['payment_checkout_expires_at']
              ?.toString()
              .isNotEmpty ??
          false))
        'payment_checkout_expires_at':
            _editableData['payment_checkout_expires_at'],
      if (_editableData['secure_payment_methods'] is List)
        'secure_payment_methods': _editableData['secure_payment_methods'],
      if ((_editableData['revision_of']?.toString().isNotEmpty ?? false))
        'revision_of': _editableData['revision_of'],
    };
  }

  bool _isStripeEnabledInTemplate(InvoiceTemplate template) {
    return template.preferredPaymentMethods
        .contains(InvoiceTemplate.paymentMethodStripe);
  }

  Future<String> _persistDraftJob({required bool popOnSuccess}) async {
    if (_clientCtrl.text.trim().isEmpty) {
      throw Exception('Client name is required');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception(
          'Please sign in again before saving or creating payment links.');
    }

    final existingId = _editableData['id']?.toString().trim() ?? '';

    if (existingId.isEmpty) {
      await _reserveInvoiceSequenceIfNeeded(userId: userId);
    }

    final payload = _buildJobPayload(userId: userId);

    if (existingId.isNotEmpty) {
      await _supabase
          .from('jobs')
          .update(Map<String, dynamic>.from(payload)..remove('user_id'))
          .eq('id', existingId)
          .eq('user_id', userId);
      // Auto-create/link customer in ledger
      await _ensureCustomerExists(userId: userId);
      _invalidateStatsProviders();
      if (popOnSuccess && mounted) {
        _isDirty = false;
        Navigator.pop(context);
      }
      return existingId;
    }

    final inserted =
        await _supabase.from('jobs').insert(payload).select('id').single();
    final newId = inserted['id']?.toString();
    if (newId == null || newId.isEmpty) {
      throw Exception('Job saved but no job ID was returned.');
    }
    _editableData['id'] = newId;

    // Auto-create customer in ledger
    await _ensureCustomerExists(userId: userId);
    _invalidateStatsProviders();

    if (popOnSuccess && mounted) {
      _isDirty = false;
      Navigator.pop(context);
    }
    return newId;
  }

  void _invalidateStatsProviders() {
    try {
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.invalidate(customerLedgerListProvider);
      container.read(analyticsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Provider invalidation failed: $e');
    }
  }

  Future<void> _ensureCustomerExists({required String userId}) async {
    final clientName = _clientCtrl.text.trim();
    if (clientName.isEmpty) return;

    // Check if customer_id is already set (already linked)
    final existingCustomerId =
        (_editableData['customer_id'] ?? _editableData['customerId'])
            ?.toString()
            .trim();
    if (existingCustomerId != null && existingCustomerId.isNotEmpty) {
      // Already linked — update the customer's updated_at timestamp
      try {
        await _supabase
            .from('customers')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existingCustomerId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Customer timestamp update failed (non-critical): $e');
      }
      return;
    }

    try {
      // Check if a customer with this name already exists
      final existing = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', userId)
          .ilike('name', clientName)
          .maybeSingle();

      String customerId;
      if (existing != null) {
        customerId = existing['id'].toString();
      } else {
        // Create a new customer — try with full columns first, fallback to base
        final now = DateTime.now().toIso8601String();
        final phone = _editableData['clientPhone']?.toString().trim();
        final email = _editableData['clientEmail']?.toString().trim();
        final address = _editableData['clientAddress']?.toString().trim();

        final fullPayload = <String, dynamic>{
          'id': const Uuid().v4(),
          'user_id': userId,
          'name': clientName,
          'phone': (phone != null && phone.isNotEmpty) ? phone : null,
          'email': (email != null && email.isNotEmpty) ? email : null,
          'address': (address != null && address.isNotEmpty) ? address : null,
          'total_billed': 0,
          'total_paid': 0,
          'balance': 0,
          'job_count': 1,
          'created_at': now,
          'updated_at': now,
        };

        Map<String, dynamic> newCustomer;
        try {
          newCustomer = await _supabase
              .from('customers')
              .insert(fullPayload)
              .select('id')
              .single();
        } catch (e) {
          debugPrint(
              'Customer insert with all columns failed, retrying without optional columns: $e');
          // Fallback: columns from migration might not exist yet
          fullPayload.remove('total_billed');
          fullPayload.remove('total_paid');
          fullPayload.remove('balance');
          fullPayload.remove('job_count');
          fullPayload.remove('updated_at');
          newCustomer = await _supabase
              .from('customers')
              .insert(fullPayload)
              .select('id')
              .single();
        }
        customerId = newCustomer['id'].toString();
      }

      // Link this job to the customer
      final jobId = _editableData['id']?.toString().trim();
      if (jobId != null && jobId.isNotEmpty) {
        await _supabase
            .from('jobs')
            .update({'customer_id': customerId})
            .eq('id', jobId)
            .eq('user_id', userId);
      }
      _editableData['customer_id'] = customerId;
      _editableData['customerId'] = customerId;
    } catch (e) {
      // Don't fail the job save if customer creation fails
      debugPrint('Auto-create customer failed: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) return false;
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Save Draft — persists current edits without changing status.
  /// If the document is already 'sent', the save preserves that status
  /// (never regresses back to 'draft').
  Future<void> _saveJob() async {
    if (_clientCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client name is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Preserve current status — do NOT force it to 'draft'.
      // _editableData['status'] is already set from widget.jobData on init,
      // so _buildJobPayload will use whatever the current status is.
      // For new documents it defaults to 'draft'; for existing sent documents
      // it stays 'sent'.
      await _persistDraftJob(popOnSuccess: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Could not save. Please check your connection and try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Send Invoice / Send Quote — the explicit send action.
  /// For revision drafts, shows a choice: Replace original or Send as additional.
  Future<void> _sendDocument() async {
    if (_clientCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client name is required')));
      return;
    }
    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Business profile not loaded. Please check Settings.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Block sending a $0 invoice (quotes are exempt — they're estimates)
    if ((_editableData['type']?.toString() ?? 'invoice') != 'quote') {
      if (_calculateTotal() <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Add line items before sending — invoice total is \$0')),
        );
        return;
      }
    }

    final revisionOf = _editableData['revision_of']?.toString();
    final isRevision = revisionOf != null && revisionOf.isNotEmpty;

    if (isRevision) {
      // Show choice dialog for revision drafts
      final choice = await _showRevisionSendChoice();
      if (choice == null) return; // User cancelled
      await _executeSend(replaceOriginal: choice == 'replace');
    } else {
      await _executeSend(replaceOriginal: false);
    }
  }

  /// Shows a bottom sheet asking whether to replace the original or send as
  /// an additional invoice.
  Future<String?> _showRevisionSendChoice() async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Send Revised Invoice',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'This invoice is a revision of a previously sent invoice.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'replace'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Replace original invoice'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cancels the original and carries forward any payments already received.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'additional'),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Send as additional invoice'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Both invoices remain active as separate receivables.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Executes the actual send flow.
  /// If [replaceOriginal] is true, cancels the original invoice and carries
  /// forward its payment amounts onto this revision.
  Future<void> _executeSend({required bool replaceOriginal}) async {
    setState(() => _isSaving = true);
    try {
      final revisionOf = _editableData['revision_of']?.toString();

      // If replacing, carry forward payments from the original before persisting.
      if (replaceOriginal && revisionOf != null && revisionOf.isNotEmpty) {
        await _carryForwardPaymentsAndCancelOriginal(revisionOf);
      }

      // 1. Mark as 'sent'.
      _editableData['status'] = 'sent';

      // 2. Persist the job (insert or update) with status = 'sent'.
      await _persistDraftJob(popOnSuccess: false);

      // 2b. Recognize material costs for non-quote invoices.
      final isQuote =
          (_editableData['type']?.toString() ?? 'invoice') == 'quote';
      if (!isQuote) {
        try {
          final materials = _editableData['materials'] as List? ?? [];
          final jobId = _editableData['id']?.toString() ?? '';
          final userId = _supabase.auth.currentUser?.id ?? '';
          if (materials.isNotEmpty && jobId.isNotEmpty && userId.isNotEmpty) {
            final mcRepo = ProviderScope.containerOf(context)
                .read(materialCostRepositoryProvider);
            await mcRepo.recognizeMaterialCosts(
              userId,
              jobId,
              materials,
              DateTime.now(),
            );

            // Auto-link pending expense from the receipt "Both" flow.
            final pendingLink = _editableData['_pendingExpenseLink'];
            if (pendingLink is Map && pendingLink['expenseId'] != null) {
              final costs = await mcRepo.getCostsForJob(jobId);
              for (final cost in costs) {
                await mcRepo.linkExpenseToCost(
                  cost.id,
                  pendingLink['expenseId'].toString(),
                  cost.provisionalCost,
                );
              }
            }
          }
        } catch (e) {
          // Non-fatal — cost recognition failure must not block send.
          debugPrint('Material cost recognition failed (non-fatal): $e');
        }
      }

      // 3. Generate and share the PDF.
      if (!isQuote && _includeStripePayment) {
        await _generateSecurePaymentPdf();
      } else {
        await _generatePlainPdf();
      }

      // 4. Pop the worksheet after share completes.
      if (mounted) {
        _isDirty = false;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not send. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Carries forward payments from the original invoice and cancels it.
  /// Sets amount_paid on this revision to the original's amount_paid so the
  /// PDF and balance reflect the carried amount.
  Future<void> _carryForwardPaymentsAndCancelOriginal(
      String originalJobId) async {
    try {
      // Fetch the original invoice's financial state.
      final original = await _supabase
          .from('jobs')
          .select('total_amount, amount_paid, amount_due')
          .eq('id', originalJobId)
          .maybeSingle();

      if (original == null) return;

      final originalPaid =
          double.tryParse(original['amount_paid']?.toString() ?? '0') ?? 0;

      // Carry forward the already-paid amount onto this revision.
      if (originalPaid > 0.01) {
        _editableData['amount_paid'] = originalPaid;
        // amount_due will be computed by _buildJobPayload or by the DB.
      }

      // Cancel the original invoice (mark as superseded).
      await _supabase.from('jobs').update({
        'status': 'cancelled',
      }).eq('id', originalJobId);

      // Supersede the original's recognized material costs so they are
      // not counted in analytics.  The new revision will create fresh costs.
      try {
        final mcRepo = ProviderScope.containerOf(context)
            .read(materialCostRepositoryProvider);
        await mcRepo.supersedeCostsForJob(originalJobId);
      } catch (e) {
        debugPrint('Material cost supersession failed (non-fatal): $e');
      }
    } catch (e) {
      debugPrint('Failed to carry forward payments: $e');
      // Non-fatal — the revision can still be sent without carry-forward.
    }
  }

  /// Preview PDF — opens PdfPreviewScreen with the current live worksheet state.
  /// Does NOT save the job. Does NOT change status. The user returns to the
  /// same editing session via the back button.
  void _previewPdf() async {
    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Business profile not loaded. Please check Settings.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    // Build PDF data from current in-memory worksheet state, not from Supabase.
    final liveData = _buildCurrentPdfData();

    // If Stripe payment is toggled on, ensure the PDF shows the payment section.
    // Re-use an existing checkout URL if available; otherwise use a preview
    // placeholder so the QR/link section renders in the preview.
    final isQuote = (_editableData['type']?.toString() ?? 'invoice') == 'quote';
    if (!isQuote && _includeStripePayment) {
      final existingUrl =
          (liveData['payment_checkout_url'] ?? liveData['securePaymentUrl'] ?? '')
              .toString()
              .trim();
      if (existingUrl.isEmpty) {
        liveData['securePaymentUrl'] = 'https://checkout.stripe.com/preview';
      }
      liveData['securePaymentProvider'] =
          liveData['payment_provider']?.toString().trim().isNotEmpty == true
              ? liveData['payment_provider']
              : 'stripe';
      final template = await TemplateService.loadTemplate();
      liveData['preferredPaymentMethods'] =
          InvoiceTemplate.normalizePaymentMethods([
        ...template.preferredPaymentMethods,
        InvoiceTemplate.paymentMethodStripe,
      ]);
      liveData['paymentMethodDetails'] = template.paymentMethodDetails;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(jobData: liveData),
      ),
    );
  }

  /// Pure PDF generation helper — generates and opens the system share sheet.
  /// Does NOT persist the job or change status. Callers are responsible for
  /// persisting and setting status before calling this if needed.
  Future<void> _generatePlainPdf() async {
    if (_profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Business profile not loaded. Please check Settings.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    await _preparePdfGeneration();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      await _reserveInvoiceSequenceIfNeeded(userId: userId);
    }
    final template = await TemplateService.loadTemplate();
    final currentData = _buildCurrentPdfData();
    await PdfService.generateAndPrint(
      jobData: currentData
        ..['preferredPaymentMethods'] = template.preferredPaymentMethods
        ..['paymentMethodDetails'] = template.paymentMethodDetails,
      profile: _profile!,
      template: template,
    );
  }

  /// Stripe PDF generation helper — creates a checkout session, generates
  /// the PDF with payment link/QR, and shows the link dialog.
  /// The caller is responsible for persisting the job and setting status
  /// before calling this. The jobId must already exist in Supabase.
  Future<void> _generateSecurePaymentPdf() async {
    if (_profile == null) return;
    if (_isGeneratingSecurePdf) return;
    await _preparePdfGeneration();

    setState(() => _isGeneratingSecurePdf = true);
    try {
      final template = await TemplateService.loadTemplate();
      final jobId = _editableData['id']?.toString() ?? '';
      if (jobId.isEmpty) {
        throw Exception('Job must be saved before creating a payment link.');
      }
      final totalAmount = _calculateTotal();
      final currencyCode =
          PaymentService.currencyCodeFromSymbol(_profile!.currencySymbol);

      final checkout = await PaymentService.createStripeCheckout(
        amount: totalAmount,
        currency: currencyCode,
        clientName: _clientCtrl.text.trim(),
        clientEmail: _clientEmailCtrl.text.trim().isEmpty
            ? null
            : _clientEmailCtrl.text.trim(),
        jobId: jobId,
        documentType: (_editableData['type']?.toString() ?? 'invoice'),
        description: _descCtrl.text.trim(),
      );

      _editableData['payment_provider'] = checkout.provider;
      _editableData['payment_checkout_url'] = checkout.checkoutUrl;
      _editableData['payment_checkout_session_id'] = checkout.checkoutSessionId;
      _editableData['payment_status'] = 'pending';
      _editableData['payment_currency'] = checkout.currency;
      _editableData['payment_amount_minor'] = checkout.amountMinor;
      _editableData['payment_checkout_expires_at'] = checkout.expiresAtIso;
      _editableData['secure_payment_methods'] = checkout.acceptedMethods;

      final effectivePaymentMethods = InvoiceTemplate.normalizePaymentMethods([
        ...template.preferredPaymentMethods,
        InvoiceTemplate.paymentMethodStripe,
      ]);

      final currentData = _buildCurrentPdfData()
        ..['securePaymentUrl'] = checkout.checkoutUrl
        ..['securePaymentProvider'] = checkout.provider
        ..['securePaymentMethods'] = checkout.acceptedMethods
        ..['preferredPaymentMethods'] = effectivePaymentMethods
        ..['paymentMethodDetails'] = template.paymentMethodDetails;

      await PdfService.generateAndPrint(
        jobData: currentData,
        profile: _profile!,
        template: template,
      );

      if (mounted) {
        await _showSecurePaymentLinkDialog(checkout);
      }
    } on app_exceptions.NetworkException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Network error. Check your connection and try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyStripeError(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingSecurePdf = false);
    }
  }

  String _friendlyStripeError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('missing required environment') ||
        msg.contains('stripe_secret_key')) {
      return 'Stripe is not configured. Please set up Stripe in your server settings.';
    }
    if (msg.contains('amount must be greater than zero') ||
        msg.contains('amountminor must be')) {
      return 'Invoice total must be greater than zero to create a payment link.';
    }
    if (msg.contains('authentication expired') ||
        msg.contains('invalid jwt') ||
        msg.contains('missing bearer') ||
        msg.contains('not_authenticated')) {
      return 'Session expired. Please close and reopen the app, then try again.';
    }
    if (msg.contains('job not found')) {
      return 'Please save the invoice first, then try generating the payment link.';
    }
    if (msg.contains('checkout session creation failed') ||
        msg.contains('stripe rejected')) {
      return 'Stripe rejected the request. Please check your Stripe configuration.';
    }
    if (msg.contains('incomplete checkout data')) {
      return 'Payment service returned incomplete data. Please try again.';
    }
    return 'Payment link failed. Please try again or verify your Stripe setup.';
  }

  Future<void> _preparePdfGeneration() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 140));
  }

  Future<void> _showSecurePaymentLinkDialog(
      SecureCheckoutSession checkout) async {
    final url = checkout.checkoutUrl;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Secure Payment Link Ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The PDF now includes a secure checkout link and QR code.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment link copied')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceiptForMaterials() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
    );
    if (!mounted || result is! domain_receipt.Receipt) return;

    // Parse AI-extracted items
    if (result.hasExtractedItems) {
      try {
        final aiResult =
            ReceiptAiResult.fromJsonString(result.extractedItemsJson!);
        if (aiResult.items.isNotEmpty) {
          setState(() {
            for (final item in aiResult.items) {
              final cost = item.totalPrice;
              final markedUpCost =
                  _markupPercent > 0 ? cost * (1 + _markupPercent / 100) : cost;
              (_editableData['materials'] as List).add({
                'item': item.name,
                'cost': double.parse(markedUpCost.toStringAsFixed(2)),
                'originalCost': cost,
                'fromReceipt': true,
              });
            }
            _isDirty = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${aiResult.items.length} items imported from receipt${_markupPercent > 0 ? ' with ${_markupPercent.toStringAsFixed(0)}% markup' : ''}'),
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Receipt item parsing failed: $e');
      }
    }

    // Fallback: use total amount as a single material
    if (result.extractedAmount != null && result.extractedAmount! > 0) {
      final cost = result.extractedAmount!;
      final markedUpCost =
          _markupPercent > 0 ? cost * (1 + _markupPercent / 100) : cost;
      setState(() {
        (_editableData['materials'] as List).add({
          'item': result.extractedVendor ?? 'Receipt item',
          'cost': double.parse(markedUpCost.toStringAsFixed(2)),
          'originalCost': cost,
          'fromReceipt': true,
        });
        _isDirty = true;
      });
    }
  }

  void _applyMarkupToReceiptItems() {
    final materials = (_editableData['materials'] as List?) ?? [];
    for (int i = 0; i < materials.length; i++) {
      final m = materials[i];
      // Snapshot the original cost the first time markup is applied
      if (m['originalCost'] == null && m['cost'] != null) {
        m['originalCost'] = (m['cost'] as num).toDouble();
      }
      if (m['originalCost'] != null) {
        final original = (m['originalCost'] as num).toDouble();
        final markedUp = _markupPercent > 0
            ? original * (1 + _markupPercent / 100)
            : original;
        materials[i] = {
          ...Map<String, dynamic>.from(m),
          'cost': double.parse(markedUp.toStringAsFixed(2)),
        };
      }
    }
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = query.isEmpty
                ? _customers
                : _customers.where((c) {
                    final name = (c['name'] ?? '').toString().toLowerCase();
                    return name.contains(query.toLowerCase());
                  }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (_, controller) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 8),
                        const Text('Select Client',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('No clients found',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)))
                        : ListView.builder(
                            controller: controller,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Text(
                                    ((c['name'] ?? '?').toString().isEmpty
                                            ? '?'
                                            : (c['name'] ?? '?').toString())[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(c['name'] ?? 'Unknown',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    if (c['phone'] != null) c['phone'],
                                    if (c['email'] != null) c['email'],
                                  ].join(' \u2022 '),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                                onTap: () {
                                  _selectCustomer(c);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Pick from existing logged expenses to add as materials
  Future<void> _pickFromExpenses() async {
    final container = ProviderScope.containerOf(context);
    final expenseState = container.read(expenseListProvider);
    final expenses = expenseState.expenses;

    if (expenses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged expenses found')),
        );
      }
      return;
    }

    // Filter to expenses that have an amount
    final alreadyLinkedIds = (_editableData['materials'] as List)
        .where((m) => m['expenseId'] != null)
        .map((m) => m['expenseId'].toString())
        .toSet();

    final available = expenses.where((e) {
      return e.amount > 0 && !alreadyLinkedIds.contains(e.id);
    }).toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available expenses to import')),
        );
      }
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final symbol = _profile?.currencySymbol ?? '\$';
    final f = NumberFormat.currency(symbol: symbol);
    final selected = <Expense>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Import from Expenses',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  'Select expenses to add as materials',
                                  style: TextStyle(
                                      fontSize: 12, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          if (selected.isNotEmpty)
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Add ${selected.length}'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Expense list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: available.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (_, i) {
                          final expense = available[i];
                          final isSelected = selected.contains(expense);
                          final cat = expense.category;
                          final dateStr =
                              DateFormat('MMM d').format(expense.expenseDate);
                          final hasReceipt = expense.hasReceipt;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primaryContainer.withValues(alpha: 0.3)
                                  : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.5)
                                    : cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? cs.primary.withValues(alpha: 0.15)
                                    : cs.surfaceContainerHigh,
                                child: isSelected
                                    ? Icon(Icons.check,
                                        size: 18, color: cs.primary)
                                    : Icon(_getCategoryIcon(cat),
                                        size: 18, color: cs.onSurfaceVariant),
                              ),
                              title: Text(
                                expense.description,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (expense.vendor != null &&
                                      expense.vendor!.isNotEmpty)
                                    expense.vendor!,
                                  dateStr,
                                  cat.displayName,
                                  if (hasReceipt) 'Has receipt',
                                ].join(' · '),
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                              trailing: Text(
                                f.format(expense.amount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                ),
                              ),
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    selected.remove(expense);
                                  } else {
                                    selected.add(expense);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Running total
                    if (selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          border:
                              Border(top: BorderSide(color: cs.outlineVariant)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selected.length} expense${selected.length > 1 ? 's' : ''} selected',
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                            Text(
                              f.format(selected.fold(
                                  0.0, (sum, e) => sum + e.amount)),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((confirmed) {
      if (confirmed == true && selected.isNotEmpty) {
        setState(() {
          for (final expense in selected) {
            final cost = expense.amount;
            final markedUpCost =
                _markupPercent > 0 ? cost * (1 + _markupPercent / 100) : cost;
            (_editableData['materials'] as List).add({
              'item': expense.description,
              'quantity': 1,
              'unitPrice': double.parse(markedUpCost.toStringAsFixed(2)),
              'cost': double.parse(markedUpCost.toStringAsFixed(2)),
              'originalCost': cost,
              'fromReceipt': expense.hasReceipt,
              'expenseId': expense.id,
            });
          }
          _isDirty = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selected.length} expense${selected.length > 1 ? 's' : ''} added as materials${_markupPercent > 0 ? ' with ${_markupPercent.toStringAsFixed(0)}% markup' : ''}'),
            ),
          );
        }
      }
    });
  }

  IconData _getCategoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.materials:
        return Icons.handyman;
      case ExpenseCategory.labor:
        return Icons.engineering;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.tools:
        return Icons.build;
      case ExpenseCategory.supplies:
        return Icons.inventory_2;
      case ExpenseCategory.insurance:
        return Icons.shield;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.fees:
        return Icons.account_balance;
      case ExpenseCategory.meals:
        return Icons.restaurant;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  void _addMaterialItem() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material / Part'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('material_name_field'),
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Item Name (e.g. Pipe)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    key: const ValueKey('material_qty_field'),
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('×',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const ValueKey('material_cost_field'),
                    controller: unitPriceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Unit Price', prefixText: '\$'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final unitPrice = double.tryParse(unitPriceCtrl.text) ?? 0.0;
                setState(() {
                  (_editableData['materials'] as List).add({
                    'id': const Uuid().v4(),
                    'item': nameCtrl.text,
                    'quantity': qty < 1 ? 1 : qty,
                    'unitPrice': unitPrice,
                    'cost': (qty < 1 ? 1 : qty) * unitPrice,
                  });
                  _isDirty = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _profile?.currencySymbol ?? '\$';
    final format = NumberFormat.currency(symbol: symbol);
    final total = _calculateTotal();
    final colorScheme = Theme.of(context).colorScheme;
    final docType = _editableData['type']?.toString().toUpperCase() ?? 'JOB';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 114,
              centerTitle: true,
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
              title: Text(
                docType == 'QUOTE' ? 'Quote' : 'Invoice',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        HSLColor.fromColor(colorScheme.primary)
                            .withLightness(
                                (HSLColor.fromColor(colorScheme.primary)
                                            .lightness -
                                        0.05)
                                    .clamp(0.0, 1.0))
                            .toColor(),
                        colorScheme.primary,
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(format.format(total),
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.1)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Estimated total incl. tax',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2)),
                    ],
                  ),
                ),
              ),
            ),
            // Revision context banner — shown when editing a clone of a sent invoice
            if (_editableData['revision_of'] != null)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing revision draft \u2014 original invoice preserved',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeToggle(),
                    const SizedBox(height: 10),
                    _buildVoiceRefineButton(),
                    const SizedBox(height: 12),
                    _clientSection(),
                    const SizedBox(height: 10),
                    _documentSection(format),
                    const SizedBox(height: 10),
                    _materialsSection(format),
                    const SizedBox(height: 14),
                    _buildPaymentSection(),
                    const SizedBox(height: 20),
                    _actions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    final cs = Theme.of(context).colorScheme;
    final selected = _editableData['type'] as String? ?? 'invoice';
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          _toggleSegment('invoice', 'Invoice', selected, cs),
          _toggleSegment('quote', 'Quote', selected, cs),
        ],
      ),
    );
  }

  Widget _toggleSegment(
      String value, String label, String selected, ColorScheme cs) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              _editableData['type'] = value;
              _isDirty = true;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Compact field decoration (denser padding for card-grouped fields) ──
  static const _denseFieldPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 10);

  InputDecoration _denseDecoration(String label,
      {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      contentPadding: _denseFieldPadding,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
    );
  }

  /// Section card wrapper — groups related fields with an optional label.
  Widget _sectionCard(
      {String? label, required Widget child, EdgeInsets? padding}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.38),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(label,
                  style: AppTextStyles.metadata(Theme.of(context).textTheme,
                          Theme.of(context).colorScheme)
                      .copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 1.05)),
            ),
          Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(14, label != null ? 10 : 14, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _toolActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clientSection() {
    final linkedCustomerId =
        (_editableData['customer_id'] ?? _editableData['customerId'])
            ?.toString()
            .trim();
    final isLinked = linkedCustomerId != null && linkedCustomerId.isNotEmpty;

    return _sectionCard(
      label: 'CLIENT',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('client_name_field'),
                  controller: _clientCtrl,
                  onChanged: (_) => _autoMatchCustomer(),
                  decoration: _denseDecoration('Client Name',
                      suffixIcon: isLinked
                          ? Tooltip(
                              message: 'Linked to client ledger',
                              child: Icon(Icons.link,
                                  color: AppColors.paid(context), size: 18),
                            )
                          : null),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton.filled(
                  onPressed: _customers.isEmpty ? null : _showCustomerPicker,
                  icon: const Icon(Icons.person_search, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(44, 44),
                  ),
                  tooltip: 'Select existing client',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('client_address_field'),
            controller: _clientAddressCtrl,
            minLines: 1,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
            decoration: _denseDecoration('Address (Optional)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('client_phone_field'),
                  controller: _clientPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _denseDecoration('Phone'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('client_email_field'),
                  controller: _clientEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _denseDecoration('Email'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentSection(NumberFormat f) {
    final type = _editableData['laborType'] ?? 'profile';

    return _sectionCard(
      label: 'DETAILS',
      child: Column(
        children: [
          TextField(
            key: const ValueKey('invoice_number_field'),
            controller: _invoiceNumberCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9/_-]'),
              ),
            ],
            onChanged: (value) {
              _invoiceNumberEditedByUser = true;
              _editableData['invoiceNumber'] = value.trim();
              _editableData['invoice_number'] = value.trim();
            },
            decoration: _denseDecoration(
              (_editableData['type']?.toString() == 'quote')
                  ? 'Quote Number'
                  : 'Invoice Number',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
              key: const ValueKey('job_summary_field'),
              controller: _descCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: _denseDecoration('Job Summary')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      key: const ValueKey('labor_hours_field'),
                      enabled: type != 'flat',
                      controller: _laborHoursCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration:
                          _denseDecoration('Hours', suffixText: 'hrs'))),
              const SizedBox(width: 10),
              _laborBadge(f),
            ],
          ),
        ],
      ),
    );
  }

  Widget _laborBadge(NumberFormat f) {
    final colorScheme = Theme.of(context).colorScheme;
    final type = _editableData['laborType'] ?? 'profile';
    if (type == 'flat') {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              )),
          child: Text('Flat Fee',
              style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)));
    }
    final rate = type == 'hourly'
        ? (double.tryParse(_editableData['laborRate']?.toString() ?? '85') ??
            85.0)
        : (_profile?.hourlyRate ?? 85.0);
    return GestureDetector(
      onTap: () => _showEditHourlyRateDialog(rate),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.12),
              )),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('× ${f.format(rate)}',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(width: 3),
              Icon(Icons.edit,
                  size: 12, color: colorScheme.primary.withValues(alpha: 0.45)),
            ],
          )),
    );
  }

  void _showEditHourlyRateDialog(double currentRate) {
    final rateCtrl =
        TextEditingController(text: currentRate.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Hourly Rate'),
        content: TextField(
          controller: rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Hourly Rate',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newRate = double.tryParse(rateCtrl.text);
              if (newRate != null && newRate > 0) {
                setState(() {
                  _editableData['laborType'] = 'hourly';
                  _editableData['laborRate'] = newRate;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _materialsSection(NumberFormat f) {
    final cs = Theme.of(context).colorScheme;
    final materials = (_editableData['materials'] as List?) ?? [];
    final materialsTotal = materials.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0),
    );

    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + summary badges inline
          Row(
            children: [
              Text('MATERIALS & PARTS',
                  style: AppTextStyles.metadata(Theme.of(context).textTheme, cs)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.05)),
              const Spacer(),
              if (materials.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${materials.length} ${materials.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    f.format(materialsTotal),
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Material items list
          if (materials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 28,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No materials added yet',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add materials using the options below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...materials.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              final isFromReceipt = item['fromReceipt'] == true;
              final originalCost = item['originalCost'] as num?;
              final currentCost = (item['cost'] as num?)?.toDouble() ?? 0.0;
              final hasMarkup =
                  originalCost != null && _markupPercent > 0;
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final unitPrice = (item['unitPrice'] as num?)?.toDouble();

              return Container(
                margin: EdgeInsets.only(bottom: index < materials.length - 1 ? 6 : 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isFromReceipt
                      ? cs.primaryContainer.withValues(alpha: 0.15)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    if (isFromReceipt) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.receipt_outlined, size: 14, color: cs.primary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['item'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          if (qty > 1 && unitPrice != null)
                            Text(
                              '$qty × ${f.format(unitPrice)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            )
                          else if (hasMarkup)
                            Text(
                              '\$${originalCost.toStringAsFixed(2)} + ${_markupPercent.toStringAsFixed(0)}% markup',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              qty > 1 ? 'Qty: $qty' : 'Qty: 1',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(f.format(currentCost),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: cs.onSurface)),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() {
                          materials.removeAt(index);
                          _isDirty = true;
                        }),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.close_rounded,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Markup section – always visible
          ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.tertiary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: cs.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Text('Markup',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.onSurface)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: TextField(
                      controller: _markupCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.tertiary),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.tertiary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.tertiary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.tertiary),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _markupPercent = double.tryParse(v) ?? 0.0;
                          _applyMarkupToReceiptItems();
                        });
                      },
                    ),
                  ),
                  Text(' %',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.tertiary)),
                  const Spacer(),
                  if (_markupPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _toolActionChip(
                icon: Icons.camera_alt_rounded,
                label: 'Scan',
                onTap: _scanReceiptForMaterials,
                colorScheme: cs,
              ),
              const SizedBox(width: 8),
              _toolActionChip(
                icon: Icons.receipt_long_rounded,
                label: 'Receipts',
                onTap: _pickFromExpenses,
                colorScheme: cs,
              ),
              const SizedBox(width: 8),
              _toolActionChip(
                icon: Icons.add_rounded,
                label: 'Add item',
                onTap: _addMaterialItem,
                colorScheme: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final isQuote = (_editableData['type']?.toString() ?? 'invoice') == 'quote';
    if (isQuote) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _includeStripePayment
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _includeStripePayment
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.credit_card_rounded,
              color: _includeStripePayment
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: const Text('Include Stripe Payment Link',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              _includeStripePayment
                  ? 'A secure payment QR code and link will be added to the PDF'
                  : 'Toggle on to add a Stripe payment link to this invoice',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            value: _includeStripePayment,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.32),
            onChanged: (v) => setState(() {
              _includeStripePayment = v;
              _stripeOverrideActive = true;
              _isDirty = true;
            }),
          ),
          if (_stripeAvailability != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stripeAvailability == 'not_configured'
                          ? 'Stripe is not configured on the server. Payment links will not work.'
                          : 'Could not verify Stripe availability. Payment links may not work.',
                      style: TextStyle(fontSize: 11, color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceRefineButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final busy = _isSaving || _isGeneratingSecurePdf;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : _voiceRefine,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(
                alpha: busy ? 0.08 : 0.25,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.tertiary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 16,
                  color: busy
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Edit with voice',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: busy
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    final colorScheme = Theme.of(context).colorScheme;
    final isQuote = (_editableData['type']?.toString() ?? 'invoice') == 'quote';
    final docLabel = isQuote ? 'Quote' : 'Invoice';
    final busy = _isSaving || _isGeneratingSecurePdf;

    return Column(
      children: [
        // 1) PRIMARY: Send Invoice / Send Quote
        FilledButton.icon(
          onPressed: busy ? null : _sendDocument,
          icon: _isSaving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(
            _isSaving ? 'Sending…' : 'Send $docLabel',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 10),

        // 2) SECONDARY: Preview Invoice PDF / Preview Quote PDF
        OutlinedButton.icon(
          onPressed: (_profile == null || busy) ? null : _previewPdf,
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: Text(
            'Preview $docLabel PDF',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 8),

        // 3) TERTIARY: Save Draft
        TextButton(
          onPressed: busy ? null : _saveJob,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(38),
          ),
          child: Text(
            'Save Draft',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: busy
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _voiceRefine() async {
    // Use voice capture to get additional details and merge into current data
    try {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(voiceCaptureProvider.notifier);

      // Show a full-screen voice recording overlay
      final result = await Navigator.of(context).push<VoiceCaptureResult>(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              _VoiceRefineSheet(notifier: notifier),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
        ),
      );

      if (result == null || !mounted) return;

      // Merge the new voice data into the existing editable data
      final newData = result.extractedData;
      setState(() {
        // Merge description
        final newDesc = (newData['description'] ?? '').toString().trim();
        if (newDesc.isNotEmpty) {
          final existing = _descCtrl.text.trim();
          _descCtrl.text = existing.isEmpty ? newDesc : '$existing\n$newDesc';
        }

        // ── Apply edits (update/remove existing materials) ──
        final edits = (newData['edits'] as List?) ?? [];
        final materialsList = _editableData['materials'] as List;
        for (final edit in edits) {
          if (edit is! Map) continue;
          final action = edit['action']?.toString() ?? '';
          final targetName =
              (edit['item']?.toString() ?? '').toLowerCase().trim();
          if (targetName.isEmpty) continue;

          // Find matching material by name (case-insensitive)
          final matchIdx = materialsList.indexWhere((m) =>
              m is Map &&
              (m['item']?.toString() ?? '').toLowerCase().trim() == targetName);

          if (matchIdx < 0) continue; // No match found

          if (action == 'remove') {
            materialsList.removeAt(matchIdx);
          } else if (action == 'update') {
            final existing =
                Map<String, dynamic>.from(materialsList[matchIdx] as Map);
            if (edit['quantity'] != null) {
              existing['quantity'] = (edit['quantity'] as num).toInt();
            }
            if (edit['unitPrice'] != null) {
              existing['unitPrice'] = (edit['unitPrice'] as num).toDouble();
            }
            // Recalculate cost
            final qty = (existing['quantity'] as num?)?.toInt() ?? 1;
            final unitPrice =
                (existing['unitPrice'] as num?)?.toDouble() ?? 0.0;
            existing['cost'] = qty * unitPrice;
            materialsList[matchIdx] = existing;
          }
        }

        // ── Add new materials ──
        final newMaterials = (newData['materials'] as List?) ?? [];
        for (final m in newMaterials) {
          if (m is Map) {
            final mat = Map<String, dynamic>.from(m);
            // Ensure quantity and unitPrice are present
            final qty = (mat['quantity'] as num?)?.toInt() ?? 1;
            final unitPrice = (mat['unitPrice'] as num?)?.toDouble();
            final cost = (mat['cost'] as num?)?.toDouble() ?? 0.0;
            mat['quantity'] = qty < 1 ? 1 : qty;
            mat['unitPrice'] = unitPrice ?? (qty > 0 ? cost / qty : cost);
            mat['cost'] = cost;
            materialsList.add(mat);
          }
        }

        // ── Update labor hours ──
        // If edits contain labor change, replace instead of accumulate
        final hasEdits = edits.isNotEmpty;
        final newHours = newData['laborHours'] ?? newData['labor_hours'];
        if (newHours != null) {
          final additionalHours = (newHours as num).toDouble();
          if (hasEdits && additionalHours > 0) {
            // Edit mode: replace labor hours
            _laborHoursCtrl.text = additionalHours.toString();
          } else if (additionalHours > 0) {
            // Add mode: accumulate labor hours
            final currentHours = double.tryParse(_laborHoursCtrl.text) ?? 0;
            _laborHoursCtrl.text = (currentHours + additionalHours).toString();
          }
        }

        // ── Update labor type & rate ──
        final newLaborType = newData['laborType']?.toString();
        if (newLaborType != null && newLaborType != 'profile') {
          _editableData['laborType'] = newLaborType;
          if (newLaborType == 'hourly' && newData['laborRate'] != null) {
            _editableData['laborRate'] =
                (newData['laborRate'] as num).toDouble();
          } else if (newLaborType == 'flat' && newData['laborAmount'] != null) {
            _editableData['laborAmount'] =
                (newData['laborAmount'] as num).toDouble();
          }
        }

        // ── Update document type ──
        final newType = newData['type']?.toString();
        if (newType != null &&
            (newType == 'invoice' || newType == 'quote') &&
            hasEdits) {
          _editableData['type'] = newType;
        }

        // Update client name (replace if edits, otherwise only if empty)
        final newClient =
            (newData['clientName'] ?? newData['client_name'] ?? '')
                .toString()
                .trim();
        if (newClient.isNotEmpty && newClient != 'Unknown') {
          if (hasEdits || _clientCtrl.text.trim().isEmpty) {
            _clientCtrl.text = newClient;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice details merged into document')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice capture failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Bottom sheet for voice refine — records additional voice input
class _VoiceRefineSheet extends StatefulWidget {
  final VoiceCaptureNotifier notifier;
  const _VoiceRefineSheet({required this.notifier});

  @override
  State<_VoiceRefineSheet> createState() => _VoiceRefineSheetState();
}

class _VoiceRefineSheetState extends State<_VoiceRefineSheet> {
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = 'Starting...';

  @override
  void initState() {
    super.initState();
    // Defer recording start to after the first frame to avoid
    // "modify provider while widget tree is building" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRecording();
    });
  }

  Future<void> _startRecording() async {
    try {
      await widget.notifier.startRecording();
      if (mounted) {
        setState(() {
          _isRecording = true;
          _statusText = 'Listening... describe additional details';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Could not start recording. Tap mic to retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isProcessing
              ? 'Processing...'
              : _isRecording
                  ? 'Listening...'
                  : 'Voice Edit',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated recording indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isRecording ? 140 : 100,
                height: _isRecording ? 140 : 100,
                decoration: BoxDecoration(
                  color: (_isRecording
                          ? colorScheme.error
                          : colorScheme.primary)
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? colorScheme.error
                            : colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color:
                                      colorScheme.error.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                )
                              ],
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _statusText,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isRecording
                    ? 'Tap to stop'
                    : _isProcessing
                        ? ''
                        : 'Tap mic to start',
                style: TextStyle(
                  color: _isRecording
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = 'Processing your voice input...';
      });
      try {
        final result = await widget.notifier
            .stopAndProcess()
            .timeout(const Duration(seconds: 45));
        if (result == null) {
          // Pipeline failed (error was swallowed by notifier)
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusText = 'Could not process audio. Tap mic to try again.';
            });
          }
          return;
        }
        if (mounted) {
          Navigator.pop(context, result);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusText = 'Timed out. Tap mic to try again.';
          });
        }
      }
    } else {
      await _startRecording();
    }
  }
}
