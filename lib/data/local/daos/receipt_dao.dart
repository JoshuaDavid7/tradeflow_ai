import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'receipt_dao.g.dart';

@DriftAccessor(tables: [Receipts])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  ReceiptDao(AppDatabase db) : super(db);

  Future<List<Receipt>> getAllReceipts(String userId) =>
      (select(receipts)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<Receipt?> getReceiptById(String id) =>
      (select(receipts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Receipt>> getJobReceipts(String jobId) =>
      (select(receipts)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<Receipt?> getReceiptByExpenseId(String expenseId) =>
      (select(receipts)..where((t) => t.expenseId.equals(expenseId)))
          .getSingleOrNull();

  Future<List<Receipt>> getUnlinkedReceipts(String userId) =>
      (select(receipts)
        ..where((t) =>
            t.userId.equals(userId) &
            t.expenseId.isNull() &
            t.jobId.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<List<Receipt>> getPendingOcrReceipts(String userId) =>
      (select(receipts)
        ..where((t) =>
            t.userId.equals(userId) & t.ocrStatus.equals('pending'))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<Receipt> createReceipt(ReceiptsCompanion receipt) async {
    await into(receipts).insert(receipt);
    return await getReceiptById(receipt.id.value)
        .then((r) => r ?? (throw Exception('Receipt not found after insert')));
  }

  Future<bool> updateReceipt(String id, ReceiptsCompanion receipt) async {
    final updated = await (update(receipts)..where((t) => t.id.equals(id)))
        .write(receipt.copyWith(synced: const Value(false)));
    return updated > 0;
  }

  Future<void> updateOcrResults({
    required String receiptId,
    required String ocrText,
    double? amount,
    String? vendor,
    DateTime? date,
  }) =>
      updateReceipt(receiptId, ReceiptsCompanion(
        ocrText: Value(ocrText),
        extractedAmount: Value(amount),
        extractedVendor: Value(vendor),
        extractedDate: Value(date),
        ocrStatus: const Value('completed'),
      ));

  Future<void> linkToExpense(String receiptId, String expenseId) =>
      updateReceipt(receiptId, ReceiptsCompanion(expenseId: Value(expenseId)));

  Future<void> linkToJob(String receiptId, String jobId) =>
      updateReceipt(receiptId, ReceiptsCompanion(jobId: Value(jobId)));

  Future<int> deleteReceipt(String id) =>
      (delete(receipts)..where((t) => t.id.equals(id))).go();

  Future<void> markAsSynced(String id) =>
      (update(receipts)..where((t) => t.id.equals(id))).write(
        const ReceiptsCompanion(synced: Value(true)),
      );

  Future<List<Receipt>> getUnsyncedReceipts() =>
      (select(receipts)..where((t) => t.synced.equals(false))).get();

  Stream<List<Receipt>> watchAllReceipts(String userId) =>
      (select(receipts)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
}
