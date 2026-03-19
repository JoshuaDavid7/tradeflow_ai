import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'job_dao.g.dart';

@DriftAccessor(tables: [Jobs, Payments])
class JobDao extends DatabaseAccessor<AppDatabase> with _$JobDaoMixin {
  JobDao(AppDatabase db) : super(db);

  Future<List<Job>> getAllJobs(String userId) =>
      (select(jobs)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<Job?> getJobById(String id) =>
      (select(jobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Job>> getJobsByStatus(String userId, String status) =>
      (select(jobs)
        ..where((t) => t.userId.equals(userId) & t.status.equals(status))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<Job> createJob(JobsCompanion job) async {
    await into(jobs).insert(job);
    return await getJobById(job.id.value)
        .then((j) => j ?? (throw Exception('Job not found after insert')));
  }

  Future<bool> updateJob(String id, JobsCompanion job) async {
    final updated = await (update(jobs)..where((t) => t.id.equals(id)))
        .write(job.copyWith(
      updatedAt: Value(DateTime.now()),
      synced: const Value(false),
    ));
    return updated > 0;
  }

  Future<int> deleteJob(String id) =>
      (delete(jobs)..where((t) => t.id.equals(id))).go();

  Future<void> recordPayment({
    required String jobId,
    required double amount,
    required String method,
    String? reference,
    String? notes,
    DateTime? receivedAt,
  }) async {
    final job = await getJobById(jobId);
    if (job == null) throw Exception('Job not found');

    final effectiveDate = receivedAt ?? DateTime.now();

    await into(payments).insert(PaymentsCompanion.insert(
      id: const Uuid().v4(),
      jobId: jobId,
      userId: job.userId,
      amount: amount,
      method: method,
      reference: Value(reference),
      notes: Value(notes),
      receivedAt: effectiveDate,
    ));

    final newPaid = job.amountPaid + amount;
    final newDue = job.total - newPaid;

    // Document state (status) is never mutated by payments.
    await updateJob(jobId, JobsCompanion(
      amountPaid: Value(newPaid),
      amountDue: Value(newDue),
      paidAt: newDue <= 0.01 ? Value(effectiveDate) : const Value.absent(),
    ));
  }

  Future<List<Payment>> getJobPayments(String jobId) =>
      (select(payments)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
      .get();

  /// Get all payments for a user, ordered by receivedAt descending.
  Future<List<Payment>> getUserPayments(String userId) =>
      (select(payments)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
      .get();

  /// Insert a payment record into the local payments table **without**
  /// mutating the associated job row (amountPaid, amountDue, status).
  ///
  /// Use this when the job state has already been updated elsewhere
  /// (e.g. on Supabase) and you only need a local payment record for
  /// analytics / Collected tracking.
  Future<void> insertPaymentRecord({
    required String jobId,
    required String userId,
    required double amount,
    required String method,
    String? reference,
    String? notes,
    DateTime? receivedAt,
  }) async {
    await into(payments).insert(PaymentsCompanion.insert(
      id: const Uuid().v4(),
      jobId: jobId,
      userId: userId,
      amount: amount,
      method: method,
      reference: Value(reference),
      notes: Value(notes),
      receivedAt: receivedAt ?? DateTime.now(),
    ));
  }

  /// Delete all auto-reconciled payment records for a user.
  ///
  /// Called before reconciliation so that stale records (e.g. with wrong
  /// receivedAt dates) are replaced with freshly-computed ones.
  Future<int> deleteAutoReconciledPayments(String userId) =>
      (delete(payments)
            ..where((t) =>
                t.userId.equals(userId) &
                t.reference.equals('auto-reconciled')))
          .go();

  Future<void> markAsSynced(String id) =>
      (update(jobs)..where((t) => t.id.equals(id))).write(
        JobsCompanion(
          synced: const Value(true),
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ),
      );

  Future<List<Job>> getUnsyncedJobs() =>
      (select(jobs)..where((t) => t.synced.equals(false))).get();

  Stream<List<Job>> watchAllJobs(String userId) =>
      (select(jobs)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<Job?> watchJobById(String id) =>
      (select(jobs)..where((t) => t.id.equals(id))).watchSingleOrNull();
}
