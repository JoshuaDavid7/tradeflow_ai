import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/material_cost_repository.dart';
import '../../data/local/database.dart' show AppDatabase, databaseProvider, RecognizedMaterialCost;
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

// ── Expense Month Selector ───────────────────────────────────────────────────

/// The month currently selected on the Expenses screen.
final selectedExpenseMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Expense list state
class ExpenseListState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;

  const ExpenseListState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseListState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Expense list notifier
class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  final IExpenseRepository _repository;
  final String? _userId;

  ExpenseListNotifier(this._repository, this._userId)
      : super(const ExpenseListState()) {
    if (_userId != null) {
      Future<void>(loadExpenses);
    }
  }

  /// Load all expenses
  Future<void> loadExpenses() async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final expenses = await _repository.getAllExpenses(_userId!);

      state = state.copyWith(
        expenses: expenses,
        isLoading: false,
      );

      ErrorHandler.debug('Expenses loaded', {'count': expenses.length});
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Create new expense
  Future<Expense?> createExpense(Expense expense) async {
    try {
      final created = await _repository.createExpense(expense);

      // Add to local state
      state = state.copyWith(
        expenses: [created, ...state.expenses],
      );

      ErrorHandler.info('Expense created', {'id': created.id});
      return created;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return null;
    }
  }

  /// Update expense
  Future<bool> updateExpense(String id, Expense expense) async {
    try {
      final updated = await _repository.updateExpense(id, expense);

      // Update in local state
      final updatedExpenses = state.expenses
          .map<Expense>((e) => e.id == id ? updated : e)
          .toList();

      state = state.copyWith(expenses: updatedExpenses);

      ErrorHandler.info('Expense updated', {'id': id});
      return true;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Delete expense
  Future<bool> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);

      // Remove from local state
      final updatedExpenses = state.expenses.where((e) => e.id != id).toList();
      state = state.copyWith(expenses: updatedExpenses);

      ErrorHandler.info('Expense deleted', {'id': id});
      return true;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Attach receipt to expense
  Future<bool> attachReceipt(
    String expenseId,
    String receiptPath,
    String? ocrText,
  ) async {
    try {
      await _repository.attachReceipt(expenseId, receiptPath, ocrText);

      // Update in local state
      final updatedExpenses = state.expenses.map((e) {
        if (e.id == expenseId) {
          return e.copyWith(
            receiptPath: receiptPath,
            ocrText: ocrText,
          );
        }
        return e;
      }).toList();

      state = state.copyWith(expenses: updatedExpenses);

      ErrorHandler.info('Receipt attached', {'expenseId': expenseId});
      return true;
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Refresh expenses
  Future<void> refresh() => loadExpenses();
}

/// Provider for expense list
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final userId = ref.watch(userIdProvider);

  return ExpenseListNotifier(repository, userId);
});

/// Provider for expense statistics
final expenseStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return await repository.getExpenseStats(userId);
});

/// Provider for expenses by category
final expensesByCategoryProvider =
    Provider<Map<ExpenseCategory, List<Expense>>>((ref) {
  final expenses = ref.watch(expenseListProvider).expenses;

  final Map<ExpenseCategory, List<Expense>> grouped = {};

  for (final expense in expenses) {
    if (!grouped.containsKey(expense.category)) {
      grouped[expense.category] = [];
    }
    grouped[expense.category]!.add(expense);
  }

  return grouped;
});

/// Provider for this month's expenses
final monthlyExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseListProvider).expenses;
  final now = DateTime.now();

  return expenses.where((expense) {
    final localDate = expense.expenseDate.toLocal();
    return localDate.month == now.month &&
        localDate.year == now.year;
  }).toList();
});

/// Provider for tax deductible expenses
final taxDeductibleExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseListProvider).expenses;
  return expenses.where((e) => e.taxDeductible).toList();
});

