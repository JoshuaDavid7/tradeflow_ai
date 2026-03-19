import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart' as domain;
import '../local/database.dart' as localdb;
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import 'package:drift/drift.dart' as drift;

/// Expense repository interface
abstract class IExpenseRepository {
  Future<List<domain.Expense>> getAllExpenses(String userId);
  Future<List<domain.Expense>> getJobExpenses(String jobId);
  Future<domain.Expense> createExpense(domain.Expense expense);
  Future<domain.Expense> updateExpense(String id, domain.Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> attachReceipt(String expenseId, String receiptPath, String? ocrText);
  Future<Map<String, dynamic>> getExpenseStats(String userId, {DateTime? month});
}

/// Expense repository implementation (Offline-First)
class ExpenseRepository implements IExpenseRepository {
  final localdb.AppDatabase _db;

  ExpenseRepository(this._db);

  @override
  Future<List<domain.Expense>> getAllExpenses(String userId) async {
    try {
      final dbExpenses = await _db.expenseDao.getAllExpenses(userId);
      return dbExpenses.map(_convertFromDb).toList();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to fetch expenses',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<domain.Expense>> getJobExpenses(String jobId) async {
    try {
      final dbExpenses = await _db.expenseDao.getJobExpenses(jobId);
      return dbExpenses.map(_convertFromDb).toList();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to fetch job expenses',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<domain.Expense> createExpense(domain.Expense expense) async {
    try {
      final companion = localdb.ExpensesCompanion.insert(
        id: expense.id,
        userId: expense.userId,
        jobId: drift.Value(expense.jobId),
        description: expense.description,
        vendor: drift.Value(expense.vendor),
        category: expense.category.name,
        amount: expense.amount,
        expenseDate: expense.expenseDate,
        receiptPath: drift.Value(expense.receiptPath),
        receiptUrl: drift.Value(expense.receiptUrl),
        ocrText: drift.Value(expense.ocrText),
        taxDeductible: drift.Value(expense.taxDeductible),
        taxCategory: drift.Value(expense.taxCategory),
        paymentMethod: drift.Value(expense.paymentMethod?.name),
        createdAt: drift.Value(expense.createdAt),
        updatedAt: drift.Value(expense.updatedAt),
        synced: drift.Value(expense.synced),
      );

      final dbExpense = await _db.expenseDao.createExpense(companion);

      ErrorHandler.info('Expense created (offline-first)', {'id': dbExpense.id});
      return _convertFromDb(dbExpense);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to create expense',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<domain.Expense> updateExpense(String id, domain.Expense expense) async {
    try {
      final companion = localdb.ExpensesCompanion(
        description: drift.Value(expense.description),
        vendor: drift.Value(expense.vendor),
        category: drift.Value(expense.category.name),
        amount: drift.Value(expense.amount),
        expenseDate: drift.Value(expense.expenseDate),
        receiptPath: drift.Value(expense.receiptPath),
        receiptUrl: drift.Value(expense.receiptUrl),
        ocrText: drift.Value(expense.ocrText),
        taxDeductible: drift.Value(expense.taxDeductible),
        taxCategory: drift.Value(expense.taxCategory),
        paymentMethod: drift.Value(expense.paymentMethod?.name),
      );

      final ok = await _db.expenseDao.updateExpense(id, companion);
      if (!ok) {
        throw DatabaseException(message: 'Expense not found', code: 'NOT_FOUND');
      }

      final dbExpense = await _db.expenseDao.getExpenseById(id);
      if (dbExpense == null) {
        throw DatabaseException(message: 'Expense not found', code: 'NOT_FOUND');
      }

      ErrorHandler.info('Expense updated (offline-first)', {'id': id});
      return _convertFromDb(dbExpense);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to update expense',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _db.expenseDao.deleteExpense(id);
      ErrorHandler.info('Expense deleted (offline-first)', {'id': id});
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to delete expense',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> attachReceipt(
    String expenseId,
    String receiptPath,
    String? ocrText,
  ) async {
    try {
      await _db.expenseDao.attachReceipt(
        expenseId: expenseId,
        receiptPath: receiptPath,
        ocrText: ocrText,
      );
      ErrorHandler.info('Receipt attached to expense', {'expenseId': expenseId});
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to attach receipt',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getExpenseStats(String userId, {DateTime? month}) async {
    try {
      final expenses = await _db.expenseDao.getAllExpenses(userId);
      final targetMonth = month ?? DateTime.now();

      final totalExpenses =
          expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

      final monthlyExpenses = expenses
          .where((e) {
            final localDate = e.expenseDate.toLocal();
            return localDate.year == targetMonth.year && localDate.month == targetMonth.month;
          })
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      final taxDeductibleTotal = expenses
          .where((e) => e.taxDeductible)
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      final Map<String, double> categoryTotals = {};
      final Map<String, double> monthlyCategoryTotals = {};
      for (final e in expenses) {
        final category = domain.ExpenseCategory.values.firstWhere(
          (c) => c.name == e.category,
          orElse: () => domain.ExpenseCategory.other,
        );
        categoryTotals[category.displayName] =
            (categoryTotals[category.displayName] ?? 0.0) + e.amount;

        final localDate = e.expenseDate.toLocal();
        if (localDate.year == targetMonth.year &&
            localDate.month == targetMonth.month) {
          monthlyCategoryTotals[category.displayName] =
              (monthlyCategoryTotals[category.displayName] ?? 0.0) + e.amount;
        }
      }

      return {
        'totalExpenses': totalExpenses,
        'monthlyExpenses': monthlyExpenses,
        'taxDeductibleTotal': taxDeductibleTotal,
        'categoryTotals': categoryTotals,
        'monthlyCategoryTotals': monthlyCategoryTotals,
      };
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to get expense statistics',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Convert database expense to domain model
  domain.Expense _convertFromDb(localdb.Expense dbExpense) {
    return domain.Expense(
      id: dbExpense.id,
      userId: dbExpense.userId,
      jobId: dbExpense.jobId,
      description: dbExpense.description,
      vendor: dbExpense.vendor,
      category: domain.ExpenseCategory.values.firstWhere(
        (c) => c.name == dbExpense.category,
        orElse: () => domain.ExpenseCategory.other,
      ),
      amount: dbExpense.amount,
      expenseDate: dbExpense.expenseDate,
      receiptPath: dbExpense.receiptPath,
      receiptUrl: dbExpense.receiptUrl,
      ocrText: dbExpense.ocrText,
      taxDeductible: dbExpense.taxDeductible,
      taxCategory: dbExpense.taxCategory,
      paymentMethod: dbExpense.paymentMethod != null
          ? domain.PaymentMethod.values.firstWhere(
              (p) => p.name == dbExpense.paymentMethod,
              orElse: () => domain.PaymentMethod.other,
            )
          : null,
      createdAt: dbExpense.createdAt,
      updatedAt: dbExpense.updatedAt,
      synced: dbExpense.synced,
    );
  }
}

/// Provider for Expense repository
final expenseRepositoryProvider = Provider<IExpenseRepository>((ref) {
  final db = ref.watch(localdb.databaseProvider);
  return ExpenseRepository(db);
});
