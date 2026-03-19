import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'material_cost_dao.g.dart';

@DriftAccessor(tables: [RecognizedMaterialCosts, MaterialCostLinks])
class MaterialCostDao extends DatabaseAccessor<AppDatabase>
    with _$MaterialCostDaoMixin {
  MaterialCostDao(super.db);

  // ── RecognizedMaterialCosts ────────────────────────────────────────────────

  Future<List<RecognizedMaterialCost>> getActiveByUser(String userId) =>
      (select(recognizedMaterialCosts)
            ..where((t) =>
                t.userId.equals(userId) & t.status.equals('active')))
          .get();

  Future<List<RecognizedMaterialCost>> getByJob(String jobId) =>
      (select(recognizedMaterialCosts)
            ..where((t) => t.jobId.equals(jobId) & t.status.equals('active')))
          .get();

  Future<void> insertCost(RecognizedMaterialCostsCompanion cost) =>
      into(recognizedMaterialCosts).insert(cost);

  Future<bool> updateCost(
      String id, RecognizedMaterialCostsCompanion companion) =>
      (update(recognizedMaterialCosts)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Mark all active recognized costs for a job as superseded.
  Future<void> supersedeCostsForJob(String jobId) =>
      (update(recognizedMaterialCosts)
            ..where(
                (t) => t.jobId.equals(jobId) & t.status.equals('active')))
          .write(RecognizedMaterialCostsCompanion(
        status: const Value('superseded'),
        updatedAt: Value(DateTime.now()),
      ));

  /// Sum of canonical_cost for active costs, optionally filtered by month.
  Future<double> totalActiveCosts(String userId, {DateTime? month}) async {
    final costs = await getActiveByUser(userId);
    if (month == null) {
      return costs.fold<double>(0.0, (sum, c) => sum + c.canonicalCost);
    }
    return costs
        .where((c) {
          final d = c.recognitionDate.toLocal();
          return d.year == month.year && d.month == month.month;
        })
        .fold<double>(0.0, (sum, c) => sum + c.canonicalCost);
  }

  Future<List<RecognizedMaterialCost>> getUnsyncedCosts() =>
      (select(recognizedMaterialCosts)
            ..where((t) => t.synced.equals(false)))
          .get();

  Future<void> markCostSynced(String id) =>
      (update(recognizedMaterialCosts)..where((t) => t.id.equals(id)))
          .write(const RecognizedMaterialCostsCompanion(
              synced: Value(true)));

  // ── MaterialCostLinks ──────────────────────────────────────────────────────

  Future<List<MaterialCostLink>> getLinksForCost(String costId) =>
      (select(materialCostLinks)
            ..where((t) => t.recognizedMaterialCostId.equals(costId)))
          .get();

  Future<List<MaterialCostLink>> getLinksForExpense(String expenseId) =>
      (select(materialCostLinks)
            ..where((t) => t.expenseId.equals(expenseId)))
          .get();

  /// Returns the set of all expense IDs that are linked to any active
  /// recognized material cost. These expenses must be excluded from
  /// the operating-expenses sum to avoid double counting.
  Future<Set<String>> getLinkedExpenseIds(String userId) async {
    final activeCosts = await getActiveByUser(userId);
    if (activeCosts.isEmpty) return {};

    final costIds = activeCosts.map((c) => c.id).toSet();
    final allLinks = await select(materialCostLinks).get();
    return allLinks
        .where((l) => costIds.contains(l.recognizedMaterialCostId))
        .map((l) => l.expenseId)
        .toSet();
  }

  Future<void> insertLink(MaterialCostLinksCompanion link) =>
      into(materialCostLinks).insert(link);

  Future<void> deleteLinksForCost(String costId) =>
      (delete(materialCostLinks)
            ..where((t) => t.recognizedMaterialCostId.equals(costId)))
          .go();

  Future<List<MaterialCostLink>> getUnsyncedLinks() async {
    // Links don't have a synced column — they're synced via parent.
    // Return all for now; sync logic can filter as needed.
    return select(materialCostLinks).get();
  }
}
