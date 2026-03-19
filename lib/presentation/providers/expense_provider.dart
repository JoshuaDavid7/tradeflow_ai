import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

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
      loadExpenses();
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
