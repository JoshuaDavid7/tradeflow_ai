import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tradeflow_ai/domain/models/receipt.dart' as domain_receipt;
import 'package:tradeflow_ai/domain/models/job.dart' hide Material;
import 'package:tradeflow_ai/presentation/providers/job_provider.dart';
import 'package:tradeflow_ai/presentation/providers/profile_provider.dart';
import 'package:tradeflow_ai/presentation/providers/analytics_provider.dart';
import 'package:tradeflow_ai/presentation/providers/expense_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:tradeflow_ai/presentation/widgets/shimmer_loading.dart';
import 'package:tradeflow_ai/core/theme/app_theme.dart';
import 'package:tradeflow_ai/data/services/supabase_service.dart';
import 'package:tradeflow_ai/data/services/demo_data_service.dart';
import 'package:tradeflow_ai/presentation/providers/customer_ledger_provider.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/ai_action_coordinator.dart';
import '../widgets/ai_assistant_overlay.dart';
import '../../screens/draft_review_screen.dart';
import '../../screens/pdf_preview_screen.dart';
import '../../screens/settings_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'receipts/receipt_scanner_screen.dart';
import 'receipts/scan_result_router_screen.dart';
import 'customer_ledger/note_editor_screen.dart';

class DashboardScreenNew extends ConsumerStatefulWidget {
  const DashboardScreenNew({super.key});

  @override
  ConsumerState<DashboardScreenNew> createState() => _DashboardScreenNewState();
}

class _DashboardScreenNewState extends ConsumerState<DashboardScreenNew> {
  final _supabase = Supabase.instance.client;

  // Month selector for metrics
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Build the attention subtitle with a specific breakdown,
  /// e.g. "1 draft · 2 invoices awaiting payment"
  String _attentionSubtitle(JobListState jobState) {
    if (jobState.isLoading) return '';
    final awaiting = jobState.jobs.where((j) => j.isAwaitingPayment).toList();
    final drafts =
        jobState.jobs.where((j) => j.status == JobStatus.draft).toList();
    final parts = <String>[];
    if (drafts.length == 1) parts.add('1 draft');
    if (drafts.length > 1) parts.add('${drafts.length} drafts');
    if (awaiting.length == 1) parts.add('1 invoice awaiting payment');
    if (awaiting.length > 1) {
      parts.add('${awaiting.length} invoices awaiting payment');
    }
    if (parts.isEmpty) return 'All caught up';
    return parts.join(' \u00b7 ');
  }

