import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../domain/models/job.dart';
import '../presentation/providers/job_provider.dart';
import '../presentation/providers/analytics_provider.dart';
import '../presentation/providers/customer_ledger_provider.dart';
import '../presentation/providers/navigation_provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/widgets/record_payment_sheet.dart';
import '../presentation/widgets/shimmer_loading.dart';
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
  late final ProviderSubscription<JobListState> _jobListSubscription;
  late final ProviderSubscription<int> _historyTabSubscription;
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
    _tabController =
        TabController(length: 4, initialIndex: initialIndex, vsync: this);
    // Consume the value so it doesn't re-trigger on rebuild.
    if (requestedTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(historyInitialTabProvider.notifier).state = 0;
      });
    }
    _jobListSubscription = ref.listenManual<JobListState>(
      jobListProvider,
      (previous, next) {
        _syncFromJobState(next, notify: true);
      },
    );
    _historyTabSubscription = ref.listenManual<int>(
      historyInitialTabProvider,
      (prev, next) {
        if (next != 0 && next < _tabController.length) {
          _tabController.animateTo(next);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(historyInitialTabProvider.notifier).state = 0;
          });
        }
      },
    );
    _syncFromJobState(ref.read(jobListProvider), notify: false);
    _fetchJobs();
  }

  @override
  void dispose() {
    _jobListSubscription.close();
    _historyTabSubscription.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    await ref.read(jobListProvider.notifier).refresh();
  }

  void _syncFromJobState(JobListState state, {required bool notify}) {
    final normalized = state.jobs
        .map<Map<String, dynamic>>((job) => _jobToHistoryMap(job))
        .toList();

    void apply() {
      _allJobs = normalized;
      _isLoading = state.isLoading && normalized.isEmpty;
      _error = normalized.isEmpty ? state.error : null;
    }

    if (notify && mounted) {
      setState(apply);
      return;
    }
    apply();
  }

  Map<String, dynamic> _jobToHistoryMap(Job job) {
    final data = Map<String, dynamic>.from(job.toJson())
      ..['id'] = job.id
      ..['created_at'] = job.createdAt.toIso8601String();
    return data;
  }

  List<Map<String, dynamic>> _getFilteredJobs(String filter) {
    switch (filter) {
      case 'draft':
        return _allJobs
            .where((j) => j['status']?.toString().toLowerCase() == 'draft')
            .toList();
      case 'sent':
        // Show sent invoices that still have an outstanding balance.
        // Fully paid invoices appear in the Paid tab instead.
        return _allJobs.where((j) {
          if (j['status']?.toString().toLowerCase() != 'sent') return false;
          final total =
              double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0;
          final amountPaid =
              double.tryParse(j['amount_paid']?.toString() ?? '0') ?? 0;
          if (total > 0 && amountPaid >= total - 0.01) return false;
          return true;
        }).toList();
      case 'paid':
        // Payment-state filter: sent invoices whose balance is settled.
        // Requires status='sent' to exclude cancelled/draft edge cases.
        return _allJobs.where((j) {
          if (j['status']?.toString().toLowerCase() != 'sent') return false;
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

    final invoiceNumber = job['invoice_number']?.toString() ?? '';
    final clientEmail = job['client_email']?.toString();

    final recorded = await showRecordPaymentSheet(
      context,
      jobId: jobId,
      totalAmount: total,
      amountPaid: amountPaid,
      clientName: clientName,
      clientEmail: clientEmail,
      invoiceNumber: invoiceNumber,
    );

    if (recorded == true) {
      await _fetchJobs();
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

  /// Invalidate Riverpod providers so the dashboard, job list, and analytics
  /// all refresh immediately after payment / status actions.
  void _invalidateProviders() {
    try {
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.invalidate(customerLedgerListProvider);
      container.read(analyticsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('History: provider invalidation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Pipeline'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'All (${_allJobs.length})'),
            Tab(text: 'Drafts (${_getFilteredJobs('draft').length})'),
            Tab(text: 'Unpaid (${_getFilteredJobs('sent').length})'),
            Tab(text: 'Paid (${_getFilteredJobs('paid').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                ShimmerLoadingListItem(),
                ShimmerLoadingListItem(),
                ShimmerLoadingListItem(),
              ]),
            )
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
    final currencySymbol = ref.watch(currencySymbolProvider);

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

        final isSent =
            status == 'sent' || status == 'paid' || status == 'cancelled';
        final isCancelled = status == 'cancelled';

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
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                  const SizedBox(height: 8),
                  Text(
                      (job['client_name']?.toString().trim().isNotEmpty ??
                              false)
                          ? job['client_name'].toString().trim()
                          : (job['title']?.toString().trim().isNotEmpty ??
                                  false)
                              ? job['title'].toString().trim()
                              : 'Untitled Job',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        // Mute cancelled cards so amount doesn't read as active
                        color:
                            isCancelled ? colorScheme.onSurfaceVariant : null,
                      )),
                  const SizedBox(height: 2),
                  // Show description only if meaningful (not empty/generic).
                  if (_isDescriptionUseful(job['description']?.toString()))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(job['description'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ),
                  // Show partial-payment subtitle for invoices with payments.
                  if (_hasPartialPayment(job))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                          '$currencySymbol${(double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} of $currencySymbol${total.toStringAsFixed(2)} paid',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.paid(context),
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  const SizedBox(height: 6),
                  // Price + status actions on the same row for compactness
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price — muted + line-through for cancelled
                      Text('$currencySymbol${total.toStringAsFixed(2)}',
                          maxLines: 1,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCancelled
                                ? colorScheme.onSurfaceVariant
                                : null,
                            decoration:
                                isCancelled ? TextDecoration.lineThrough : null,
                            decorationColor: isCancelled
                                ? colorScheme.onSurfaceVariant
                                : null,
                          )),
                      const SizedBox(width: 12),
                      // Status action buttons inline after price
                      ..._buildStatusActionsList(context, job),
                    ],
                  ),
                  // Cancelled subtitle
                  if (isCancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Superseded — no longer active',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          )),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStatusActionsList(
      BuildContext context, Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final currentStatus = job['status']?.toString().toLowerCase() ?? 'draft';
    final total = double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0;
    final amountPaid =
        double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0;
    final isFullyPaid = total > 0 && amountPaid >= total - 0.01;

    if (currentStatus == 'draft') {
      return [
        _actionChip(
            context,
            'Edit',
            Icons.edit_outlined,
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
          // Paid in full — inline confirmation text instead of lone icon
          return [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.paid(context), size: 18),
                const SizedBox(width: 4),
                Text('Paid in full',
                    style: TextStyle(
                      color: AppColors.paid(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ];
        }
        // Zero-dollar invoice — no payable balance, skip Record Payment CTA
        if (total <= 0) {
          return [
            Text('\u2014 no balance',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                )),
          ];
        }
        return [
          _actionChip(context, 'Record Payment', Icons.payments_rounded,
              AppColors.paid(context), () => _recordPayment(job)),
        ];
      }
      // Sent quote — no actions (not deletable either; it's a financial record)
      return [];
    }
    return [];
  }

  /// Generic boilerplate descriptions that add no value to the card.
  static const _genericDescriptions = {
    'untitled job',
    'services rendered',
    'professional services',
    'labour',
    'labor',
    'service',
    'work performed',
    'no description',
  };

  /// Returns true if the description is non-null, non-empty, and not generic.
  bool _isDescriptionUseful(String? description) {
    if (description == null || description.trim().isEmpty) return false;
    return !_genericDescriptions.contains(description.toLowerCase().trim());
  }

  /// Returns true if the invoice has a partial payment (> 0 but not fully paid).
  bool _hasPartialPayment(Map<String, dynamic> job) {
    final total = double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0;
    final amountPaid =
        double.tryParse(job['amount_paid']?.toString() ?? '0') ?? 0;
    if (total <= 0 || amountPaid < 0.01) return false;
    return amountPaid < total - 0.01; // Has payment but not fully paid
  }

  Future<void> _confirmDeleteJob(String jobId) async {
    // Safety: only allow deletion of drafts. Sent/paid/cancelled jobs
    // are financial records that must not be casually removed.
    final job = _allJobs.firstWhere((j) => j['id']?.toString() == jobId,
        orElse: () => <String, dynamic>{});
    final status = job['status']?.toString().toLowerCase() ?? '';
    if (status != 'draft') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sent invoices cannot be deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text(
            'Are you sure you want to delete this draft? This action cannot be undone.'),
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
            content: Text('Draft deleted'),
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
    final deleteColor =
        Theme.of(context).colorScheme.error.withValues(alpha: 0.7);
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
              Icon(Icons.delete_outline, size: 14, color: deleteColor),
              const SizedBox(width: 3),
              Text('Delete',
                  style: TextStyle(
                      color: deleteColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
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
              Text(label, style: AppTextStyles.chipLabel(color)),
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
    final total = double.tryParse(job['total_amount']?.toString() ?? '0') ?? 0;
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
          Text(label, style: AppTextStyles.badge(color)),
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
      child: Text(type.toUpperCase(), style: AppTextStyles.badge(color)),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined,
              size: 56, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No jobs here yet',
              style: AppTextStyles.emptyTitle(textTheme, colorScheme)),
          const SizedBox(height: 8),
          Text('Create your first invoice or quote to see it here',
              textAlign: TextAlign.center,
              style: AppTextStyles.emptyBody(textTheme, colorScheme)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              // Switch to Home tab
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
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
            Icon(Icons.cloud_off_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.5)),
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