/// Provider for expenses with receipts
final expensesWithReceiptsProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseListProvider).expenses;
  return expenses.where((e) => e.hasReceipt).toList();
});

/// Provider for job-specific expenses
final jobExpensesProvider =
    Provider.family<List<Expense>, String>((ref, jobId) {
  final expenses = ref.watch(expenseListProvider).expenses;
  return expenses.where((e) => e.jobId == jobId).toList();
});

// ── Cost Breakdown (summary totals) ──────────────────────────────────────────

class CostBreakdown {
  final double standaloneTotal;
  final double standaloneMonthly;
  final double materialCostTotal;
  final double materialCostMonthly;
  final Set<String> linkedExpenseIds;
  final double totalCosts;
  final double monthlyCosts;
  final List<RecognizedMaterialCost> materialCosts;

  const CostBreakdown({
    required this.standaloneTotal,
    required this.standaloneMonthly,
    required this.materialCostTotal,
    required this.materialCostMonthly,
    required this.linkedExpenseIds,
    required this.totalCosts,
    required this.monthlyCosts,
    required this.materialCosts,
  });
}

final costBreakdownProvider = FutureProvider<CostBreakdown>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final materialCostRepo = ref.watch(materialCostRepositoryProvider);
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(userIdProvider);
  final selectedMonth = ref.watch(selectedExpenseMonthProvider);

  if (userId == null) throw Exception('User not authenticated');

  final allExpenses = await repository.getAllExpenses(userId);
  final linkedIds = await materialCostRepo.getLinkedExpenseIds(userId);
  final activeCosts = await db.materialCostDao.getActiveByUser(userId);

  double standaloneTotal = 0, standaloneMonthly = 0;
  for (final e in allExpenses) {
    if (linkedIds.contains(e.id)) continue;
    standaloneTotal += e.amount;
    final d = e.expenseDate.toLocal();
    if (d.year == selectedMonth.year && d.month == selectedMonth.month) {
      standaloneMonthly += e.amount;
    }
  }

  double materialCostTotal = 0, materialCostMonthly = 0;
  for (final c in activeCosts) {
    materialCostTotal += c.canonicalCost;
    final d = c.recognitionDate.toLocal();
    if (d.year == selectedMonth.year && d.month == selectedMonth.month) {
      materialCostMonthly += c.canonicalCost;
    }
  }

  return CostBreakdown(
    standaloneTotal: standaloneTotal,
    standaloneMonthly: standaloneMonthly,
    materialCostTotal: materialCostTotal,
    materialCostMonthly: materialCostMonthly,
    linkedExpenseIds: linkedIds,
    totalCosts: standaloneTotal + materialCostTotal,
    monthlyCosts: standaloneMonthly + materialCostMonthly,
    materialCosts: activeCosts,
  );
});

// ── Unified Cost Ledger ──────────────────────────────────────────────────────

/// The type of a row in the unified cost ledger.
enum CostEntryType {
  /// A manually-logged or receipt-scanned expense (not linked to material cost).
  loggedExpense,
  /// A logged expense that is linked to a material cost (counted via canonical cost).
  linkedExpense,
  /// An invoice-derived material cost (estimated or actual).
  invoiceMaterial,
}

/// A single row in the unified cost ledger.
class CostLedgerEntry {
  final String id;
  final CostEntryType type;
  final String description;
  final double amount;          // The canonical cost that counts toward "Spent"
  final DateTime date;
  final String? jobId;
  final String? jobName;        // Resolved from job (e.g. "Bathroom Repair")
  final String? clientName;     // Resolved from job
  final String? invoiceNumber;  // Resolved from job
  final String? category;       // For logged expenses
  final String? vendor;         // For logged expenses
  final bool isEstimated;       // Material cost using invoice fallback
  final String? linkedToMaterialId; // For linked expenses: which material cost
  final String? linkedReceiptName;  // For materials: name of the linked receipt
  final double? linkedReceiptAmount; // For materials: amount of the linked receipt
  final Expense? expense;       // Original expense object (for logged/linked)
  final RecognizedMaterialCost? materialCost; // Original material cost