  @override
  Widget build(BuildContext context) {
    final jobStats = ref.watch(jobStatsProvider);
    final profile = ref.watch(businessProfileProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          unawaited(HapticFeedback.mediumImpact());
          ref.invalidate(jobStatsProvider);
          ref.invalidate(jobListProvider);
          await ref.read(analyticsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // ── Header: Simple pinned AppBar with business name ──
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                profile?.businessName ?? 'Your Business',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: false,
              actions: [
                // Profile avatar / business menu
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        (profile?.businessName ?? 'Y')[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Greeting + attention subtitle (scrolls away naturally) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Consumer(builder: (context, ref, _) {
                  final jobState = ref.watch(jobListProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()},',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _attentionSubtitle(jobState),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 1. Summary Card (Metrics Strip) ──
                  RepaintBoundary(
                    child: jobStats.when(
                      data: (stats) => _buildMetricsStrip(
                          context, stats, analyticsAsync, currencySymbol),
                      loading: () => const ShimmerLoadingCard(height: 88),
                      error: (_, __) => _buildErrorCard(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 2. + Create CTA ──
                  RepaintBoundary(
                    child: _buildCreateButton(context, colorScheme),
                  ),
                  const SizedBox(height: 10),

                  // ── 3. Start with Voice ──
                  RepaintBoundary(
                    child: _buildVoiceSection(context, colorScheme),
                  ),
                  const SizedBox(height: 26),

                  // ── 4. Urgent Section ──
                  RepaintBoundary(
                    child: Consumer(builder: (context, ref, _) {
                      final jobState = ref.watch(jobListProvider);
                      return _buildUrgentSection(
                          context, currencySymbol, jobState);
                    }),
                  ),

                  // ── 5. Recent Jobs ──
                  RepaintBoundary(
                    child: Consumer(builder: (context, ref, _) {
                      final jobState = ref.watch(jobListProvider);
                      return _buildRecentJobs(
                          context, currencySymbol, jobState);
                    }),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METRICS STRIP — Premium gradient summary card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMetricsStrip(
    BuildContext context,
    Map<String, dynamic> jobStats,
    AsyncValue<BusinessAnalytics> analyticsAsync,
    String currencySymbol,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final outstanding = ((jobStats['outstandingRevenue'] as double?) ?? 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Awaiting payment (all-time) + Sent chip
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Awaiting payment',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol${outstanding.toStringAsFixed(0)}',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(builder: (context, ref, _) {
                final jobState = ref.watch(jobListProvider);
                final outstandingCount = jobState.jobs
                    .where((j) => j.isAwaitingPayment)
                    .length;
                return GestureDetector(
                  onTap: () {
                    // Navigate to Jobs tab → Sent tab (outstanding only)
                    ref.read(historyInitialTabProvider.notifier).state = 2;
                    ref.read(historyOutstandingFilterProvider.notifier).state = true;
                    ref.read(bottomNavIndexProvider.notifier).state = 1;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '$outstandingCount unpaid',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          // Month scope selector (applies to Collected / Spent / Profit below)
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month,
                    color: Colors.white.withValues(alpha: 0.75), size: 14),
                const SizedBox(width: 4),
                Text(
                  _isCurrentMonth
                      ? 'This Month'
                      : DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.75), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Bottom row: Gross Income, Expenses, Net Income
          analyticsAsync.when(
            data: (analytics) => Row(
              children: [
                _buildMiniMetric(
                  context,
                  label: 'Gross Income',
                  value:
                      '$currencySymbol${analytics.monthlyRevenue.toStringAsFixed(0)}',
                  color: Colors.white,
                ),
                _buildMetricDivider(),
                _buildMiniMetric(
                  context,
                  label: 'Expenses',
                  value:
                      '$currencySymbol${analytics.monthlyExpenses.toStringAsFixed(0)}',
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                _buildMetricDivider(),
                _buildMiniMetric(
                  context,
                  label: 'Net Income',
                  value:
                      '$currencySymbol${analytics.monthlyProfit.toStringAsFixed(0)}',
                  color: analytics.monthlyProfit >= 0
                      ? const Color(0xFF6FDD9B)
                      : const Color(0xFFFFB4AB),
                ),
              ],
            ),
            loading: () => Row(
              children: [
                _buildMiniMetric(context,
                    label: 'Gross Income', value: '\u2014', color: Colors.white),
                _buildMetricDivider(),
                _buildMiniMetric(context,
                    label: 'Expenses', value: '\u2014', color: Colors.white),
                _buildMetricDivider(),
                _buildMiniMetric(context,
                    label: 'Net Income', value: '\u2014', color: Colors.white),
              ],
            ),
            error: (_, __) => Row(
              children: [
                _buildMiniMetric(
                  context,
                  label: 'Gross Income',
                  value:
                      '$currencySymbol${((jobStats['monthlyRevenue'] as double?) ?? 0.0).toStringAsFixed(0)}',
                  color: Colors.white,
                ),
                _buildMetricDivider(),
                _buildMiniMetric(context,
                    label: 'Expenses', value: '\u2014', color: Colors.white),
                _buildMetricDivider(),
                _buildMiniMetric(context,
                    label: 'Net Income', value: '\u2014', color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 0.5,
      height: 30,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Could not load stats',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(jobStatsProvider);
                ref.read(analyticsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // + CREATE BUTTON — Single dominant CTA, opens bottom sheet
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCreateButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          _showCreateBottomSheet(context);
        },
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Create',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE BOTTOM SHEET — 2-column grid with noun-only labels
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCreateBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Text(
                'Create new',
                style: AppTextStyles.sheetTitle(textTheme),
              ),
              const SizedBox(height: 20),
              // Row 1: Invoice + Quote
              Row(
                children: [
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: Icons.receipt_long_rounded,
                      label: 'Invoice',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DraftReviewScreen(
                              jobData: const {
                                'type': 'invoice',
                                'materials': []
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: Icons.request_quote_rounded,
                      label: 'Quote',
                      color: const Color(0xFFC49A2A),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DraftReviewScreen(
                              jobData: const {'type': 'quote', 'materials': []},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 2: Expense + Note
              Row(
                children: [
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: Icons.add_card_rounded,
                      label: 'Expense',
                      color: AppColors.expense(context),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen(),
                          ),
                        ).then((_) {
                          ref.invalidate(expenseStatsProvider);
                          ref.read(analyticsProvider.notifier).refresh();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCreateOption(
                      ctx,
                      icon: Icons.note_add_rounded,
                      label: 'Note',
                      color: AppColors.notePurple,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showClientPickerForNote(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: Scan receipt — full width, intentional single item
              _buildCreateOption(
                ctx,
                icon: Icons.document_scanner_rounded,
                label: 'Scan receipt',
                color: AppColors.noteTeal,
                onTap: () async {
                  Navigator.pop(ctx);
                  final scannedReceipt = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReceiptScannerScreen(),
                    ),
                  );
                  if (!mounted || scannedReceipt is! domain_receipt.Receipt) {
                    return;
                  }
                  // Route through shared scan result router
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanResultRouterScreen(
                        receipt: scannedReceipt,
                      ),
                    ),
                  );
                  ref.invalidate(expenseStatsProvider);
                  await ref.read(analyticsProvider.notifier).refresh();
                },
              ),
              const SizedBox(height: 12),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.cardTitle(textTheme).copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENT PICKER FOR NOTE — Select client, then open NoteEditorScreen
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showClientPickerForNote(BuildContext context) async {
    final supabase = ref.read(supabaseServiceProvider);
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    List<Map<String, dynamic>> customers = [];
    try {
      await supabase.ensureValidSession();
      final data = await supabase.client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('name');
      customers = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Customer fetch for note linking failed: $e');
    }

    if (!mounted) return;

    if (customers.isEmpty) {
      _showInlineNewClientForNote(context);
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.85,
            minChildSize: 0.3,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Create note for',
                      style:
                          AppTextStyles.sheetTitle(Theme.of(context).textTheme),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a client',
                      style: AppTextStyles.cardSubtitle(
                        Theme.of(context).textTheme,
                        Theme.of(context).colorScheme,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Client list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: customers.length + 1, // +1 for "New Client"
                        itemBuilder: (_, index) {
                          if (index == customers.length) {
                            // "New Client" option — inline creation
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                child: Icon(Icons.add_rounded,
                                    color: colorScheme.primary, size: 20),
                              ),
                              title: const Text('New client',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: const Text('Create and start a note'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _showInlineNewClientForNote(context);
                              },
                            );
                          }
                          final c = customers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                (c['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              c['name'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openNoteForClient(
                                context,
                                customerId: c['id'] as String,
                                customerName: c['name'] as String? ?? 'Unknown',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openNoteForClient(
    BuildContext context, {
    required String customerId,
    required String customerName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          customerId: customerId,
          customerName: customerName,
        ),
      ),
    );
  }

  /// Inline bottom-sheet dialog to create a new client and immediately
  /// open a note scoped to them — no detour through Customer Ledger.
  void _showInlineNewClientForNote(BuildContext context) {
    final nameCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'New client for note',
              style: AppTextStyles.sheetTitle(Theme.of(context).textTheme),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a name and we\u2019ll open the note editor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Client / Business name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _createClientAndOpenNote(ctx, nameCtrl.text),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => _createClientAndOpenNote(ctx, nameCtrl.text),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create & Start Note',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClientAndOpenNote(
      BuildContext sheetCtx, String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;

    final supabase = ref.read(supabaseServiceProvider);
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    try {
      await supabase.ensureValidSession();
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      await supabase.client.from('customers').insert({
        'id': id,
        'user_id': userId,
        'name': name,
        'created_at': now,
        'updated_at': now,
      });

      // Refresh client list
      ref.invalidate(customerLedgerListProvider);

      if (!mounted) return;
      // Close the bottom sheet
      Navigator.pop(sheetCtx);
      // Open the note editor for the new client
      _openNoteForClient(context, customerId: id, customerName: name);
    } catch (e) {
      if (sheetCtx.mounted) {
        ScaffoldMessenger.of(sheetCtx).showSnackBar(
          const SnackBar(
            content: Text('Could not create client. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE SECTION — Full-width tappable "Start with voice" card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVoiceSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      key: const ValueKey('home_voice_launcher'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          unawaited(HapticFeedback.mediumImpact());
          final result = await showAiAssistantOverlay(
            context,
            notifier: ref.read(aiAssistantProvider.notifier),
          );
          if (!mounted || result == null) {
            return;
          }
          await ref.read(aiActionCoordinatorProvider).execute(context, result);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Start with voice',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'AI',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Draft jobs, log expenses, record payments, or ask a question',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // URGENT SECTION — Unpaid/overdue invoices
  // ═══════════════════════════════════════════════════════════════════════════

  /// Semantic subtitle for an urgent card, e.g. "Invoice · overdue",
  /// "Invoice · due today", "Invoice · partially paid · sent 3d ago".
  String _urgentCardSubtitle(Job job) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paymentTag =
        job.isPartiallyPaid ? 'partially paid' : 'awaiting payment';

    if (job.dueDate != null) {
      final due =
          DateTime(job.dueDate!.year, job.dueDate!.month, job.dueDate!.day);
      if (due.isBefore(today)) return 'Invoice \u00b7 overdue';
      if (due.isAtSameMomentAs(today)) return 'Invoice \u00b7 due today';
      final daysLeft = due.difference(today).inDays;
      if (daysLeft <= 7) return 'Invoice \u00b7 due in ${daysLeft}d';
    }

    // No due date or far-out due date — show payment state + sent age
    final daysOut = now.difference(job.createdAt).inDays;
    if (daysOut == 0) return 'Invoice \u00b7 $paymentTag \u00b7 sent today';
    return 'Invoice \u00b7 $paymentTag \u00b7 sent ${daysOut}d ago';
  }

  Widget _buildUrgentSection(
      BuildContext context, String currencySymbol, JobListState jobState) {
    if (jobState.isLoading) return const SizedBox.shrink();

    // Urgent = sent invoices with outstanding balance (quotes excluded)
    final urgentJobs = jobState.jobs.where((j) => j.isAwaitingPayment).toList();

    if (urgentJobs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Urgent', onSeeAll: () {
          ref.read(historyInitialTabProvider.notifier).state = 2;
          ref.read(bottomNavIndexProvider.notifier).state = 1;
        }),
        const SizedBox(height: 10),
        ...urgentJobs.take(3).map((job) {
          final isOverdue =
              job.dueDate != null && job.dueDate!.isBefore(DateTime.now());
          final subtitle = _urgentCardSubtitle(job);

          final accentColor =
              isOverdue ? AppColors.overdue(context) : AppColors.sent(context);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openRecentJob(context, job),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: accentColor.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Warning icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.schedule_rounded,
                          color: accentColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Job details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.clientName,
                              style: AppTextStyles.cardTitle(textTheme),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? AppColors.overdue(context)
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isOverdue ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Amount due
                      Text(
                        '$currencySymbol${job.amountDue.toStringAsFixed(0)}',
                        style: AppTextStyles.cardAmount(textTheme).copyWith(
                          color: isOverdue ? AppColors.overdue(context) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 22),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT JOBS — Polished cards, prefer job title over client name dupe
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentJobs(
      BuildContext context, String currencySymbol, JobListState jobState) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Recent Jobs',
            onSeeAll: () =>
                ref.read(bottomNavIndexProvider.notifier).state = 1),
        const SizedBox(height: 10),
        if (jobState.isLoading)
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: ShimmerLoadingCard(height: 64),
            ),
          )
        else if (jobState.jobs.isEmpty)
          _buildEmptyJobsCard(context)
        else
          ...jobState.jobs.take(4).map((job) {
            // Build a meaningful subtitle: type label + detail + date.
            // Prefer job title unless it dupes the client name.
            // Exclude generic boilerplate that adds no value.
            const genericTexts = {
              'untitled job',
              'services rendered',
              'professional services',
              'labour',
              'labor',
              'service',
              'work performed',
            };
            bool isGeneric(String s) =>
                genericTexts.contains(s.toLowerCase().trim());
            final titleUsable = job.title.isNotEmpty &&
                !isGeneric(job.title) &&
                job.title.toLowerCase().trim() !=
                    job.clientName.toLowerCase().trim();
            final descUsable = (job.description?.isNotEmpty ?? false) &&
                !isGeneric(job.description!) &&
                job.description!.toLowerCase().trim() !=
                    job.clientName.toLowerCase().trim();
            final detail = titleUsable
                ? job.title
                : descUsable
                    ? job.description!
                    : null;
            final typeLabel = job.type.displayName;
            final dateStr = DateFormat('MMM d').format(job.createdAt);
            // "Invoice · Cabinet install · Mar 10" or "Quote · Mar 10"
            final subtitle = detail != null
                ? '$typeLabel \u00b7 $detail \u00b7 $dateStr'
                : '$typeLabel \u00b7 $dateStr';

            final statusColor = _getJobColor(context, job);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openRecentJob(context, job),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: statusColor.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            _getJobIcon(job),
                            color: statusColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Job details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.clientName,
                                style: AppTextStyles.cardTitle(textTheme),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppTextStyles.cardSubtitle(
                                    textTheme, colorScheme),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount + status badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currencySymbol${job.totalAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.cardAmount(textTheme),
                            ),
                            const SizedBox(height: 2),
                            _buildJobStatusChip(context, job),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {required VoidCallback onSeeAll}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionHeader(textTheme)),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor:
                colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('See All'),
        ),
      ],
    );
  }

  Future<void> _openRecentJob(BuildContext context, Job job) async {
    try {
      final fullJob = await _supabase
          .from('jobs')
          .select('*')
          .eq('id', job.id)
          .maybeSingle();
      if (!mounted) return;

      final payload = fullJob != null
          ? Map<String, dynamic>.from(fullJob)
          : <String, dynamic>{
              'id': job.id,
              'title': job.title,
              'client_name': job.clientName,
              'type': job.type.name,
              'status': job.status.name,
              'total_amount': job.totalAmount,
            };

      // Status-based routing:
      //   Draft → editor (most useful for work-in-progress)
      //   Sent/Paid/Cancelled → preview (finalized, review or reshare)
      final Widget destination = job.status == JobStatus.draft
          ? DraftReviewScreen(jobData: payload)
          : PdfPreviewScreen(jobData: payload);

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not open full job details. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Payment-aware status chip — shows "Paid" for fully-paid sent invoices.
  Widget _buildJobStatusChip(BuildContext context, Job job) {
    final color = _getJobColor(context, job);
    final label = job.isFullyPaid
        ? 'Paid'
        : job.status.name[0].toUpperCase() + job.status.name.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getJobIcon(job), size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.badge(color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJobsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.rocket_launch_outlined,
                  size: 22, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text('Get started',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: 14),

          // Quick steps
          _firstStepRow(context, Icons.mic, 'Record a voice memo',
              'Describe a job — AI creates the invoice'),
          const SizedBox(height: 10),
          _firstStepRow(context, Icons.receipt_long,
              'Create an invoice or quote', 'Tap + Create above'),
          const SizedBox(height: 10),
          _firstStepRow(context, Icons.document_scanner, 'Scan a receipt',
              'AI extracts line items and costs'),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Demo data option
          _DemoDataButton(onLoaded: () {
            ref.invalidate(jobStatsProvider);
            ref.invalidate(jobListProvider);
            ref.read(analyticsProvider.notifier).refresh();
            ref.invalidate(customerLedgerListProvider);
            ref.invalidate(expenseStatsProvider);
          }),
        ],
      ),
    );
  }

  Widget _firstStepRow(
      BuildContext context, IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              Text(subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTH PICKER
  // ═══════════════════════════════════════════════════════════════════════════

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    final months = <DateTime>[];
    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColorScheme = Theme.of(ctx).colorScheme;
        final sheetTextTheme = Theme.of(ctx).textTheme;
        // Cap the height to 60% of screen so it scrolls safely on small devices
        final maxHeight = MediaQuery.of(ctx).size.height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle (matches create sheet)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        sheetColorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Centered title (matches create sheet)
                Text(
                  'Select month',
                  style: AppTextStyles.sheetTitle(sheetTextTheme),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: months.length,
                    itemBuilder: (_, index) {
                      final month = months[index];
                      final isSelected = month.year == _selectedMonth.year &&
                          month.month == _selectedMonth.month;
                      final isCurrent =
                          month.year == now.year && month.month == now.month;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? sheetColorScheme.primary
                              : sheetColorScheme.outlineVariant,
                          size: 20,
                        ),
                        title: Text(
                          isCurrent
                              ? '${DateFormat('MMMM yyyy').format(month)} (Current)'
                              : DateFormat('MMMM yyyy').format(month),
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedMonth = month);
                          Navigator.pop(ctx);
                          // Sync with the global analytics month so the
                          // Analytics tab shows the same period.
                          ref
                              .read(selectedAnalyticsMonthProvider.notifier)
                              .state = month;
                          ref
                              .read(analyticsProvider.notifier)
                              .loadAnalytics(month: month);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Payment-aware color: fully-paid sent invoices get the "paid" color.
  Color _getJobColor(BuildContext context, Job job) {
    if (job.isFullyPaid) return AppColors.paid(context);
    switch (job.status) {
      case JobStatus.paid: // legacy — shouldn't happen
        return AppColors.paid(context);
      case JobStatus.sent:
        return AppColors.sent(context);
      case JobStatus.cancelled:
        return AppColors.overdue(context);
      case JobStatus.draft:
        return AppColors.draft(context);
    }
  }

  /// Payment-aware icon: fully-paid sent invoices get the checkmark.
  IconData _getJobIcon(Job job) {
    if (job.isFullyPaid) return Icons.check_circle_rounded;
    switch (job.status) {
      case JobStatus.paid:
        return Icons.check_circle_rounded;
      case JobStatus.sent:
        return Icons.send_rounded;
      case JobStatus.cancelled:
        return Icons.cancel_rounded;
      case JobStatus.draft:
        return Icons.edit_rounded;
    }
  }
}

/// Stateful widget for the "Load sample data" button on the dashboard empty state.
class _DemoDataButton extends StatefulWidget {
  final VoidCallback onLoaded;

  const _DemoDataButton({required this.onLoaded});

  @override
  State<_DemoDataButton> createState() => _DemoDataButtonState();
}

class _DemoDataButtonState extends State<_DemoDataButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Row(
      children: [
        Icon(Icons.science_outlined,
            size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Want to explore first?',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: TextButton(
            onPressed: _loading || userId == null
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await DemoDataService.seed(userId);
                      widget.onLoaded();
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not load sample data')),
                        );
                      }
                    }
                    if (mounted) setState(() => _loading = false);
                  },
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Load sample data'),
          ),
        ),
      ],
    );
  }
}
