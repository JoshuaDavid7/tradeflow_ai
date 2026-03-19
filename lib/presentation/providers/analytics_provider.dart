import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/material_cost_repository.dart';
import '../../data/local/database.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

/// The month currently selected in the Analytics page. Other providers
/// watch this so that changing it triggers a cascade refresh.
final selectedAnalyticsMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Business analytics data
class BusinessAnalytics {
  // Revenue
  final double totalRevenue;
  final double monthlyRevenue;
  final double outstandingRevenue;

  // Expenses
  final double totalExpenses;
  final double monthlyExpenses;

  // Profit
  final double totalProfit;
  final double monthlyProfit;
  final double profitMargin;

  // Jobs
  final int totalJobs;
  final int activeJobs;
  final int completedJobs;

  // Non-overlapping status breakdown
  final int draftCount;
  final int sentUnpaidCount;
  final int paidJobsCount;
  final int cancelledCount;

  // Payments
  final double averageJobValue;
  final double averagePaymentTime; // days

  final int outstandingInvoiceCount;

  const BusinessAnalytics({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.outstandingRevenue,
    this.outstandingInvoiceCount = 0,
    required this.totalExpenses,
    required this.monthlyExpenses,
    required this.totalProfit,
    required this.monthlyProfit,
    required this.profitMargin,
    required this.totalJobs,
    required this.activeJobs,
    required this.completedJobs,
    this.draftCount = 0,
    this.sentUnpaidCount = 0,
    this.paidJobsCount = 0,
    this.cancelledCount = 0,
    required this.averageJobValue,
    required this.averagePaymentTime,
  });
}

/// Cash flow data
class CashFlowData {
  final DateTime date;
  final double income;
  final double expenses;
  final double net;

  const CashFlowData({
    required this.date,
    required this.income,
    required this.expenses,
    required this.net,
  });
}

/// Analytics notifier
class AnalyticsNotifier extends StateNotifier<AsyncValue<BusinessAnalytics>> {
  final IJobRepository _jobRepository;
  final IExpenseRepository _expenseRepository;
  final MaterialCostRepository _materialCostRepository;
  final String? _userId;