  const CostLedgerEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.jobId,
    this.jobName,
    this.clientName,
    this.invoiceNumber,
    this.category,
    this.vendor,
    this.isEstimated = false,
    this.linkedToMaterialId,
    this.linkedReceiptName,
    this.linkedReceiptAmount,
    this.expense,
    this.materialCost,
  });
}

/// Provider that produces the unified cost ledger — every row that contributes
/// to "Spent", with no double-counting. Sorted by date descending.
final costLedgerProvider = FutureProvider<List<CostLedgerEntry>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final materialCostRepo = ref.watch(materialCostRepositoryProvider);
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) throw Exception('User not authenticated');

  final allExpenses = await repository.getAllExpenses(userId);
  final linkedIds = await materialCostRepo.getLinkedExpenseIds(userId);
  final activeCosts = await db.materialCostDao.getActiveByUser(userId);

  // Build a map of jobId -> {clientName, invoiceNumber, jobName} for enrichment.
  // Try local Drift DB first, fall back to Supabase for jobs not yet synced locally.
  final jobInfoCache = <String, Map<String, String>>{};
  Future<Map<String, String>> getJobInfo(String jobId) async {
    if (jobInfoCache.containsKey(jobId)) return jobInfoCache[jobId]!;
    try {
      // Try local DB first
      final rows = await db.jobDao.getJobById(jobId);
      if (rows != null) {
        jobInfoCache[jobId] = {
          'clientName': rows.clientName,
          'invoiceNumber': rows.title,
          'jobName': rows.description ?? '',
        };
        return jobInfoCache[jobId]!;
      }
      // Fall back to Supabase
      final supabase = ref.read(supabaseProvider);
      final data = await supabase
          .from('jobs')
          .select('invoice_number, client_name, description')
          .eq('id', jobId)
          .maybeSingle();
      if (data != null) {
        jobInfoCache[jobId] = {
          'clientName': data['client_name']?.toString() ?? '',
          'invoiceNumber': data['invoice_number']?.toString() ?? '',
          'jobName': data['description']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('Failed to fetch job info for $jobId: $e');
    }
    return jobInfoCache[jobId] ?? {};
  }

  // Build a map of materialCostId -> linked expenseId for cross-reference
  final costToExpenseId = <String, String>{};
  for (final c in activeCosts) {
    final links = await db.materialCostDao.getLinksForCost(c.id);
    if (links.isNotEmpty) {
      costToExpenseId[c.id] = links.first.expenseId;
    }
  }

  final entries = <CostLedgerEntry>[];

  // 1) Standalone logged expenses (not linked to any material cost)
  for (final e in allExpenses) {
    if (linkedIds.contains(e.id)) continue;
    final jobInfo = e.jobId != null ? await getJobInfo(e.jobId!) : <String, String>{};
    entries.add(CostLedgerEntry(
      id: 'exp_${e.id}',
      type: CostEntryType.loggedExpense,
      description: e.description,
      amount: e.amount,
      date: e.expenseDate,
      jobId: e.jobId,
      jobName: jobInfo['jobName'],
      clientName: jobInfo['clientName'],
      invoiceNumber: jobInfo['invoiceNumber'],
      category: e.category.displayName,
      vendor: e.vendor,
      expense: e,
    ));
  }

  // 2) Invoice material costs (estimated or linked/actual)
  for (final c in activeCosts) {
    final linkedExpId = costToExpenseId[c.id];
    final isLinked = linkedExpId != null;
    // Resolve linked receipt info for "Actual" materials
    String? receiptName;
    double? receiptAmount;
    if (isLinked) {
      final linkedExp = allExpenses.where((e) => e.id == linkedExpId);
      if (linkedExp.isNotEmpty) {
        receiptName = linkedExp.first.description;
        receiptAmount = linkedExp.first.amount;
      }
    }
    final jobInfo = c.jobId != null ? await getJobInfo(c.jobId!) : <String, String>{};
    entries.add(CostLedgerEntry(
      id: 'mat_${c.id}',
      type: CostEntryType.invoiceMaterial,
      description: c.description,
      amount: c.canonicalCost,
      date: c.recognitionDate,
      jobId: c.jobId,
      jobName: jobInfo['jobName'],
      clientName: jobInfo['clientName'],
      invoiceNumber: jobInfo['invoiceNumber'],
      isEstimated: !isLinked,
      linkedReceiptName: receiptName,
      linkedReceiptAmount: receiptAmount,
      materialCost: c,
    ));
  }

  // 3) Linked expenses — informational "shadow" rows (NOT counted in totals).
  //    Resolve context from the material cost's job (the invoice it's linked to),
  //    falling back to the expense's own job if needed.
  for (final e in allExpenses) {
    if (!linkedIds.contains(e.id)) continue;
    String? matCostId;
    String? matJobId;
    for (final pair in costToExpenseId.entries) {
      if (pair.value == e.id) {
        matCostId = pair.key;
        // Find the material cost's jobId for invoice context
        final mc = activeCosts.where((c) => c.id == pair.key);
        if (mc.isNotEmpty) matJobId = mc.first.jobId;
        break;
      }
    }
    // Prefer the material cost's job (= the invoice) for context,
    // fall back to the expense's own job
    final contextJobId = matJobId ?? e.jobId;
    final jobInfo = contextJobId != null ? await getJobInfo(contextJobId) : <String, String>{};
    entries.add(CostLedgerEntry(
      id: 'linked_${e.id}',
      type: CostEntryType.linkedExpense,
      description: e.description,
      amount: e.amount,
      date: e.expenseDate,
      jobId: contextJobId,
      jobName: jobInfo['jobName'],
      clientName: jobInfo['clientName'],
      invoiceNumber: jobInfo['invoiceNumber'],
      category: e.category.displayName,
      vendor: e.vendor,
      linkedToMaterialId: matCostId,
      expense: e,
    ));
  }

  // Sort by date descending
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

// ── Needs Action Buckets ─────────────────────────────────────────────────────

/// Categorises cost ledger entries that need user attention.
///
/// Important: "Not invoiced" and "Overhead" are different states.
///   • Not invoiced = not yet assigned to a job/invoice, needs review
///   • Overhead     = intentionally general business cost (not job-specific)
///   • Estimated    = invoice material using fallback cost, no linked receipt
class NeedsActionBuckets {
  /// Invoice materials still using estimate (no linked receipt).
  final List<CostLedgerEntry> estimated;

  /// Logged expenses not yet assigned to any job — needs review.
  final List<CostLedgerEntry> unassigned;

  int get totalCount => estimated.length + unassigned.length;
  bool get isEmpty => totalCount == 0;

  const NeedsActionBuckets({
    this.estimated = const [],
    this.unassigned = const [],
  });
}

/// Computes "Needs Action" buckets from the cost ledger.
final needsActionProvider = FutureProvider<NeedsActionBuckets>((ref) async {
  final entries = await ref.watch(costLedgerProvider.future);

  final estimated = <CostLedgerEntry>[];
  final unassigned = <CostLedgerEntry>[];

  for (final e in entries) {
    if (e.type == CostEntryType.invoiceMaterial && e.isEstimated) {
      estimated.add(e);
    } else if (e.type == CostEntryType.loggedExpense && e.jobId == null) {
      // Not assigned to a job — user should review and either assign
      // to a job or confirm it is intentional overhead.
      unassigned.add(e);
    }
  }

  return NeedsActionBuckets(
    estimated: estimated,
    unassigned: unassigned,
  );
});
