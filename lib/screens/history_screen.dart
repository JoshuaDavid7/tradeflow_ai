import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/job_provider.dart';
import '../presentation/providers/analytics_provider.dart';
import '../presentation/providers/customer_ledger_provider.dart';
import '../presentation/screens/main_shell_screen.dart';
import '../presentation/widgets/record_payment_sheet.dart';
import 'draft_review_screen.dart';
import 'pdf_preview_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allJobs = [];

  @override
  void initState() {
    super.initState();
    // Read any deep-link tab request set before navigation (e.g. from
    // the dashboard's "active jobs" chip or Urgent "See All").
    final requestedTab = ref.read(historyInitialTabProvider);
    final initialIndex =
        (requestedTab > 0 && requestedTab < 4) ? requestedTab : 0;
    _tabController = TabController(
        length: 4, initialIndex: initialIndex, vsync: this);
    // Consume the value so it doesn't re-trigger on rebuild.
    if (requestedTab != 0) {
      Future.microtask(
          () => ref.read(historyInitialTabProvider.notifier).state = 0);
    }
    _fetchJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('jobs')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      // Legacy rows with status='paid' are treated as 'sent' (document state).
      final normalized = List<Map<String, dynamic>>.from(data).map((job) {
        if (job['status']?.toString().toLowerCase() == 'paid') {
          return <String, dynamic>{...job, 'status': 'sent'};
        }
        return job;
      }).toList();
      if (mounted) {
        setState(() {
          _allJobs = normalized;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('HistoryScreen: failed to load jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load jobs. Pull down to retry.';
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredJobs(String filter) {
    switch (filter) {
      case 'draft':
        return _allJobs
            .where((j) =>
                j['status']?.toString().toLowerCase() == 'draft')
            .toList();
      case 'sent':
        // All sent documents. If the outstanding filter is active, only
        // show invoices with remaining balance > 0.
        final outstandingOnly =
            ref.watch(historyOutstandingFilterProvider);
        return _allJobs.where((j) {
          if (j['status']?.toString().toLowerCase() != 'sent') return false;
          if (!outstandingOnly) return true;
          final total =
              double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0;
          final amountPaid =
              double.tryParse(j['amount_paid']?.toString() ?? '0') ?? 0;
          if (total > 0 && amountPaid >= total - 0.01) return false;
          // Also exclude quotes from outstanding filter
          final type = j['type']?.toString().toLowerCase() ?? 'invoice';
          if (type == 'quote') return false;
          return true;
        }).toList();
      case 'paid':
        // Payment-state filter: sent invoices whose balance is settled.
        return _allJobs.where((j) {
          final total =
              double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0;
          final amountPaid =
              double.tryParse(j['amount_paid']?.toString() ?? '0') ?? 0;
          return total > 0 && amountPaid >= total - 0.01;
        }).toList();
      default:
        return _allJobs;
    }
  }



  /// Mark a job as paid via the repository layer — records a real payment,
  /// updates amount_paid / amount_due, and creates a local payment record
  /// so that the dashboard's Collected metric reflects the payment.
  Future<void> _recordPayment(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.isEmpty) return;

    final total =
        double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0.0;
    final amountPaid =
        double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0.0;
    final clientName =
        (job['client_name']?.toString().trim().isNotEmpty ?? false)
            ? job['client_name'].toString().trim()
            : (job['title']?.toString().trim().isNotEmpty ?? false)
                ? job['title'].toString().trim()
                : 'Untitled Job';

    final recorded = await showRecordPaymentSheet(
      context,
      jobId: jobId,
      totalAmount: total,
      amountPaid: amountPaid,
      clientName: clientName,
    );

    if (recorded == true) {
      await _fetchJobs();
      _invalidateProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
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

  /// Invalidate Riverpod providers so the dashboard, job list, and analytics
  /// all refresh immediately after payment / status actions.
  void _invalidateProviders() {
    try {
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.invalidate(customerLedgerListProvider);
      container.read(analyticsProvider.notifier).refresh();
    } catch (_) {
      // ProviderScope not available — ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for deep-link tab navigation from dashboard (e.g. active jobs chip)
    ref.listen<int>(historyInitialTabProvider, (prev, next) {
      if (next != 0 && next < _tabController.length) {
        _tabController.animateTo(next);
        Future.microtask(
            () => ref.read(historyInitialTabProvider.notifier).state = 0);
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Pipeline'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'All (${_allJobs.length})'),
            Tab(text: 'Drafts (${_getFilteredJobs('draft').length})'),
            Tab(text: 'Sent (${_getFilteredJobs('sent').length})'),
            Tab(text: 'Paid (${_getFilteredJobs('paid').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _allJobs.isEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchJobs,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_getFilteredJobs('all')),
                      _buildList(_getFilteredJobs('draft')),
                      _buildList(_getFilteredJobs('sent')),
                      _buildList(_getFilteredJobs('paid')),
                    ],
                  ),
                ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final date = DateTime.tryParse(job['created_at']?.toString() ?? '') ??
            DateTime.now();
        final status = job['status']?.toString() ?? 'draft';
        final total =
            double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0.0;
        final type = job['type']?.toString() ?? 'invoice';

        final isSent = status == 'sent' ||
            status == 'paid' ||
            status == 'cancelled';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isSent
                  ? PdfPreviewScreen(jobData: job)
                  : DraftReviewScreen(jobData: job),
            ),
          ).then((_) {
            _fetchJobs();
            _invalidateProviders();
          }),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _statusBadge(context, status, job),
                            const SizedBox(width: 8),
                            _typeBadge(context, type),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM dd, yyyy').format(date),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                      (job['client_name']?.toString().trim().isNotEmpty ?? false)
                          ? job['client_name'].toString().trim()
                          : (job['title']?.toString().trim().isNotEmpty ?? false)
                              ? job['title'].toString().trim()
                              : 'Untitled Job',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Text(job['description']?.toString() ?? 'No description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 14),
                  // Price always visible on its own line
                  Text('\$${total.toStringAsFixed(2)}',
                      maxLines: 1,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 10),
                  // Status action buttons wrap below the price
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _buildStatusActionsList(context, job),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStatusActionsList(BuildContext context, Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final currentStatus = job['status']?.toString().toLowerCase() ?? 'draft';
    final total =
        double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0;
    final amountPaid =
        double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0;
    final isFullyPaid = total > 0 && amountPaid >= total - 0.01;

    if (currentStatus == 'draft') {
      return [
        _actionChip(context, 'Open', Icons.edit_outlined,
            Theme.of(context).colorScheme.primary,
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DraftReviewScreen(jobData: job)),
                ).then((_) {
                  _fetchJobs();
                  _invalidateProviders();
                })),
        _deleteChip(context, () => _confirmDeleteJob(jobId)),
      ];
    }
    if (currentStatus == 'sent') {
      final type = job['type']?.toString().toLowerCase() ?? 'invoice';
      if (type == 'invoice') {
        if (isFullyPaid) {
          return [
            Icon(Icons.check_circle, color: AppColors.paid(context), size: 24),
            _deleteChip(context, () => _confirmDeleteJob(jobId)),
          ];
        }
        return [
          _actionChip(context, 'Record Payment', Icons.payments_rounded,
              AppColors.paid(context), () => _recordPayment(job)),
          _deleteChip(context, () => _confirmDeleteJob(jobId)),
        ];
      }
      // Sent quote — no payment action
      return [
        _deleteChip(context, () => _confirmDeleteJob(jobId)),
      ];
    }
    return [];
  }

  Future<void> _confirmDeleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _supabase.from('jobs').delete().eq('id', jobId);
      _fetchJobs();
      _invalidateProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Delete failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// De-emphasized delete button — text-only, no background, positioned after
  /// the primary status actions to reduce accidental taps.
  Widget _deleteChip(BuildContext context, VoidCallback onTap) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 14, color: muted),
              const SizedBox(width: 3),
              Text('Delete',
                  style: TextStyle(
                      color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(
      BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(
      BuildContext context, String status, Map<String, dynamic> job) {
    Color color;
    String label;
    IconData icon;

    // Payment-aware: fully-paid sent invoices show "PAID" badge.
    final total =
        double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0;
    final amountPaid =
        double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0;
    final isFullyPaid = total > 0 && amountPaid >= total - 0.01;

    if (isFullyPaid && status == 'sent') {
      color = AppColors.paid(context);
      label = 'PAID';
      icon = Icons.check_circle_outline;
    } else {
      switch (status) {
        case 'draft':
          color = AppColors.draft(context);
          label = 'DRAFT';
          icon = Icons.edit_outlined;
          break;
        case 'sent':
          color = AppColors.sent(context);
          label = 'SENT';
          icon = Icons.send;
          break;
        case 'cancelled':
          color = AppColors.overdue(context);
          label = 'CANCELLED';
          icon = Icons.cancel_outlined;
          break;
        default:
          color = AppColors.draft(context);
          label = status.toUpperCase();
          icon = Icons.circle_outlined;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _typeBadge(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = type == 'quote' ? colorScheme.tertiary : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(type.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No jobs here yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text(
              'Tap + Create on the Home tab to\nadd your first invoice or quote',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text(_error ?? 'Could not load jobs.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchJobs();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
