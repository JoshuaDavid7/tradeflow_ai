import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/database.dart';
import '../local/tables/tables.dart';

/// A potential expense match for an unlinked recognized material cost.
class PotentialMatch {
  final String expenseId;
  final String expenseDescription;
  final double expenseAmount;
  final double score; // 0-100
  const PotentialMatch({
    required this.expenseId,
    required this.expenseDescription,
    required this.expenseAmount,
    required this.score,
  });
}

/// Repository for canonical material-cost accounting.
///
/// Each real material cost is represented once. Analytics sums
/// [canonicalCost] on active records, preventing double-counting between
/// invoice materials and expense rows.
class MaterialCostRepository {
  final AppDatabase _db;
  MaterialCostRepository(this._db);

  // ── Recognition ────────────────────────────────────────────────────────────

  /// Create recognized material costs for each material line on a sent
  /// invoice.  Called exactly once when a non-quote invoice transitions
  /// to 'sent'.
  ///
  /// [materials] is the raw JSON list from `jobData['materials']`.
  /// Each item may have `originalCost` (pre-markup cost basis) and/or
  /// `cost` (billed amount).  We use `originalCost ?? cost` as the
  /// provisional cost basis.
  Future<void> recognizeMaterialCosts(
    String userId,
    String jobId,
    List<dynamic> materials,
    DateTime recognitionDate,
  ) async {
    for (int i = 0; i < materials.length; i++) {
      final m = materials[i];
      if (m is! Map) continue;
      final description = m['item']?.toString() ?? 'Material';
      final materialId = m['id']?.toString();
      final cost = (m['cost'] as num?)?.toDouble() ?? 0.0;
      final originalCost = (m['originalCost'] as num?)?.toDouble();
      final provisionalCost = originalCost ?? cost;
      if (provisionalCost <= 0) continue; // Skip zero-cost items

      final companion = RecognizedMaterialCostsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        jobId: Value(jobId),
        materialIndex: Value(i),
        description: description,
        provisionalCost: provisionalCost,
        canonicalCost: provisionalCost,
        recognitionDate: recognitionDate,
      );
      await _db.materialCostDao.insertCost(
        companion.copyWith(materialId: Value(materialId)),
      );
    }
  }

  /// Mark all active recognized costs for a job as superseded.
  /// Called when a revision replaces the original invoice.
  Future<void> supersedeCostsForJob(String jobId) =>
      _db.materialCostDao.supersedeCostsForJob(jobId);

  // ── Linking ────────────────────────────────────────────────────────────────

  /// Link an expense to a recognized material cost.
  /// Updates the canonical cost to the allocated amount and marks the
  /// source as 'both'.
  Future<void> linkExpenseToCost(
      String costId, String expenseId, double allocatedAmount) async {
    await _db.materialCostDao.insertLink(
      MaterialCostLinksCompanion.insert(
        id: const Uuid().v4(),
        recognizedMaterialCostId: costId,
        expenseId: expenseId,
        allocatedAmount: allocatedAmount,
      ),
    );
    await _db.materialCostDao.updateCost(
      costId,
      RecognizedMaterialCostsCompanion(
        canonicalCost: Value(allocatedAmount),
        source: const Value('both'),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  // ── Analytics queries ──────────────────────────────────────────────────────

  /// Returns the set of all expense IDs that are linked to any active
  /// recognized material cost.  These must be excluded from
  /// operating-expenses to prevent double-counting.
  Future<Set<String>> getLinkedExpenseIds(String userId) =>
      _db.materialCostDao.getLinkedExpenseIds(userId);

  /// Total canonical cost for all active recognized material costs.
  Future<double> getTotalActiveMaterialCosts(String userId,
          {DateTime? month}) =>
      _db.materialCostDao.totalActiveCosts(userId, month: month);

  /// Active recognized costs for a specific job.
  Future<List<RecognizedMaterialCost>> getCostsForJob(String jobId) =>
      _db.materialCostDao.getByJob(jobId);

  // ── Backfill ───────────────────────────────────────────────────────────────

  /// Backfill recognized material costs for existing sent invoices that
  /// were sent before the cost-recognition system was implemented.
  /// Safe to call multiple times — skips jobs that already have costs.
  Future<int> backfillForUser(String userId) async {
    int count = 0;
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('jobs')
          .select('id, materials, created_at, status, type')
          .eq('user_id', userId)
          .eq('status', 'sent');

      for (final row in rows) {
        final jobId = row['id']?.toString() ?? '';
        final type = row['type']?.toString().toLowerCase() ?? '';
        if (jobId.isEmpty || type == 'quote') continue;

        // Skip if this job already has recognized costs
        final existing = await _db.materialCostDao.getByJob(jobId);
        if (existing.isNotEmpty) continue;

        final materials = row['materials'] as List? ?? [];
        if (materials.isEmpty) continue;

        final createdAt = DateTime.tryParse(
                row['created_at']?.toString() ?? '') ??
            DateTime.now();
        await recognizeMaterialCosts(userId, jobId, materials, createdAt);
        count += materials.length;
      }
    } catch (e) {
      debugPrint('Material cost backfill error: $e');
    }
    return count;
  }

  // ── Duplicate suggestion ───────────────────────────────────────────────────

  /// Find expenses that are potential matches for an unlinked recognized
  /// material cost. Uses safe heuristics: same job, category=materials,
  /// amount within 30%, date within 60 days, name similarity.
  Future<List<PotentialMatch>> findPotentialMatches(
    RecognizedMaterialCost cost,
    List<dynamic> expenses,
  ) async {
    final linkedIds = await _db.materialCostDao.getLinkedExpenseIds(cost.userId);
    final links = await _db.materialCostDao.getLinksForCost(cost.id);
    if (links.isNotEmpty) return []; // Already linked

    final matches = <PotentialMatch>[];
    for (final e in expenses) {
      if (e is! Map && e.runtimeType.toString() != 'Expense') continue;

      final expId = (e is Map ? e['id'] : (e as dynamic).id)?.toString() ?? '';
      if (linkedIds.contains(expId)) continue; // Already linked elsewhere

      final category =
          (e is Map ? e['category'] : (e as dynamic).category)?.toString() ?? '';
      if (category != 'materials') continue;

      final amount =
          (e is Map ? (e['amount'] as num?)?.toDouble() : (e as dynamic).amount as double?) ?? 0.0;
      final description =
          (e is Map ? e['description'] : (e as dynamic).description)?.toString() ?? '';
      final expDate = e is Map
          ? DateTime.tryParse(e['expense_date']?.toString() ?? '')
          : (e as dynamic).expenseDate as DateTime?;

      double score = 0;

      // Amount similarity: within 30%
      if (cost.provisionalCost > 0 && amount > 0) {
        final ratio = amount / cost.provisionalCost;
        if (ratio >= 0.7 && ratio <= 1.3) {
          score += 40 * (1.0 - (ratio - 1.0).abs());
        }
      }

      // Name similarity
      final costName = cost.description.toLowerCase().trim();
      final expName = description.toLowerCase().trim();
      if (costName.isNotEmpty && expName.isNotEmpty) {
        if (costName == expName) {
          score += 30;
        } else if (costName.contains(expName) || expName.contains(costName)) {
          score += 20;
        }
      }

      // Date proximity (within 60 days)
      if (expDate != null) {
        final daysDiff =
            cost.recognitionDate.difference(expDate).inDays.abs();
        if (daysDiff <= 60) {
          score += 20 * (1.0 - daysDiff / 60);
        }
      }

      // Same job
      if (cost.jobId != null) {
        final expJobId =
            (e is Map ? e['job_id'] : (e as dynamic).jobId)?.toString();
        if (expJobId == cost.jobId) score += 10;
      }

      if (score >= 25) {
        matches.add(PotentialMatch(
          expenseId: expId,
          expenseDescription: description,
          expenseAmount: amount,
          score: score,
        ));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(5).toList();
  }
}

/// Riverpod provider for the material cost repository.
final materialCostRepositoryProvider = Provider<MaterialCostRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MaterialCostRepository(db);
});
