import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../main_shell_screen.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshSpinCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _refreshSpinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshSpinCtrl.repeat();
    try {
      await ref.read(analyticsProvider.notifier).refresh();
      ref.invalidate(cashFlowTrendProvider);
      ref.invalidate(expenseByCategoryProvider);
      ref.invalidate(taxDeductibleSummaryProvider);
    } finally {
      if (mounted) {
        _refreshSpinCtrl.stop();
        _refreshSpinCtrl.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    final selected = ref.read(selectedAnalyticsMonthProvider);
    final months = <DateTime>[
      for (int i = 0; i < 12; i++) DateTime(now.year, now.month - i),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final ts = Theme.of(ctx).textTheme;
        final maxH = MediaQuery.of(ctx).size.height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('Select month',
                    style: ts.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: months.length,
                    itemBuilder: (_, i) {
                      final m = months[i];
                      final isSel =
                          m.year == selected.year && m.month == selected.month;
                      final isCur =
                          m.year == now.year && m.month == now.month;
                      return ListTile(
                        leading: Icon(
                          isSel
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSel ? cs.primary : cs.outlineVariant,
                          size: 20,
                        ),
                        title: Text(
                          isCur
                              ? '${DateFormat('MMMM yyyy').format(m)} (Current)'
                              : DateFormat('MMMM yyyy').format(m),
                          style: TextStyle(
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          ref
                              .read(selectedAnalyticsMonthProvider.notifier)
                              .state = m;
                          ref
                              .read(analyticsProvider.notifier)
                              .loadAnalytics(month: m);
                          Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final selectedMonth = ref.watch(selectedAnalyticsMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final monthLabel = isCurrentMonth
        ? 'This Month'
        : DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Month selector chip in the AppBar
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => RefreshIndicator(
          onRefresh: () async {
            final m = ref.read(selectedAnalyticsMonthProvider);
            await ref.read(analyticsProvider.notifier).loadAnalytics(month: m);
            ref.invalidate(cashFlowTrendProvider);
            ref.invalidate(expenseByCategoryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── SECTION A: Monthly Performance ──────────────────────
              _SectionHeader(
                title: 'Monthly Performance',
                subtitle: monthLabel,
              ),
              const SizedBox(height: 12),
              _buildMonthlyMetrics(context, analytics, currencySymbol),
              const SizedBox(height: 28),

              // ── SECTION B: Outstanding (always current) ────────────
              const _SectionHeader(
                title: 'Outstanding',
                subtitle: 'Current open invoices \u00b7 as of today',
              ),
              const SizedBox(height: 12),
              _buildOutstandingCard(context, analytics, currencySymbol),
              const SizedBox(height: 28),

              // ── SECTION C: Cash Flow ───────────────────────────────
              _SectionHeader(
                title: 'Cash Flow',
                subtitle:
                    '6 months ending ${DateFormat('MMM yyyy').format(selectedMonth)} \u00b7 Collected vs Spent',
              ),
              const SizedBox(height: 12),
              _CashFlowChart(currencySymbol: currencySymbol),
              const SizedBox(height: 28),

              // ── SECTION D: Expense Breakdown (selected month) ──────
              _SectionHeader(
                title: 'Expense Breakdown',
                subtitle: monthLabel,
              ),
              const SizedBox(height: 12),
              _ExpensePieChart(
                  currencySymbol: currencySymbol,
                  monthLabel: monthLabel),
              const SizedBox(height: 28),

              // ── SECTION E: All-Time Summary ────────────────────────
              const _SectionHeader(
                title: 'All-Time Summary',
                subtitle: 'Since you started using the app',
              ),
              const SizedBox(height: 12),
              _buildAllTimeSummary(context, analytics, currencySymbol),
              const SizedBox(height: 28),

              // ── SECTION F: Tax (YTD) ───────────────────────────────
              _TaxDeductibleCard(currencySymbol: currencySymbol),
            ],
          ),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(6, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerLoadingCard(height: 100),
          )),
        ),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.read(analyticsProvider.notifier).refresh(),
        ),
      ),
    );
  }

  // ── This Month metrics ──────────────────────────────────────────────────────

  Widget _buildMonthlyMetrics(
      BuildContext context, BusinessAnalytics analytics, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _HeroCard(
            title: 'Collected',
            value: '$cs${analytics.monthlyRevenue.toStringAsFixed(0)}',
            subtitle: 'Cash received',
            icon: Icons.trending_up,
            color: AppColors.paid(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroCard(
            title: 'Spent',
            value: '$cs${analytics.monthlyExpenses.toStringAsFixed(0)}',
            subtitle: 'Expenses logged',
            icon: Icons.arrow_downward,
            color: AppColors.expense(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroCard(
            title: 'Profit',
            value: '$cs${analytics.monthlyProfit.toStringAsFixed(0)}',
            subtitle: analytics.monthlyRevenue > 0
                ? '${(analytics.monthlyProfit / analytics.monthlyRevenue * 100).toStringAsFixed(0)}% margin'
                : '\u2014',
            icon: Icons.account_balance_wallet,
            color: analytics.monthlyProfit >= 0
                ? colorScheme.primary
                : colorScheme.error,
          ),
        ),
      ],
    );
  }

  // ── Outstanding card (tappable) ─────────────────────────────────────────────

  Widget _buildOutstandingCard(
      BuildContext context, BusinessAnalytics analytics, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = analytics.outstandingInvoiceCount;
    return GestureDetector(
      onTap: () {
        // Navigate to Jobs → Sent tab filtered to outstanding invoices
        ref.read(historyOutstandingFilterProvider.notifier).state = true;
        ref.read(historyInitialTabProvider.notifier).state = 2;
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.access_time,
                  color: colorScheme.tertiary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cs${analytics.outstandingRevenue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? 'All invoices settled'
                        : count == 1
                            ? '1 invoice awaiting payment'
                            : '$count invoices awaiting payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  // ── All-Time Summary ────────────────────────────────────────────────────────

  Widget _buildAllTimeSummary(
      BuildContext context, BusinessAnalytics analytics, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _HealthTile(
          icon: Icons.work_outline,
          label: 'Total Documents',
          value: '${analytics.totalJobs}',
          detail: _buildJobBreakdown(analytics),
          color: colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _HealthTile(
          icon: Icons.attach_money,
          label: 'Avg. Document Value',
          value: '$cs${analytics.averageJobValue.toStringAsFixed(0)}',
          detail: 'Across all invoices & quotes',
          color: AppColors.paid(context),
        ),
        const SizedBox(height: 8),
        _HealthTile(
          icon: Icons.savings_outlined,
          label: 'Lifetime Profit',
          value: '$cs${analytics.totalProfit.toStringAsFixed(0)}',
          detail:
              '${analytics.profitMargin.toStringAsFixed(1)}% overall margin',
          color: analytics.totalProfit >= 0
              ? AppColors.paid(context)
              : colorScheme.error,
        ),
      ],
    );
  }

  /// Builds a non-overlapping breakdown string like "2 paid · 3 unpaid · 1 draft".
  String _buildJobBreakdown(BusinessAnalytics a) {
    final parts = <String>[];
    if (a.paidJobsCount > 0) parts.add('${a.paidJobsCount} paid');
    if (a.sentUnpaidCount > 0) parts.add('${a.sentUnpaidCount} unpaid');
    if (a.draftCount > 0) parts.add('${a.draftCount} draft');
    if (a.cancelledCount > 0) parts.add('${a.cancelledCount} cancelled');
    return parts.isEmpty ? '\u2014' : parts.join(' \u00b7 ');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HeroCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CASH FLOW CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _CashFlowChart extends ConsumerWidget {
  final String currencySymbol;
  const _CashFlowChart({required this.currencySymbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowTrendProvider);

    return cashFlowAsync.when(
      data: (data) {
        // Check if there's any meaningful data in the window
        final hasData = data.isNotEmpty &&
            data.any((d) => d.income > 0.01 || d.expenses > 0.01);

        if (data.isEmpty || !hasData) {
          // Show month labels even in empty state so it feels anchored
          return _buildEmptyCashFlow(context, ref, data);
        }
        final colorScheme = Theme.of(context).colorScheme;
        final maxY = _calcMaxY(data);
        // Compute a clean interval so labels don't overlap
        final interval = _niceInterval(maxY);

        return Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend row
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    _legendDot(AppColors.paid(context), 'Collected'),
                    const SizedBox(width: 16),
                    _legendDot(AppColors.expense(context), 'Expenses'),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final month = data[groupIndex];
                          final label =
                              rodIndex == 0 ? 'Collected' : 'Expenses';
                          final val = rodIndex == 0
                              ? month.income
                              : month.expenses;
                          return BarTooltipItem(
                            '$label\n$currencySymbol${val.toStringAsFixed(0)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM').format(data[idx].date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            // Hide the max value label to prevent overlap
                            if (value == meta.max || value == 0) {
                              return const SizedBox.shrink();
                            }
                            String label;
                            if (value >= 1000) {
                              label =
                                  '$currencySymbol${(value / 1000).toStringAsFixed(1)}k';
                            } else {
                              label =
                                  '$currencySymbol${value.toStringAsFixed(0)}';
                            }
                            return Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: data.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.income,
                            color: AppColors.paid(context),
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: entry.value.expenses,
                            color: AppColors.expense(context),
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const ShimmerLoadingCard(height: 260),
      error: (_, __) => _emptyPlaceholder(
        icon: Icons.bar_chart,
        message: 'Failed to load chart',
        hint: 'Pull down to retry.',
      ),
    );
  }

  /// Empty/near-empty cash flow state — shows month labels so the period
  /// is clear, with an overlay message.
  Widget _buildEmptyCashFlow(
      BuildContext context, WidgetRef ref, List<CashFlowData> data) {
    final colorScheme = Theme.of(context).colorScheme;
    final anchor = ref.watch(selectedAnalyticsMonthProvider);
    // Generate month labels even if data is empty
    final months = data.isNotEmpty
        ? data.map((d) => DateFormat('MMM').format(d.date)).toList()
        : [
            for (int i = 5; i >= 0; i--)
              DateFormat('MMM').format(
                  DateTime(anchor.year, anchor.month - i, 1)),
          ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Empty state message
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart,
                      size: 32,
                      color: colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  Text(
                    'No cash flow in this period',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Record payments or expenses to see your trend.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Month labels at bottom — anchored to the selected period
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: months
                .map((m) => Text(m,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Builder(builder: (context) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
    });
  }

  double _calcMaxY(List<CashFlowData> data) {
    double maxVal = 100;
    for (final d in data) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expenses > maxVal) maxVal = d.expenses;
    }
    return maxVal * 1.15; // 15% headroom
  }

  /// Compute a "nice" interval that avoids label overlap.
  double _niceInterval(double maxY) {
    if (maxY <= 500) return 100;
    if (maxY <= 2000) return 500;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    return (maxY / 5).ceilToDouble();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPENSE PIE CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _ExpensePieChart extends ConsumerWidget {
  final String currencySymbol;
  final String monthLabel;
  const _ExpensePieChart(
      {required this.currencySymbol, required this.monthLabel});

  static const _colors = [
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.pink,
    Colors.brown,
    Colors.red,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(expenseByCategoryProvider);

    return categoryAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _emptyPlaceholder(
            icon: Icons.pie_chart_outline,
            message: 'No expenses in $monthLabel',
            hint: 'Log receipts or expenses to see your breakdown.',
          );
        }

        final total = categories.values.fold(0.0, (sum, val) => sum + val);
        final entries = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: entries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cat = entry.value;
                      final pct =
                          total > 0 ? (cat.value / total * 100) : 0.0;
                      return PieChartSectionData(
                        value: cat.value,
                        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                        color: _colors[idx % _colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final displayName =
                      cat.key[0].toUpperCase() + cat.key.substring(1);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colors[idx % _colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$displayName ($currencySymbol${cat.value.toStringAsFixed(0)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const ShimmerLoadingCard(height: 280),
      error: (_, __) => _emptyPlaceholder(
        icon: Icons.pie_chart_outline,
        message: 'Failed to load expenses',
        hint: 'Pull down to retry.',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAX DEDUCTIBLE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _TaxDeductibleCard extends ConsumerWidget {
  final String currencySymbol;
  const _TaxDeductibleCard({required this.currencySymbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxDeductibleSummaryProvider);

    return taxAsync.when(
      data: (total) => Builder(builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Tax Deductions',
              subtitle: 'Year to date \u00b7 ${DateTime.now().year}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long,
                        color: colorScheme.onTertiary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currencySymbol${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Deductible expenses recorded',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      loading: () => const ShimmerLoadingCard(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEALTH TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _HealthTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _HealthTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _emptyPlaceholder({
  required IconData icon,
  required String message,
  required String hint,
}) {
  return Builder(builder: (context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: colorScheme.outlineVariant),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  });
}
