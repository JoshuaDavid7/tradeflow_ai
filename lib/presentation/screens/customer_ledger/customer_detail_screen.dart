import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../providers/customer_ledger_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/shimmer_loading.dart';
import '../../../data/services/supabase_service.dart';
import '../../../screens/draft_review_screen.dart';
import '../../../screens/pdf_preview_screen.dart';
import 'project_detail_screen.dart';
import 'note_editor_screen.dart';
import 'block_editor/note_block.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../services/ai_action_coordinator.dart';
import '../../widgets/ai_assistant_overlay.dart';
import '../expenses/add_expense_screen.dart';
import '../../../data/local/database.dart' show databaseProvider;
import '../../../data/repositories/expense_repository.dart'
    show expenseRepositoryProvider;

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late String _customerId;
  late String _customerName;
  late Map<String, dynamic> _customerData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _customerId = widget.customer['id'] ?? '';
    _customerName = widget.customer['name'] ?? 'Unknown';
    _customerData = Map<String, dynamic>.from(widget.customer);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tabLabel(String base, int? count) {
    if (count == null || count == 0) return base;
    return '$base ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _customerName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          // Create invoice for this customer
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'edit_client') {
                _showEditClientDialog();
              } else if (value == 'invoice') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DraftReviewScreen(
                      jobData: {
                        'type': 'invoice',
                        'materials': [],
                        'clientName': _customerName,
                        'client_name': _customerName,
                        'customer_id': _customerId,
                        'clientPhone': _customerData['phone'] ?? '',
                        'clientEmail': _customerData['email'] ?? '',
                        'clientAddress': _customerData['address'] ?? '',
                      },
                    ),
                  ),
                ).then((_) => _invalidateProviders());
              } else if (value == 'quote') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DraftReviewScreen(
                      jobData: {
                        'type': 'quote',
                        'materials': [],
                        'clientName': _customerName,
                        'client_name': _customerName,
                        'customer_id': _customerId,
                        'clientPhone': _customerData['phone'] ?? '',
                        'clientEmail': _customerData['email'] ?? '',
                        'clientAddress': _customerData['address'] ?? '',
                      },
                    ),
                  ),
                ).then((_) => _invalidateProviders());
              } else if (value == 'project') {
                _showAddProjectDialog();
              } else if (value == 'note') {
                _openNoteEditor();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit_client',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Client'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'invoice',
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('New Invoice'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'quote',
                child: ListTile(
                  leading: Icon(Icons.request_quote),
                  title: Text('New Quote'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'project',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('New Project'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'note',
                child: ListTile(
                  leading: Icon(Icons.note_add),
                  title: Text('New Note'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            Tab(
                text: _tabLabel(
                    'Projects',
                    ref
                        .watch(customerProjectsProvider(_customerId))
                        .valueOrNull
                        ?.length)),
            Tab(
                text: _tabLabel(
                    'Jobs',
                    ref
                        .watch(customerJobsProvider(_customerId))
                        .valueOrNull
                        ?.length)),
            Tab(
                text: _tabLabel(
                    'Expenses',
                    ref
                        .watch(customerExpensesProvider(_customerId))
                        .valueOrNull
                        ?.length)),
            Tab(
                text: _tabLabel(
                    'Notes',
                    ref
                        .watch(customerNotesProvider(_customerId))
                        .valueOrNull
                        ?.length)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer summary card
          _buildSummaryCard(),

          // Contact info row
          _buildContactRow(),

          // Quick actions
          _buildQuickActions(),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsTab(),
                _buildJobsTab(),
                _buildExpensesTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final jobsAsync = ref.watch(customerJobsProvider(_customerId));

    return jobsAsync.when(
      data: (jobs) {
        // Compute totals from actual job data
        double totalBilled = 0.0;
        double totalPaid = 0.0;
        for (final job in jobs) {
          final type = (job['type']?.toString().toLowerCase() ?? 'invoice');
          final status = (job['status']?.toString().toLowerCase() ?? 'draft');
          if (type == 'quote') continue; // Don't count quotes as billed
          if (status == 'cancelled' || status == 'superseded')
            continue; // Don't count cancelled/superseded invoices
          final total = (job['total_amount'] as num?)?.toDouble() ?? 0.0;
          totalBilled += total;
          final amountPaid = (job['amount_paid'] as num?)?.toDouble() ?? 0.0;
          totalPaid += amountPaid;
        }
        final balance = totalBilled - totalPaid;

        return _buildSummaryRow(totalBilled, totalPaid, balance);
      },
      loading: () {
        // Fall back to customer record while loading
        final totalBilled =
            (widget.customer['total_billed'] as num?)?.toDouble() ?? 0.0;
        final totalPaid =
            (widget.customer['total_paid'] as num?)?.toDouble() ?? 0.0;
        final balance = (widget.customer['balance'] as num?)?.toDouble() ?? 0.0;
        return _buildSummaryRow(totalBilled, totalPaid, balance);
      },
      error: (_, __) => _buildSummaryRow(0, 0, 0),
    );
  }

  Widget _buildSummaryRow(
      double totalBilled, double totalPaid, double balance) {
    final curr = ref.watch(currencySymbolProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
              child: _buildStat(
                  'Billed',
                  '$curr${totalBilled.toStringAsFixed(0)}',
                  Theme.of(context).colorScheme.primary)),
          Container(
              height: 30,
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
          Flexible(
              child: _buildStat('Paid', '$curr${totalPaid.toStringAsFixed(0)}',
                  AppColors.paid(context))),
          Container(
              height: 30,
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
          Flexible(
              child: _buildStat(
            'Outstanding',
            '$curr${balance.toStringAsFixed(0)}',
            balance > 0 ? AppColors.sent(context) : AppColors.paid(context),
          )),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyles.cardAmount(textTheme)
                .copyWith(fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyles.metadata(textTheme, cs)),
      ],
    );
  }

  Widget _buildContactRow() {
    final phone = _customerData['phone']?.toString() ?? '';
    final email = _customerData['email']?.toString() ?? '';
    final address = _customerData['address']?.toString() ?? '';

    if (phone.isEmpty && email.isEmpty && address.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (phone.isNotEmpty) ...[
            _contactChip(
              icon: Icons.phone,
              label: formatPhoneNumber(phone),
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
              cs: cs,
              textTheme: textTheme,
            ),
            const SizedBox(width: 8),
            _contactChip(
              icon: Icons.message,
              label: 'Text',
              onTap: () => launchUrl(Uri.parse('sms:$phone')),
              cs: cs,
              textTheme: textTheme,
            ),
            const SizedBox(width: 8),
          ],
          if (email.isNotEmpty)
            _contactChip(
              icon: Icons.email_outlined,
              label: email,
              onTap: () => launchUrl(Uri.parse('mailto:$email')),
              cs: cs,
              textTheme: textTheme,
            ),
        ],
      ),
    );
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.metadata(textTheme, cs)
                      .copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _quickActionButton(
            icon: Icons.receipt_long,
            label: 'Invoice',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DraftReviewScreen(
                  jobData: {
                    'type': 'invoice',
                    'materials': [],
                    'clientName': _customerName,
                    'client_name': _customerName,
                    'customer_id': _customerId,
                    'clientPhone': _customerData['phone'] ?? '',
                    'clientEmail': _customerData['email'] ?? '',
                    'clientAddress': _customerData['address'] ?? '',
                  },
                ),
              ),
            ).then((_) => _invalidateProviders()),
            cs: cs,
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
          _quickActionButton(
            icon: Icons.request_quote,
            label: 'Quote',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DraftReviewScreen(
                  jobData: {
                    'type': 'quote',
                    'materials': [],
                    'clientName': _customerName,
                    'client_name': _customerName,
                    'customer_id': _customerId,
                    'clientPhone': _customerData['phone'] ?? '',
                    'clientEmail': _customerData['email'] ?? '',
                    'clientAddress': _customerData['address'] ?? '',
                  },
                ),
              ),
            ).then((_) => _invalidateProviders()),
            cs: cs,
            textTheme: textTheme,
          ),
          const SizedBox(width: 8),
          _quickActionButton(
            icon: Icons.payments_outlined,
            label: 'Payment',
            onTap: () => _showPaymentJobPicker(),
            cs: cs,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme cs,
    required TextTheme textTheme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.metadata(textTheme, cs).copyWith(
                      fontWeight: FontWeight.w600, color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentJobPicker() {
    final curr = ref.read(currencySymbolProvider);
    final jobsAsync = ref.read(customerJobsProvider(_customerId));
    final jobs = jobsAsync.valueOrNull ?? [];

    // Filter to unpaid invoices only
    final unpaidJobs = jobs.where((j) {
      final type = (j['type']?.toString().toLowerCase()) ?? 'invoice';
      if (type == 'quote') return false;
      final status = (j['status']?.toString().toLowerCase()) ?? 'draft';
      if (status != 'sent') return false; // Only sent invoices are payable
      final total = (j['total_amount'] as num?)?.toDouble() ?? 0.0;
      final paid = (j['amount_paid'] as num?)?.toDouble() ?? 0.0;
      return paid < total;
    }).toList();

    if (unpaidJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No outstanding invoices for this client')),
      );
      return;
    }

    // If only one unpaid job, go directly to payment sheet
    if (unpaidJobs.length == 1) {
      _openPaymentSheet(unpaidJobs.first);
      return;
    }

    // Show picker
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select Invoice',
                    style: AppTextStyles.sheetTitle(textTheme)),
                const SizedBox(height: 12),
                ...unpaidJobs.map((job) {
                  final total =
                      (job['total_amount'] as num?)?.toDouble() ?? 0.0;
                  final paid = (job['amount_paid'] as num?)?.toDouble() ?? 0.0;
                  final due = total - paid;
                  final title = job['title'] ?? job['client_name'] ?? 'Invoice';
                  return ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    leading: Icon(Icons.receipt_long, color: cs.primary),
                    title:
                        Text(title, style: AppTextStyles.cardTitle(textTheme)),
                    subtitle: Text(
                        'Total: $curr${total.toStringAsFixed(2)}  •  Due: $curr${due.toStringAsFixed(2)}',
                        style: AppTextStyles.cardSubtitle(textTheme, cs)),
                    trailing: Text('$curr${due.toStringAsFixed(0)}',
                        style: AppTextStyles.cardAmount(textTheme)
                            .copyWith(color: AppColors.sent(context))),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openPaymentSheet(job);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Invalidate Riverpod providers so the dashboard, job list, and analytics
  /// all refresh immediately after mutations.
  void _invalidateProviders() {
    ref.invalidate(customerJobsProvider(_customerId));
    ref.invalidate(customerLedgerListProvider);
    try {
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.read(analyticsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Provider invalidation from customer detail failed: $e');
    }
  }

  void _openPaymentSheet(Map<String, dynamic> job) async {
    final total = (job['total_amount'] as num?)?.toDouble() ?? 0.0;
    final paid = (job['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final jobId = job['id']?.toString() ?? '';
    final clientName = job['client_name']?.toString() ?? _customerName;

    final result = await showRecordPaymentSheet(
      context,
      jobId: jobId,
      totalAmount: total,
      amountPaid: paid,
      clientName: clientName,
    );

    if (result == true) {
      _invalidateProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Payment recorded',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.paid(context),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildProjectsTab() {
    final projectsAsync = ref.watch(customerProjectsProvider(_customerId));

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return _emptyState(
            icon: Icons.folder_open,
            message: 'No projects yet',
            subtitle: 'Tap + to create a project for $_customerName',
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(customerProjectsProvider(_customerId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final status = project['status'] ?? 'active';
              final statusColor = status == 'completed'
                  ? AppColors.paid(context)
                  : status == 'archived'
                      ? AppColors.draft(context)
                      : Theme.of(context).colorScheme.primary;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(
                        project: project,
                        customerName: _customerName,
                      ),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    child: Icon(Icons.folder, color: statusColor, size: 20),
                  ),
                  title: Text(project['name'] ?? 'Untitled',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style:
                          AppTextStyles.cardTitle(Theme.of(context).textTheme)),
                  subtitle: Text(project['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardSubtitle(
                          Theme.of(context).textTheme,
                          Theme.of(context).colorScheme)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: AppTextStyles.badge(statusColor),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
        ]),
      ),
      error: (e, __) => _emptyState(
        icon: Icons.folder_open,
        message: 'No projects yet',
        subtitle: 'Tap + to create a project',
      ),
    );
  }

  Widget _buildJobsTab() {
    final curr = ref.watch(currencySymbolProvider);
    final jobsAsync = ref.watch(customerJobsProvider(_customerId));

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return _emptyState(
            icon: Icons.receipt_long,
            message: 'No invoices or quotes',
            subtitle: 'Create one using the + button above',
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(customerJobsProvider(_customerId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final type = job['type'] ?? 'invoice';
              final status = job['status'] ?? 'draft';
              final total = (job['total_amount'] as num?)?.toDouble() ?? 0.0;
              final createdAt =
                  DateTime.tryParse(job['created_at']?.toString() ?? '') ??
                      DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () {
                    final jobStatus =
                        (job['status']?.toString().toLowerCase()) ?? 'draft';
                    final isSent = jobStatus == 'sent' ||
                        jobStatus == 'paid' ||
                        jobStatus == 'cancelled';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isSent
                            ? PdfPreviewScreen(jobData: job)
                            : DraftReviewScreen(jobData: job),
                      ),
                    ).then((_) => _invalidateProviders());
                  },
                  leading: CircleAvatar(
                    backgroundColor: type == 'quote'
                        ? AppColors.paid(context).withValues(alpha: 0.2)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                    child: Icon(
                      type == 'quote'
                          ? Icons.request_quote
                          : Icons.receipt_long,
                      color: type == 'quote'
                          ? AppColors.paid(context)
                          : Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    job['title'] ?? job['client_name'] ?? 'Untitled',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.cardTitle(Theme.of(context).textTheme),
                  ),
                  subtitle: Text(
                    '${type.toUpperCase()} \u2022 ${status.toUpperCase()} \u2022 ${DateFormat('MMM d, y').format(createdAt)}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.cardSubtitle(
                        Theme.of(context).textTheme,
                        Theme.of(context).colorScheme),
                  ),
                  trailing: Text(
                    '$curr${total.toStringAsFixed(2)}',
                    style:
                        AppTextStyles.cardAmount(Theme.of(context).textTheme),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
        ]),
      ),
      error: (e, __) => _emptyState(
        icon: Icons.receipt_long,
        message: 'No invoices or quotes',
      ),
    );
  }

  Widget _buildExpensesTab() {
    final curr = ref.watch(currencySymbolProvider);
    final costLedgerAsync = ref.watch(costLedgerProvider);

    return costLedgerAsync.when(
      data: (allEntries) {
        // Filter cost ledger entries belonging to this customer.
        final customerEntries = allEntries.where((entry) {
          // Skip linked-expense shadow rows
          if (entry.type == CostEntryType.linkedExpense) return false;
          // Direct customerId match on logged expenses
          if (entry.expense?.customerId == _customerId) return true;
          // Client name match from job enrichment
          if (entry.clientName != null &&
              entry.clientName!.toLowerCase().trim() ==
                  _customerName.toLowerCase().trim()) {
            return true;
          }
          return false;
        }).toList();

        if (customerEntries.isEmpty) {
          return _emptyState(
            icon: Icons.money_off,
            message: 'No expenses tracked',
            subtitle: 'Expenses linked to this client will appear here',
          );
        }

        // ── Group invoice materials by jobId (same as main Expenses screen) ──
        final displayRows = _groupExpensesForDisplay(customerEntries);
        displayRows.sort((a, b) => b.displayDate.compareTo(a.displayDate));

        // Calculate total
        final totalExpenses =
            displayRows.fold<double>(0.0, (sum, row) => sum + row.totalAmount);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(costLedgerProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayRows.length + 1, // +1 for summary header
            itemBuilder: (context, index) {
              // ── Summary header ──
              if (index == 0) {
                return _buildExpenseSummaryHeader(
                    context, totalExpenses, displayRows.length, curr);
              }

              final row = displayRows[index - 1];

              if (row.isGroup) {
                return _buildGroupedExpenseRow(context, row, curr);
              } else {
                return _buildSingleExpenseRow(context, row.entry!, curr);
              }
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
        ]),
      ),
      error: (e, __) => _emptyState(
        icon: Icons.money_off,
        message: 'No expenses tracked',
      ),
    );
  }

  // ── Expense grouping (mirrors main Expenses screen logic) ────────────────

  List<_CustomerDisplayRow> _groupExpensesForDisplay(
      List<CostLedgerEntry> entries) {
    final materialsByJob = <String, List<CostLedgerEntry>>{};
    final standaloneRows = <_CustomerDisplayRow>[];

    for (final e in entries) {
      if (e.type == CostEntryType.invoiceMaterial && e.jobId != null) {
        (materialsByJob[e.jobId!] ??= []).add(e);
      } else {
        standaloneRows.add(_CustomerDisplayRow.single(e));
      }
    }

    final rows = <_CustomerDisplayRow>[];
    for (final mapEntry in materialsByJob.entries) {
      final materials = mapEntry.value;
      if (materials.length > 1) {
        rows.add(_CustomerDisplayRow.group(materials));
      } else {
        rows.add(_CustomerDisplayRow.single(materials.first));
      }
    }

    rows.addAll(standaloneRows);
    return rows;
  }

  /// Infer a trade-category title from grouped material descriptions.
  String _groupedTitle(_CustomerDisplayRow row) {
    if (row.jobName != null && row.jobName!.isNotEmpty) {
      return '${row.jobName!} materials';
    }
    // Try AI-suggested title from child item descriptions
    final itemNames =
        row.children!.map((c) => c.description.toLowerCase()).toList();
    const categories = {
      'Plumbing': ['pipe', 'valve', 'pvc', 'fitting', 'faucet', 'drain'],
      'Electrical': ['wire', 'switch', 'outlet', 'breaker', 'conduit'],
      'Hardware': ['screw', 'bolt', 'nail', 'anchor', 'bracket', 'hinge'],
      'Paint': ['paint', 'primer', 'brush', 'roller', 'tape', 'stain'],
      'Lumber': ['wood', 'lumber', 'plywood', 'board', '2x4', 'timber'],
      'Flooring': ['tile', 'grout', 'laminate', 'vinyl', 'carpet'],
    };
    for (final cat in categories.entries) {
      for (final keyword in cat.value) {
        if (itemNames.any((n) => n.contains(keyword))) {
          return '${cat.key} supplies';
        }
      }
    }
    if (row.children!.length > 1) {
      return '${row.children!.first.description} + ${row.children!.length - 1} more';
    }
    if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
      return row.invoiceNumber!;
    }
    return 'Invoice from ${DateFormat('MMM d, y').format(row.displayDate)}';
  }

  // ── Expense summary header ───────────────────────────────────────────────

  Widget _buildExpenseSummaryHeader(
      BuildContext context, double total, int itemCount, String curr) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.expense(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.expense(context), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Expenses',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('$itemCount expense${itemCount == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7))),
                ],
              ),
            ),
            Text(
              '$curr${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.expense(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single expense row ───────────────────────────────────────────────────

  Widget _buildSingleExpenseRow(
      BuildContext context, CostLedgerEntry entry, String curr) {
    final isMaterial = entry.type == CostEntryType.invoiceMaterial;

    final IconData icon;
    final Color iconColor;
    if (isMaterial) {
      icon = Icons.inventory_2_outlined;
      iconColor = Colors.orange;
    } else {
      icon = Icons.receipt;
      iconColor = AppColors.expense(context);
    }

    String? badge;
    if (isMaterial && entry.isEstimated) {
      badge = 'No receipt';
    } else if (isMaterial && !entry.isEstimated) {
      badge = 'Receipt linked';
    } else if (!isMaterial && entry.jobId == null) {
      badge = 'Not invoiced';
    }

    final subtitleParts = <String>[];
    if (isMaterial && entry.invoiceNumber != null) {
      subtitleParts.add(entry.invoiceNumber!);
    } else if (entry.vendor != null && entry.vendor!.isNotEmpty) {
      subtitleParts.add(entry.vendor!);
    }
    subtitleParts.add(DateFormat('MMM d, y').format(entry.date));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _onExpenseRowTap(context, entry, curr),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(entry.description,
            style: AppTextStyles.cardTitle(Theme.of(context).textTheme)),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                subtitleParts.join(' \u2022 '),
                style: AppTextStyles.cardSubtitle(
                    Theme.of(context).textTheme, Theme.of(context).colorScheme),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (badge == 'No receipt' || badge == 'Not invoiced'
                          ? Colors.amber.shade700
                          : AppColors.paid(context))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: badge == 'No receipt' || badge == 'Not invoiced'
                        ? Colors.amber.shade700
                        : AppColors.paid(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '$curr${entry.amount.toStringAsFixed(2)}',
          style: AppTextStyles.cardAmount(Theme.of(context).textTheme)
              .copyWith(color: iconColor),
        ),
      ),
    );
  }

  // ── Grouped expense row ──────────────────────────────────────────────────

  Widget _buildGroupedExpenseRow(
      BuildContext context, _CustomerDisplayRow row, String curr) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');
    final title = _groupedTitle(row);

    final subtitleParts = <String>[];
    if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
      subtitleParts.add(row.invoiceNumber!);
    }
    subtitleParts.add('${row.itemCount} items');

    final dateLine = dateFormat.format(row.displayDate);
    final estimatedCount = row.children!.where((c) => c.isEstimated).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showGroupedExpenseDetail(context, row, curr),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitleParts.join(' · '),
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(dateLine,
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant)),
                        if (estimatedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  Colors.amber.shade700.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$estimatedCount estimated',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$curr${row.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grouped expense detail sheet ─────────────────────────────────────────

  void _showGroupedExpenseDetail(
      BuildContext context, _CustomerDisplayRow row, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = row.children!;
    final title = _groupedTitle(row);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (row.invoiceNumber != null) row.invoiceNumber!,
                            '${row.itemCount} items',
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$cs${row.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Materials table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                              flex: 3,
                              child: Text('ITEM',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                          const Expanded(
                              flex: 2,
                              child: Text('STATUS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                          const Expanded(
                              flex: 2,
                              child: Text('COST',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                    // Material rows
                    ...children.map((child) {
                      final isEst = child.isEstimated;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.3))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(child.description,
                                    style: const TextStyle(fontSize: 13))),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isEst
                                            ? Colors.amber.shade700
                                            : AppColors.paid(context))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isEst ? 'No rcpt' : 'Receipt',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isEst
                                          ? Colors.amber.shade700
                                          : AppColors.paid(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                  '$cs${child.amount.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Total row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: Border(
                            top: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.5))),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                              flex: 3,
                              child: Text('TOTAL',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800))),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 2,
                            child: Text(
                                '$cs${row.totalAmount.toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Expense row tap handling ──────────────────────────────────────────────

  void _onExpenseRowTap(
      BuildContext context, CostLedgerEntry entry, String cs) {
    final isMaterial = entry.type == CostEntryType.invoiceMaterial;
    if (isMaterial) {
      _showMaterialDetail(context, entry, cs);
    } else if (entry.expense != null) {
      _showLoggedExpenseDetail(context, entry, cs);
    }
  }

  void _showMaterialDetail(
      BuildContext context, CostLedgerEntry entry, String cs) async {
    final colorScheme = Theme.of(context).colorScheme;
    final cost = entry.materialCost;
    if (cost == null) return;

    // Resolve linked receipt info directly from DB (bypass provider cache)
    String? receiptName = entry.linkedReceiptName;
    double? receiptAmount = entry.linkedReceiptAmount;
    if (receiptName == null && cost.source == 'both') {
      try {
        final db = ref.read(databaseProvider);
        final links = await db.materialCostDao.getLinksForCost(cost.id);
        if (links.isNotEmpty) {
          final expId = links.first.expenseId;
          final repository = ref.read(expenseRepositoryProvider);
          final userId = ref.read(userIdProvider);
          if (userId != null) {
            final allExp = await repository.getAllExpenses(userId);
            final match = allExp.where((e) => e.id == expId);
            if (match.isNotEmpty) {
              receiptName = match.first.description;
              receiptAmount = match.first.amount;
            } else {
              // Expense not found in domain model, check raw DB
              final rawExp = await db.expenseDao.getExpenseById(expId);
              if (rawExp != null) {
                receiptName = rawExp.description;
                receiptAmount = rawExp.amount;
              } else {
                receiptName = 'Receipt (ID: ${expId.substring(0, 8)}...)';
                receiptAmount = links.first.allocatedAmount;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to resolve linked receipt: $e');
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.description,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Invoice Material',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Amount banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('$cs${cost.canonicalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // Status badge
              Row(
                children: [
                  Icon(
                    entry.isEstimated
                        ? Icons.schedule
                        : Icons.check_circle_outline,
                    size: 18,
                    color: entry.isEstimated
                        ? Colors.amber.shade700
                        : AppColors.paid(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.isEstimated
                          ? 'No receipt linked — using invoice estimate'
                          : 'Receipt linked — actual cost verified',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: entry.isEstimated
                            ? Colors.amber.shade700
                            : AppColors.paid(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Details
              _expDetailRow(Icons.calendar_today, 'Recognized',
                  DateFormat('MMM d, y').format(cost.recognitionDate)),
              if (entry.clientName != null)
                _expDetailRow(
                    Icons.person_outline, 'Client', entry.clientName!),
              if (entry.invoiceNumber != null)
                _expDetailRow(
                    Icons.receipt_outlined, 'Invoice', entry.invoiceNumber!),
              if (cost.provisionalCost != cost.canonicalCost)
                _expDetailRow(Icons.compare_arrows, 'Invoice estimate',
                    '$cs${cost.provisionalCost.toStringAsFixed(2)}'),
              _expDetailRow(Icons.label_outline, 'Source',
                  cost.source == 'both' ? 'Invoice + receipt' : 'Invoice'),
              // Linked receipt section
              if (receiptName != null) ...[
                const SizedBox(height: 14),
                Text('LINKED RECEIPT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paid(context).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.paid(context).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link,
                          size: 16, color: AppColors.paid(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(receiptName!,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      if (receiptAmount != null)
                        Text('$cs${receiptAmount!.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.paid(context))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Explanation
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.isEstimated
                            ? 'Based on invoice estimate. Link a receipt for actual cost.'
                            : 'Backed by a linked receipt. Invoice estimate replaced.',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoggedExpenseDetail(
      BuildContext context, CostLedgerEntry entry, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final expense = entry.expense!;
    final dateFormat = DateFormat('EEEE, MMM d, y');
    final isLinked = entry.type == CostEntryType.linkedExpense;
    final expenseColor = AppColors.expense(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: expenseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(Icons.receipt, color: expenseColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.description,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                                isLinked
                                    ? 'Linked Expense'
                                    : expense.category.displayName,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Amount banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.overdue(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$cs${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdue(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Linked expense banner
                  if (isLinked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.paid(context).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.paid(context).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link,
                              size: 15, color: AppColors.paid(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Linked to an invoice material. Replaces the invoice estimate in totals.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.paid(context),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Details rows
                  _expDetailRow(Icons.calendar_today, 'Date',
                      dateFormat.format(expense.expenseDate)),
                  if (expense.vendor != null && expense.vendor!.isNotEmpty)
                    _expDetailRow(Icons.store, 'Vendor', expense.vendor!),
                  if (expense.paymentMethod != null)
                    _expDetailRow(Icons.payment, 'Payment',
                        expense.paymentMethod!.displayName),
                  _expDetailRow(
                    expense.taxDeductible ? Icons.check_circle : Icons.cancel,
                    'Tax Deductible',
                    expense.taxDeductible ? 'Yes' : 'No',
                    color: expense.taxDeductible
                        ? AppColors.paid(context)
                        : colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Sticky footer: Edit / Delete
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddExpenseScreen(existingExpense: expense),
                            ),
                          ).then((_) {
                            ref.invalidate(costLedgerProvider);
                          });
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _confirmExpenseDelete(ctx, expense,
                              isLinked: isLinked);
                        },
                        icon: Icon(Icons.delete,
                            size: 18, color: colorScheme.error),
                        label: Text('Delete',
                            style: TextStyle(color: colorScheme.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExpenseDelete(BuildContext context, dynamic expense,
      {bool isLinked = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(isLinked
            ? 'This expense is linked to an invoice material. Deleting it will revert that material to its estimated cost.'
            : 'Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close bottom sheet
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.client
                    .from('expenses')
                    .delete()
                    .eq('id', expense.id);
                ref.invalidate(costLedgerProvider);
              } catch (e) {
                debugPrint('Delete expense failed: $e');
              }
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _expDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final notesAsync = ref.watch(customerNotesProvider(_customerId));

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return _emptyState(
            icon: Icons.note_alt_outlined,
            message: 'No notes yet',
            subtitle:
                'Record measurements, site details,\nor client preferences',
            onAction: _openNoteEditor,
            actionLabel: 'Create Note',
          );
        }

        // Separate pinned and unpinned
        final pinned = notes.where((n) => n['pinned'] == true).toList();
        final unpinned = notes.where((n) => n['pinned'] != true).toList();

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(customerNotesProvider(_customerId)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: [
                  if (pinned.isNotEmpty) ...[
                    _noteSectionHeader(
                        'Pinned', Icons.push_pin, AppColors.sent(context)),
                    ...pinned.map(_buildNoteCard),
                    const SizedBox(height: 12),
                  ],
                  if (unpinned.isNotEmpty) ...[
                    if (pinned.isNotEmpty)
                      _noteSectionHeader('Notes', Icons.note_alt_outlined,
                          Theme.of(context).colorScheme.onSurfaceVariant),
                    ...unpinned.map(_buildNoteCard),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton(
                      heroTag: 'customer_notes_fab',
                      elevation: 2,
                      onPressed: _openNoteEditor,
                      child: const Icon(Icons.note_add),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'customer_notes_ai_fab',
                    elevation: 2,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    onPressed: () => _openAiAssistant(context),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
          ShimmerLoadingListItem(),
        ]),
      ),
      error: (e, __) => _emptyState(
        icon: Icons.note,
        message: 'No notes yet',
      ),
    );
  }

  Widget _noteSectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = note['title']?.toString() ?? '';
    final content = note['content']?.toString() ?? '';
    final colorStr = note['color']?.toString() ?? 'blue';
    final color = _parseNoteColor(colorStr);
    final updatedAt = DateTime.tryParse(note['updated_at']?.toString() ?? '');
    final pinned = note['pinned'] == true;

    // Use block-aware preview and image extraction
    final preview = plainTextPreview(content, maxLength: 100);
    final imageUrls = extractImageUrls(content, note['images']);
    final firstImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNoteEditor(existingNote: note),
        onLongPress: () => _showNoteActions(note),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3.5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with pin
                    Row(
                      children: [
                        if (pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin_rounded,
                                size: 13, color: Colors.orange.shade700),
                          ),
                        Expanded(
                          child: Text(
                            title.isNotEmpty ? title : 'Untitled',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: title.isNotEmpty
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(preview,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    // Metadata row
                    Row(
                      children: [
                        if (imageUrls.isNotEmpty) ...[
                          Icon(Icons.photo_outlined,
                              size: 13,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.45)),
                          const SizedBox(width: 2),
                          Text('${imageUrls.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(width: 8),
                        ],
                        if (updatedAt != null)
                          Text(
                            DateFormat('MMM d, y').format(updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Thumbnail
              if (firstImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstImageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: colorScheme.surfaceContainerLow,
                      child: Icon(Icons.photo,
                          color: colorScheme.outlineVariant, size: 20),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseNoteImages(dynamic imagesJson) {
    if (imagesJson == null) return [];
    if (imagesJson is List) {
      return imagesJson.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Color _parseNoteColor(String? name) {
    switch (name) {
      case 'green':
        return AppColors.noteGreen;
      case 'orange':
        return AppColors.noteOrange;
      case 'red':
        return AppColors.noteRed;
      case 'purple':
        return AppColors.notePurple;
      case 'teal':
        return AppColors.noteTeal;
      default:
        return AppColors.noteBlue;
    }
  }

  Future<void> _openAiAssistant(BuildContext context) async {
    final notifier = ref.read(aiAssistantProvider.notifier);
    final result = await showAiAssistantOverlay(context, notifier: notifier);
    if (result != null && context.mounted) {
      await ref.read(aiActionCoordinatorProvider).execute(context, result);
    }
  }

  void _openNoteEditor({Map<String, dynamic>? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: existingNote,
          customerId: _customerId,
          customerName: _customerName,
        ),
      ),
    ).then((_) {
      ref.invalidate(customerNotesProvider(_customerId));
    });
  }

  void _showNoteActions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNoteEditor(existingNote: note);
                },
              ),
              ListTile(
                leading: Icon(
                  note['pinned'] == true
                      ? Icons.push_pin_outlined
                      : Icons.push_pin,
                ),
                title: Text(note['pinned'] == true ? 'Unpin' : 'Pin to top'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final supabase = ref.read(supabaseServiceProvider);
                  try {
                    await supabase.ensureValidSession();
                    await supabase.client
                        .from('project_notes')
                        .update({'pinned': !(note['pinned'] == true)}).eq(
                            'id', note['id']);
                    ref.invalidate(customerNotesProvider(_customerId));
                  } catch (e) {
                    debugPrint('Note pin toggle failed: $e');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteNote(note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('Delete "${note['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.ensureValidSession();
                await supabase.client
                    .from('project_notes')
                    .delete()
                    .eq('id', note['id']);
                ref.invalidate(customerNotesProvider(_customerId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Could not delete note. Please try again.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    String? subtitle,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.emptyTitle(textTheme, cs)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.emptyBody(textTheme, cs)),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel ?? 'Create'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditClientDialog() {
    final nameCtrl = TextEditingController(text: _customerData['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _customerData['phone'] ?? '');
    final emailCtrl = TextEditingController(text: _customerData['email'] ?? '');
    final addressCtrl =
        TextEditingController(text: _customerData['address'] ?? '');
    String? nameError;
    String? emailError;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Client Name *',
                    prefixIcon: const Icon(Icons.person),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null)
                      setDialogState(() => nameError = null);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    errorText: emailError,
                  ),
                  onChanged: (_) {
                    if (emailError != null)
                      setDialogState(() => emailError = null);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => nameError = 'Client name is required');
                  return;
                }
                if (name.length < 2) {
                  setDialogState(
                      () => nameError = 'Name must be at least 2 characters');
                  return;
                }
                final email = emailCtrl.text.trim();
                if (email.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  setDialogState(
                      () => emailError = 'Enter a valid email address');
                  return;
                }

                final supabase = ref.read(supabaseServiceProvider);
                try {
                  await supabase.ensureValidSession();
                  final updates = <String, dynamic>{
                    'name': name,
                    'phone': phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    'email': email.isEmpty ? null : email,
                    'address': addressCtrl.text.trim().isEmpty
                        ? null
                        : addressCtrl.text.trim(),
                    'updated_at': DateTime.now().toIso8601String(),
                  };

                  await supabase.client
                      .from('customers')
                      .update(updates)
                      .eq('id', _customerId);

                  // Update local state so the screen reflects changes immediately
                  setState(() {
                    _customerName = name;
                    _customerData['name'] = name;
                    _customerData['phone'] = updates['phone'];
                    _customerData['email'] = updates['email'];
                    _customerData['address'] = updates['address'];
                  });

                  // Refresh the list so the ledger screen also updates
                  ref.invalidate(customerLedgerListProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client updated')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Could not update client. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      addressCtrl.dispose();
    });
  }

  void _showAddProjectDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Project for $_customerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final supabase = ref.read(supabaseServiceProvider);
              final userId = ref.read(userIdProvider);
              if (userId == null) return;

              final now = DateTime.now().toIso8601String();
              try {
                await supabase.ensureValidSession();
                await supabase.client.from('projects').insert({
                  'id': const Uuid().v4(),
                  'user_id': userId,
                  'customer_id': _customerId,
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  'status': 'active',
                  'created_at': now,
                  'updated_at': now,
                });
                ref.invalidate(customerProjectsProvider(_customerId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to create project. Please run the latest '
                            'database migration and try again.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// A display row for the customer expenses tab — either a single entry
/// or a grouped invoice with multiple material children.
class _CustomerDisplayRow {
  final CostLedgerEntry? entry;
  final List<CostLedgerEntry>? children;

  _CustomerDisplayRow.single(CostLedgerEntry this.entry) : children = null;
  _CustomerDisplayRow.group(List<CostLedgerEntry> this.children) : entry = null;

  bool get isGroup => children != null && children!.length > 1;

  DateTime get displayDate {
    if (isGroup) {
      return children!
          .map((c) => c.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    return entry!.date;
  }

  double get totalAmount {
    if (isGroup) {
      return children!.fold(0.0, (sum, c) => sum + c.amount);
    }
    return entry!.amount;
  }

  String? get invoiceNumber =>
      isGroup ? children!.first.invoiceNumber : entry!.invoiceNumber;
  String? get clientName =>
      isGroup ? children!.first.clientName : entry!.clientName;
  String? get jobName => isGroup ? children!.first.jobName : entry!.jobName;
  String? get jobId => isGroup ? children!.first.jobId : entry!.jobId;
  int get itemCount => isGroup ? children!.length : 1;
}
