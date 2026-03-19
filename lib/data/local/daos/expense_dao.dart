import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(AppDatabase db) : super(db);

  Future<List<Expense>> getAllExpenses(String userId) =>
      (select(expenses)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
      .get();

  Future<Expense?> getExpenseById(String id) =>
      (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Expense>> getJobExpenses(String jobId) =>
      (select(expenses)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
      .get();

  Future<List<Expense>> getExpensesByCategory(String userId, String category) =>
      (select(expenses)
        ..where((t) => t.userId.equals(userId) & t.category.equals(category))
        ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
      .get();

  Future<Expense> createExpense(ExpensesCompanion expense) async {
    await into(expenses).insert(expense);
    return await getExpenseById(expense.id.value)
        .then((e) => e ?? (throw Exception('Expense not found after insert')));
  }

  Future<bool> updateExpense(String id, ExpensesCompanion expense) async {
    final updated = await (update(expenses)..where((t) => t.id.equals(id)))
        .write(expense.copyWith(
      updatedAt: Value(DateTime.now()),
      synced: const Value(false),
    ));
    return updated > 0;
  }

  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((t) => t.id.equals(id))).go();

  Future<void> attachReceipt({
    required String expenseId,
    required String receiptPath,
    String? receiptUrl,
    String? ocrText,
  }) =>
      updateExpense(expenseId, ExpensesCompanion(
        receiptPath: Value(receiptPath),
        receiptUrl: Value(receiptUrl),
        ocrText: Value(ocrText),
      ));

  Future<void> markAsSynced(String id) =>
      (update(expenses)..where((t) => t.id.equals(id))).write(
        const ExpensesCompanion(synced: Value(true)),
      );

  Future<List<Expense>> getUnsyncedExpenses() =>
      (select(expenses)..where((t) => t.synced.equals(false))).get();

  Stream<List<Expense>> watchAllExpenses(String userId) =>
      (select(expenses)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
      .watch();

  Stream<Expense?> watchExpenseById(String id) =>
      (select(expenses)..where((t) => t.id.equals(id))).watchSingleOrNull();
}