  AnalyticsNotifier(
    this._jobRepository,
    this._expenseRepository,
    this._materialCostRepository,
    this._userId,
  ) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _initAndLoad();
    }
  }

  static const _backfillKey = 'material_cost_backfill_done';
  DateTime? _selectedMonth;

  Future<void> _initAndLoad() async {
    // One-time backfill of recognized material costs for existing sent
    // invoices that were created before the cost-recognition system.
    // Persistent guard ensures this only runs once across app launches.
    if (_userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool(_backfillKey) ?? false;
        if (!done) {
          await _materialCostRepository.backfillForUser(_userId!);
          await prefs.setBool(_backfillKey, true);
        }
      } catch (_) {
        // Non-fatal — analytics still load without backfill.
      }
    }
    await loadAnalytics();
  }

  /// Load business analytics, optionally for a specific month
  Future<void> loadAnalytics({DateTime? month}) async {
    _selectedMonth = month;
    if (_userId == null) {
      state = AsyncValue.error(
        Exception('User not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Get job stats
      final jobStats = await _jobRepository.getJobStats(_userId!, month: month);

      // Get expense stats
      final expenseStats = await _expenseRepository.getExpenseStats(_userId!, month: month);

      // Calculate analytics
      final monthlyRevenue = jobStats['monthlyRevenue'] as double? ?? 0.0;
      final outstandingRevenue =
          jobStats['outstandingRevenue'] as double? ?? 0.0;
      final totalRevenue = ((jobStats['totalRevenue'] as num?) ??
              (jobStats['totalPaid'] as num?) ??
              0)
          .toDouble();

      final targetMonth = month ?? DateTime.now();

      // ── Material-cost-aware Spent formula ─────────────────────────────────
      // Spent = operating_expenses (excluding linked) + recognized material costs
      // This prevents double-counting when an expense is also linked as a
      // canonical material cost on an invoice.
      final linkedExpenseIds =
          await _materialCostRepository.getLinkedExpenseIds(_userId!);
      final totalMaterialCosts =
          await _materialCostRepository.getTotalActiveMaterialCosts(_userId!);
      final monthlyMaterialCosts = await _materialCostRepository
          .getTotalActiveMaterialCosts(_userId!, month: targetMonth);

      final rawTotalExpenses =
          expenseStats['totalExpenses'] as double? ?? 0.0;
      final rawMonthlyExpenses =
          expenseStats['monthlyExpenses'] as double? ?? 0.0;

      // Subtract linked expense amounts so they aren't counted twice.
      // For now we subtract the full amount of any linked expense from the
      // operating total.  The canonical cost replaces it.
      double linkedTotal = 0.0;
      double linkedMonthly = 0.0;
      if (linkedExpenseIds.isNotEmpty) {
        try {
          final allExpenses =
              await _expenseRepository.getAllExpenses(_userId!);
          for (final e in allExpenses) {
            if (!linkedExpenseIds.contains(e.id)) continue;
            linkedTotal += e.amount;
            final d = e.expenseDate.toLocal();
            if (d.year == targetMonth.year &&
                d.month == targetMonth.month) {
              linkedMonthly += e.amount;
            }
          }
        } catch (_) {
          // If we can't read expenses, fall back to raw totals.
        }
      }

      final totalExpenses =
          (rawTotalExpenses - linkedTotal) + totalMaterialCosts;
      final monthlyExpenses =
          (rawMonthlyExpenses - linkedMonthly) + monthlyMaterialCosts;

      final totalProfit = totalRevenue - totalExpenses;
      final monthlyProfit = monthlyRevenue - monthlyExpenses;

      final profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

      final totalJobs = jobStats['totalJobs'] as int? ?? 0;
      final activeJobs = jobStats['activeJobsCount'] as int? ?? 0;
      final completedJobs = totalJobs - activeJobs;

      final averageJobValue = totalJobs > 0
          ? (((jobStats['totalBilled'] as num?) ?? totalRevenue) / totalJobs)
              .toDouble()
          : 0.0;

      final outstandingInvoiceCount =
          jobStats['outstandingInvoiceCount'] as int? ?? 0;
      final paidJobsCount = jobStats['paidJobsCount'] as int? ?? 0;
      final draftCount = jobStats['draftCount'] as int? ?? 0;
      final sentUnpaidCount = jobStats['sentUnpaidCount'] as int? ?? 0;
      final cancelledCount = jobStats['cancelledCount'] as int? ?? 0;

      final analytics = BusinessAnalytics(
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        outstandingRevenue: outstandingRevenue,
        outstandingInvoiceCount: outstandingInvoiceCount,
        totalExpenses: totalExpenses,
        monthlyExpenses: monthlyExpenses,
        totalProfit: totalProfit,
        monthlyProfit: monthlyProfit,
        profitMargin: profitMargin,
        totalJobs: totalJobs,
        activeJobs: activeJobs,
        completedJobs: completedJobs,
        draftCount: draftCount,
        sentUnpaidCount: sentUnpaidCount,
        paidJobsCount: paidJobsCount,
        cancelledCount: cancelledCount,
        averageJobValue: averageJobValue,
        averagePaymentTime: (jobStats['averagePaymentDays'] as num?)?.toDouble() ?? 0.0,
      );

      state = AsyncValue.data(analytics);

      ErrorHandler.debug('Analytics loaded', {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'profit': totalProfit,
      });
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh analytics (preserves current month selection)
  Future<void> refresh() => loadAnalytics(month: _selectedMonth);
}

/// Provider for business analytics
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<BusinessAnalytics>>(
        (ref) {
  final jobRepository = ref.watch(jobRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final materialCostRepository = ref.watch(materialCostRepositoryProvider);
  final userId = ref.watch(userIdProvider);

  return AnalyticsNotifier(
      jobRepository, expenseRepository, materialCostRepository, userId);
});

/// Provider for profit margin
final profitMarginProvider = Provider<double>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.when(
    data: (data) => data.profitMargin,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for monthly profit
final monthlyProfitProvider = Provider<double>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return analytics.when(
    data: (data) => data.monthlyProfit,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for cash flow trend (last 6 months).
/// Income uses actual Payment records grouped by receivedAt month — partial
/// payments are counted in the month they were received, not deferred until
/// the invoice is fully settled.  Expenses use the user-set expenseDate.
final cashFlowTrendProvider = FutureProvider<List<CashFlowData>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final materialCostRepo = ref.watch(materialCostRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  final anchor = ref.watch(selectedAnalyticsMonthProvider);

  if (userId == null) return [];

  try {
    // 6 months ending at the selected month
    final monthDates = <DateTime>[
      for (int i = 5; i >= 0; i--)
        DateTime(anchor.year, anchor.month - i, 1),
    ];

    // Income: actual cash collected per month from Payment records.
    final collectedByMonth =
        await jobRepository.getMonthlyCollectedForMonths(userId, monthDates);

    // Expenses: dedup-aware — exclude linked expenses, add material costs.
    final expenses = await expenseRepository.getAllExpenses(userId);
    final linkedIds = await materialCostRepo.getLinkedExpenseIds(userId);
    final activeCosts =
        await ref.read(databaseProvider).materialCostDao.getActiveByUser(userId);

    final months = <CashFlowData>[];
    for (final monthDate in monthDates) {
      final income = collectedByMonth[monthDate] ?? 0.0;

      // Operating expenses (not linked to material costs) in this month
      final opEx = expenses
          .where((e) {
            if (linkedIds.contains(e.id)) return false;
            final d = e.expenseDate.toLocal();
            return d.year == monthDate.year && d.month == monthDate.month;
          })
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      // Recognized material costs in this month
      final matCosts = activeCosts
          .where((c) {
            final d = c.recognitionDate.toLocal();
            return d.year == monthDate.year && d.month == monthDate.month;
          })
          .fold<double>(0.0, (sum, c) => sum + c.canonicalCost);

      final totalSpent = opEx + matCosts;

      months.add(CashFlowData(
        date: monthDate,
        income: income,
        expenses: totalSpent,
        net: income - totalSpent,
      ));
    }

    return months;
  } catch (error, stackTrace) {
    ErrorHandler.handle(error, stackTrace);
    return [];
  }
});

/// Provider for expense breakdown by category — scoped to selected month.
final expenseByCategoryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  final month = ref.watch(selectedAnalyticsMonthProvider);

  if (userId == null) return {};

  try {
    final stats = await expenseRepository.getExpenseStats(userId, month: month);
    return Map<String, double>.from(
        stats['monthlyCategoryTotals'] as Map? ?? {});
  } catch (error, stackTrace) {
    ErrorHandler.handle(error, stackTrace);
    return {};
  }
});

/// Provider for tax deductible summary
final taxDeductibleSummaryProvider = FutureProvider<double>((ref) async {
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) return 0.0;

  try {
    final stats = await expenseRepository.getExpenseStats(userId);
    return stats['taxDeductibleTotal'] as double? ?? 0.0;
  } catch (error, stackTrace) {
    ErrorHandler.handle(error, stackTrace);
    return 0.0;
  }
});
