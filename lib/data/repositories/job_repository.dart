import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/job.dart' as domain;
import '../local/database.dart' as localdb;
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import 'package:drift/drift.dart' as drift;

/// Job repository interface
abstract class IJobRepository {
  Future<List<domain.Job>> getJobs(String userId);
  Future<List<domain.Job>> getJobsByStatus(
      String userId, domain.JobStatus status);
  Future<domain.Job> getJob(String id);
  Future<domain.Job> createJob(domain.Job job);
  Future<domain.Job> updateJob(String id, domain.Job job);
  Future<void> deleteJob(String id);
  Future<Map<String, dynamic>> getJobStats(String userId, {DateTime? month});
  Future<void> recordPayment(String jobId, double amount, String method, {
    DateTime? receivedAt,
    String? reference,
    String? notes,
  });
  Future<void> updateJobStatus(String jobId, String newStatus);
  Future<Map<DateTime, double>> getMonthlyCollectedForMonths(
      String userId, List<DateTime> months);
}

/// Job repository implementation (Offline-First)
class JobRepository implements IJobRepository {
  final localdb.AppDatabase _db;
  final SupabaseClient _supabase;

  /// Guard against concurrent reconciliation calls. When two callers (e.g.
  /// jobStatsProvider + analyticsProvider) both trigger getJobStats at the same
  /// time, only the first one actually runs the delete-and-rebuild cycle; the
  /// second awaits the same Future, preventing the race condition where one
  /// caller's DELETE wipes out the other's freshly-INSERTed records.
  Completer<void>? _reconciliationGuard;

  JobRepository(this._db) : _supabase = Supabase.instance.client;

  @override
  Future<List<domain.Job>> getJobs(String userId) async {
    try {
      final rows = await _supabase
          .from('jobs')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows)
          .map(_convertFromRemote)
          .toList();
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote jobs fetch failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        final dbJobs = await _db.jobDao.getAllJobs(userId);
        return dbJobs.map(_convertFromDb).toList();
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to fetch jobs',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<List<domain.Job>> getJobsByStatus(
      String userId, domain.JobStatus status) async {
    try {
      final jobs = await getJobs(userId);
      return jobs.where((job) => job.status == status).toList();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to fetch jobs by status',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<domain.Job> getJob(String id) async {
    try {
      final row =
          await _supabase.from('jobs').select('*').eq('id', id).maybeSingle();
      if (row != null) {
        return _convertFromRemote(Map<String, dynamic>.from(row));
      }
      final dbJob = await _db.jobDao.getJobById(id);
      if (dbJob != null) {
        return _convertFromDb(dbJob);
      }
      throw DatabaseException(
        message: 'Job not found',
        code: 'NOT_FOUND',
      );
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<domain.Job> createJob(domain.Job job) async {
    try {
      final payload = {
        'id': job.id,
        'user_id': job.userId,
        'customer_id': job.customerId,
        'client_name': job.clientName,
        'title': job.title,
        'description': job.description,
        'trade': job.trade,
        'status': job.status.name,
        'type': job.type.name,
        'labor_hours': job.laborHours,
        'hourly_rate_at_time': job.hourlyRateAtTime,
        'materials': job.materials.map((m) => m.toJson()).toList(),
        'tax_rate_at_time': job.taxRateAtTime,
        'total_amount': job.totalAmount,
        'due_date': job.dueDate?.toIso8601String(),
        'paid_at': job.paidAt?.toIso8601String(),
      };
      final inserted =
          await _supabase.from('jobs').insert(payload).select('*').single();
      ErrorHandler.info('Job created (remote)', {'id': inserted['id']});
      return _convertFromRemote(Map<String, dynamic>.from(inserted));
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote job create failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        final companion = localdb.JobsCompanion.insert(
          id: job.id,
          userId: job.userId,
          customerId: drift.Value(job.customerId),
          title: job.title,
          clientName: job.clientName,
          description: drift.Value(job.description),
          trade: drift.Value(job.trade),
          status: job.status.name,
          type: job.type.name,
          laborHours: drift.Value(job.laborHours),
          laborRate: job.hourlyRateAtTime,
          materialsJson: drift.Value(_serializeMaterials(job.materials)),
          subtotal: job.subtotal,
          taxRate: drift.Value(job.taxRateAtTime),
          taxAmount: job.taxAmount,
          total: job.totalAmount,
          amountDue: job.amountDue,
          dueDate: drift.Value(job.dueDate),
          paidAt: drift.Value(job.paidAt),
          createdAt: drift.Value(job.createdAt),
          updatedAt: drift.Value(job.createdAt),
        );

        final dbJob = await _db.jobDao.createJob(companion);

        ErrorHandler.info('Job created (offline-first)', {'id': dbJob.id});
        return _convertFromDb(dbJob);
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to create job',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<domain.Job> updateJob(String id, domain.Job job) async {
    try {
      final payload = {
        'customer_id': job.customerId,
        'client_name': job.clientName,
        'title': job.title,
        'description': job.description,
        'trade': job.trade,
        'status': job.status.name,
        'type': job.type.name,
        'labor_hours': job.laborHours,
        'hourly_rate_at_time': job.hourlyRateAtTime,
        'materials': job.materials.map((m) => m.toJson()).toList(),
        'tax_rate_at_time': job.taxRateAtTime,
        'total_amount': job.totalAmount,
        'due_date': job.dueDate?.toIso8601String(),
        'paid_at': job.paidAt?.toIso8601String(),
      };
      final updated = await _supabase
          .from('jobs')
          .update(payload)
          .eq('id', id)
          .eq('user_id', job.userId)
          .select('*')
          .maybeSingle();
      if (updated != null) {
        ErrorHandler.info('Job updated (remote)', {'id': id});
        return _convertFromRemote(Map<String, dynamic>.from(updated));
      }
      throw DatabaseException(message: 'Job not found', code: 'NOT_FOUND');
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote job update failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        final companion = localdb.JobsCompanion(
          title: drift.Value(job.title),
          clientName: drift.Value(job.clientName),
          description: drift.Value(job.description),
          status: drift.Value(job.status.name),
          laborHours: drift.Value(job.laborHours),
          laborRate: drift.Value(job.hourlyRateAtTime),
          materialsJson: drift.Value(_serializeMaterials(job.materials)),
          subtotal: drift.Value(job.subtotal),
          taxRate: drift.Value(job.taxRateAtTime),
          taxAmount: drift.Value(job.taxAmount),
          total: drift.Value(job.totalAmount),
          amountDue: drift.Value(job.totalAmount - job.amountPaid),
          amountPaid: drift.Value(job.amountPaid),
          dueDate: drift.Value(job.dueDate),
          paidAt: drift.Value(job.paidAt),
        );

        final ok = await _db.jobDao.updateJob(id, companion);
        if (!ok) {
          throw DatabaseException(message: 'Job not found', code: 'NOT_FOUND');
        }
        final dbJob = await _db.jobDao.getJobById(id);
        if (dbJob == null) {
          throw DatabaseException(
              message: 'Job not found after update', code: 'NOT_FOUND');
        }
        ErrorHandler.info('Job updated (offline-first)', {'id': id});
        return _convertFromDb(dbJob);
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to update job',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<void> deleteJob(String id) async {
    try {
      await _supabase.from('jobs').delete().eq('id', id);
      ErrorHandler.info('Job deleted (remote)', {'id': id});
      return;
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote job delete failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        await _db.jobDao.deleteJob(id);
        ErrorHandler.info('Job deleted (offline-first)', {'id': id});
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to delete job',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getJobStats(String userId, {DateTime? month}) async {
    try {
      final rows =
          await _supabase.from('jobs').select('*').eq('user_id', userId);
      final targetMonth = month ?? DateTime.now();
      double totalBilled = 0.0;
      double totalRevenue = 0.0;
      double outstandingRevenue = 0.0;
      int paidJobsCount = 0;
      int activeJobsCount = 0;
      int outstandingInvoiceCount = 0;
      int draftCount = 0;
      int sentUnpaidCount = 0;
      int cancelledCount = 0;

      int totalPaymentDays = 0;
      int paymentDaysCount = 0;

      final remoteRows = List<Map<String, dynamic>>.from(rows);
      for (final row in remoteRows) {
        final type = (row['type']?.toString().toLowerCase() ?? 'invoice');
        final status = _resolveStatusFromRemote(row);
        final isCancelled = status == domain.JobStatus.cancelled;
        final isDraft = status == domain.JobStatus.draft;
        final isQuote = type == domain.JobType.quote.name;
        final total = _asDouble(row['total_amount']);
        final amountPaid = _asDouble(row['amount_paid']);
        final rawDue = _asDouble(row['amount_due']);
        // Normalize amount_due: if DB has 0/NULL but amountPaid < total,
        // compute the actual remaining balance.
        final amountDue = rawDue > 0
            ? rawDue
            : (amountPaid >= total - 0.01 && total > 0)
                ? 0.0
                : total - amountPaid;
        final createdAt = _parseDate(row['created_at']);
        final paidAt = _parseDate(row['payment_paid_at']) ??
            _parseDate(row['paid_at']);

        // Payment state is derived from amounts, not from status column.
        // Guard: amountPaid must be positive — a NULL/0 amount_due with no
        // payments recorded does NOT mean "fully paid".
        final isFullyPaid = total > 0 && amountPaid > 0.01 &&
            (amountDue <= 0.01 || amountPaid >= total - 0.01);

        if (isFullyPaid && !isQuote) {
          paidJobsCount += 1;
          totalRevenue += total;
          // Calculate days from creation to payment
          if (paidAt != null && createdAt != null) {
            totalPaymentDays += paidAt.difference(createdAt).inDays;
            paymentDaysCount += 1;
          }
        }
        if (!isCancelled && !isDraft) {
          activeJobsCount += 1;
        }

        // Non-overlapping status counters
        if (isDraft) {
          draftCount += 1;
        } else if (isCancelled) {
          cancelledCount += 1;
        } else if (isFullyPaid) {
          // sent + fully paid (already counted in paidJobsCount for invoices)
        } else {
          sentUnpaidCount += 1; // sent but not fully paid (includes partial)
        }

        if (!isQuote) {
          totalBilled += total;

          // Awaiting payment: sent invoices with remaining balance.
          // Exclude: drafts, quotes, cancelled, fully-paid.
          if (!isFullyPaid && !isCancelled && !isDraft) {
            final effectiveDue = amountDue > 0 ? amountDue : total;
            outstandingRevenue += effectiveDue;
            outstandingInvoiceCount += 1;
          }
        }
      }

      // Reconcile Stripe-paid (or externally-marked-paid) jobs into local
      // payment records so that _getMonthlyCollected() can count them.
      await _reconcileStripePaidJobs(userId, remoteRows);

      // Collected: sum actual payment records from local Drift payments table
      // by receivedAt date in the target month. This handles partial payments
      // correctly — each payment is counted in the month it was received.
      final monthlyRevenue = await _getMonthlyCollected(userId, targetMonth);

      final totalJobs = remoteRows.length;
      final averagePaymentDays = paymentDaysCount > 0
          ? (totalPaymentDays / paymentDaysCount)
          : 0.0;

      return {
        'totalJobs': totalJobs,
        // Prefer these newer, UI-friendly keys.
        'activeJobsCount': activeJobsCount,
        'paidJobsCount': paidJobsCount,
        'totalRevenue': totalRevenue,
        'outstandingRevenue': outstandingRevenue,
        'outstandingInvoiceCount': outstandingInvoiceCount,
        'draftCount': draftCount,
        'sentUnpaidCount': sentUnpaidCount,
        'cancelledCount': cancelledCount,
        'monthlyRevenue': monthlyRevenue,
        'averagePaymentDays': averagePaymentDays,

        // Keep legacy keys around to avoid breaking older screens.
        'activeJobs': activeJobsCount,
        'paidJobs': paidJobsCount,
        'totalBilled': totalBilled,
        'totalPaid': totalRevenue,
        'totalDue': outstandingRevenue,
      };
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote job stats failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        final jobs = await _db.jobDao.getAllJobs(userId);
        final totalJobs = jobs.length;
        final activeJobsCount = jobs
            .where((j) => j.status != 'cancelled' && j.status != 'draft')
            .length;
        final paidJobsCount = jobs
            .where((j) => j.total > 0 && j.amountDue <= 0.01)
            .length;
        final totalBilled = jobs.fold<double>(0.0, (sum, j) => sum + j.total);
        final totalPaid =
            jobs.fold<double>(0.0, (sum, j) => sum + j.amountPaid);
        final outstandingRevenue =
            jobs.fold<double>(0.0, (sum, j) => sum + j.amountDue);

        // Collected from local payments table
        final targetMonth = month ?? DateTime.now();
        final monthlyRevenue = await _getMonthlyCollected(userId, targetMonth);

        return {
          'totalJobs': totalJobs,
          'activeJobsCount': activeJobsCount,
          'paidJobsCount': paidJobsCount,
          'totalRevenue': totalPaid,
          'outstandingRevenue': outstandingRevenue,
          'outstandingInvoiceCount': 0,
          'monthlyRevenue': monthlyRevenue,
          'activeJobs': activeJobsCount,
          'paidJobs': paidJobsCount,
          'totalBilled': totalBilled,
          'totalPaid': totalPaid,
          'totalDue': outstandingRevenue,
        };
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to get job statistics',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Sum actual payment records from the local Drift payments table
  /// where receivedAt falls in the given month.
  ///
  /// This is the source of truth for "Collected" — each partial payment
  /// is counted in the month it was received, not when the invoice was
  /// fully paid.
  Future<double> _getMonthlyCollected(String userId, DateTime targetMonth) async {
    try {
      final allPayments = await _db.jobDao.getUserPayments(userId);
      return allPayments
          .where((p) {
            final receivedLocal = p.receivedAt.toLocal();
            return receivedLocal.year == targetMonth.year &&
                receivedLocal.month == targetMonth.month;
          })
          .fold<double>(0.0, (sum, p) => sum + p.amount);
    } catch (error, _) {
      ErrorHandler.warning('Failed to query local payments for Collected', {
        'error': error.toString(),
      });
      return 0.0;
    }
  }

  /// Returns cash collected per month for a list of [months].
  /// Uses actual Payment records grouped by receivedAt — handles partial
  /// payments correctly (each payment counted in the month it was received).
  Future<Map<DateTime, double>> getMonthlyCollectedForMonths(
      String userId, List<DateTime> months) async {
    final result = <DateTime, double>{};
    try {
      final allPayments = await _db.jobDao.getUserPayments(userId);
      for (final month in months) {
        result[month] = allPayments
            .where((p) {
              final d = p.receivedAt.toLocal();
              return d.year == month.year && d.month == month.month;
            })
            .fold<double>(0.0, (sum, p) => sum + p.amount);
      }
    } catch (error, _) {
      ErrorHandler.warning('Failed to query monthly collected', {
        'error': error.toString(),
      });
      for (final month in months) {
        result.putIfAbsent(month, () => 0.0);
      }
    }
    return result;
  }

  /// Reconcile Stripe-paid (or externally-marked-paid) jobs: for each job
  /// that Supabase considers "paid" (via payment_status or paid_at), ensure a
  /// local payment record exists so that _getMonthlyCollected() can count it.
  ///
  /// Auto-reconciled records are cleared and re-created on every call so that
  /// date corrections propagate immediately. Records created by real user
  /// actions (via recordPayment / Mark Paid) are never touched.
  Future<void> _reconcileStripePaidJobs(
    String userId,
    List<Map<String, dynamic>> remoteRows,
  ) async {
    // If another caller is already running reconciliation, wait for it to
    // finish and then return — the records are already up-to-date.
    if (_reconciliationGuard != null) {
      await _reconciliationGuard!.future;
      return;
    }

    _reconciliationGuard = Completer<void>();
    try {
      // Clear stale auto-reconciled records first. They will be re-created
      // below with the correct receivedAt dates. Real payment records
      // (from recordPayment / Mark Paid) have reference != 'auto-reconciled'
      // and are left untouched.
      await _db.jobDao.deleteAutoReconciledPayments(userId);

      for (final row in remoteRows) {
        // Reconcile jobs that are fully paid (by amount or payment_status).
        final total = _asDouble(row['total_amount']);
        final amtPaid = _asDouble(row['amount_paid']);
        final ps = row['payment_status']?.toString().toLowerCase() ?? '';
        final isFullyPaid =
            (total > 0 && amtPaid > 0.01 && amtPaid >= total - 0.01)
            || ps == 'paid' || ps == 'succeeded';
        if (!isFullyPaid) continue;

        final jobId = row['id']?.toString() ?? '';
        if (jobId.isEmpty) continue;

        // Skip if this job already has a real (non-reconciled) payment record
        // — e.g. the user clicked "Mark Paid" which calls recordPayment().
        final existingPayments = await _db.jobDao.getJobPayments(jobId);
        if (existingPayments.isNotEmpty) continue;

        // No local payment record — create one for the full amount
        if (total <= 0) continue; // Skip zero-amount jobs

        // Best available date for when the payment was received:
        // 1. payment_paid_at — set by Stripe webhook or recordPayment
        // 2. paid_at — set by recordPayment (after Supabase migration)
        // 3. created_at — rough proxy: when the invoice was created
        // (We never use DateTime.now() — that would dump all historical
        // payments into the current month.)
        final paidAt = _parseDate(row['payment_paid_at']) ??
            _parseDate(row['paid_at']) ??
            _parseDate(row['created_at']) ??
            DateTime.now();

        // Determine payment method from Supabase fields
        final paymentProvider = row['payment_provider']?.toString();
        final method = paymentProvider ?? 'reconciled';

        await _db.jobDao.insertPaymentRecord(
          jobId: jobId,
          userId: userId,
          amount: total,
          method: method,
          reference: 'auto-reconciled',
          receivedAt: paidAt,
        );

        ErrorHandler.info('Reconciled paid job into local payments', {
          'jobId': jobId,
          'amount': total,
          'paidAt': paidAt.toIso8601String(),
        });
      }
    } catch (error, _) {
      // Non-critical: reconciliation is best-effort.
      ErrorHandler.warning('Failed to reconcile paid jobs', {
        'error': error.toString(),
      });
    } finally {
      _reconciliationGuard!.complete();
      _reconciliationGuard = null;
    }
  }

  @override
  Future<void> recordPayment(
    String jobId,
    double amount,
    String method, {
    DateTime? receivedAt,
    String? reference,
    String? notes,
  }) async {
    try {
      final now = receivedAt ?? DateTime.now();

      // 1. Fetch current financial state from Supabase
      final jobRow = await _supabase
          .from('jobs')
          .select('user_id, total_amount, amount_paid, amount_due, status')
          .eq('id', jobId)
          .maybeSingle();

      if (jobRow == null) {
        throw DatabaseException(message: 'Job not found on remote', code: 'NOT_FOUND');
      }

      final userId = jobRow['user_id']?.toString() ?? '';
      final totalAmount = _asDouble(jobRow['total_amount']);
      final currentPaid = _asDouble(jobRow['amount_paid']);

      // 2. Compute new totals
      final newPaid = currentPaid + amount;
      final newDue = totalAmount - newPaid;
      final isFullyPaid = newDue <= 0.01;

      // 3. Build the update payload.
      //    Document state (status column) is NEVER mutated by payments.
      //    Payment state is tracked via amount_paid/amount_due/payment_status.
      final updatePayload = <String, dynamic>{
        'amount_paid': newPaid,
        'amount_due': isFullyPaid ? 0.0 : newDue,
      };

      if (isFullyPaid) {
        // Payment tracking fields only — document state stays as-is (e.g. 'sent')
        updatePayload['payment_status'] = 'paid';
        updatePayload['paid_at'] = now.toIso8601String();
        updatePayload['payment_paid_at'] = now.toIso8601String();
      }

      await _supabase.from('jobs').update(updatePayload).eq('id', jobId);

      // 4. Persist local payment record for Collected tracking.
      //    Uses insertPaymentRecord — insert-only, no local job mutation —
      //    because the job state was already updated on Supabase above.
      if (userId.isNotEmpty) {
        await _db.jobDao.insertPaymentRecord(
          jobId: jobId,
          userId: userId,
          amount: amount,
          method: method,
          reference: reference,
          notes: notes,
          receivedAt: now,
        );
      }

      ErrorHandler.info('Payment recorded (remote + local ledger)', {
        'jobId': jobId,
        'amount': amount,
        'method': method,
        'newPaid': newPaid,
        'newDue': isFullyPaid ? 0.0 : newDue,
        'fullyPaid': isFullyPaid,
      });
      return;
    } catch (error, stackTrace) {
      ErrorHandler.warning(
          'Remote payment update failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        // Local fallback: JobDao.recordPayment inserts the payment record
        // AND mutates the local job row (amountPaid, amountDue, status).
        // It already handles partial payments correctly — only sets
        // status='paid' when newDue <= 0.01.
        await _db.jobDao.recordPayment(
          jobId: jobId,
          amount: amount,
          method: method,
          reference: reference,
          notes: notes,
          receivedAt: receivedAt,
        );
        ErrorHandler.info('Payment recorded (offline-first)', {
          'jobId': jobId,
          'amount': amount,
          'method': method,
        });
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to record payment',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<void> updateJobStatus(String jobId, String newStatus) async {
    try {
      await _supabase
          .from('jobs')
          .update({'status': newStatus})
          .eq('id', jobId);
      ErrorHandler.info('Job status updated (remote)', {
        'id': jobId,
        'status': newStatus,
      });
    } catch (error, stackTrace) {
      ErrorHandler.warning('Remote status update failed, using local fallback', {
        'error': error.toString(),
      });
      try {
        await _db.jobDao.updateJob(
          jobId,
          localdb.JobsCompanion(status: drift.Value(newStatus)),
        );
        ErrorHandler.info('Job status updated (offline-first)', {
          'id': jobId,
          'status': newStatus,
        });
      } catch (_) {
        ErrorHandler.handle(error, stackTrace);
        throw DatabaseException(
          message: 'Failed to update job status',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Convert database job to domain model
  domain.Job _convertFromDb(localdb.Job dbJob) {
    return domain.Job(
      id: dbJob.id,
      userId: dbJob.userId,
      customerId: dbJob.customerId,
      clientName: dbJob.clientName,
      title: dbJob.title,
      description: dbJob.description,
      trade: dbJob.trade,
      status: domain.JobStatus.values.firstWhere(
        (s) => s.name == dbJob.status,
        orElse: () => domain.JobStatus.draft,
      ),
      type: domain.JobType.values.firstWhere(
        (t) => t.name == dbJob.type,
        orElse: () => domain.JobType.invoice,
      ),
      laborHours: dbJob.laborHours,
      hourlyRateAtTime: dbJob.laborRate,
      materials: _deserializeMaterials(dbJob.materialsJson),
      taxRateAtTime: dbJob.taxRate,
      totalAmount: dbJob.total,
      createdAt: dbJob.createdAt,
      amountPaid: dbJob.amountPaid,
      amountDue: dbJob.amountDue,
      dueDate: dbJob.dueDate,
      paidAt: dbJob.paidAt,
    );
  }

  domain.Job _convertFromRemote(Map<String, dynamic> row) {
    final status = _resolveStatusFromRemote(row);
    final type = _resolveTypeFromRemote(row['type']);
    final total = _asDouble(row['total_amount']);
    final paidAt =
        _parseDate(row['payment_paid_at']) ?? _parseDate(row['paid_at']);
    final amountPaid = _asDouble(row['amount_paid']);
    // For legacy rows where payment_status='paid' but amount_paid wasn't
    // populated, infer from payment_status.
    final paymentStatus =
        row['payment_status']?.toString().toLowerCase() ?? '';
    final isPaymentMarkedPaid =
        paymentStatus == 'paid' || paymentStatus == 'succeeded';
    final normalizedAmountPaid = amountPaid > 0
        ? amountPaid
        : isPaymentMarkedPaid
            ? total
            : 0.0;
    final rawDue = _asDouble(row['amount_due']);
    final amountDue = rawDue > 0
        ? rawDue
        : (normalizedAmountPaid >= total - 0.01 && total > 0)
            ? 0.0
            : total - normalizedAmountPaid;

    return domain.Job(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      customerId: row['customer_id']?.toString(),
      clientName: (row['client_name']?.toString().trim().isNotEmpty ?? false)
          ? row['client_name'].toString().trim()
          : (row['title']?.toString().trim().isNotEmpty ?? false)
              ? row['title'].toString().trim()
              : 'Unknown Client',
      title: (row['title']?.toString().trim().isNotEmpty ?? false)
          ? row['title'].toString().trim()
          : (row['client_name']?.toString().trim().isNotEmpty ?? false)
              ? row['client_name'].toString().trim()
              : 'Untitled Job',
      description: row['description']?.toString(),
      trade: row['trade']?.toString(),
      status: status,
      type: type,
      laborHours: _asDouble(row['labor_hours']),
      hourlyRateAtTime: _asDouble(row['hourly_rate_at_time']),
      materials: _parseRemoteMaterials(row['materials']),
      taxRateAtTime: _asDouble(row['tax_rate_at_time']),
      totalAmount: total,
      amountPaid: normalizedAmountPaid,
      amountDue: amountDue,
      dueDate: _parseDate(row['due_date']),
      paidAt: paidAt,
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
    );
  }

  domain.JobStatus _resolveStatusFromRemote(Map<String, dynamic> row) {
    // Document state only — draft / sent / cancelled.
    // Payment state is derived from amount_paid / amount_due on the Job model.
    // Legacy rows that still have status='paid' map to sent (they are sent
    // documents that happen to be fully paid).
    final rawStatus = row['status']?.toString().toLowerCase() ?? 'draft';
    if (rawStatus == 'paid') return domain.JobStatus.sent;
    return domain.JobStatus.values.firstWhere(
      (status) => status.name == rawStatus,
      orElse: () => domain.JobStatus.draft,
    );
  }

  domain.JobType _resolveTypeFromRemote(dynamic value) {
    final rawType = value?.toString().toLowerCase() ?? 'invoice';
    return domain.JobType.values.firstWhere(
      (type) => type.name == rawType,
      orElse: () => domain.JobType.invoice,
    );
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  List<domain.Material> _parseRemoteMaterials(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => domain.Material(
                item: item['item']?.toString() ?? 'Item',
                cost: _asDouble(item['cost']),
              ))
          .toList();
    }
    return const [];
  }

  /// Serialize materials to JSON string
  String _serializeMaterials(List<domain.Material> materials) {
    if (materials.isEmpty) return '[]';

    final items = materials.map((m) {
      // Escape quotes in item name
      final escapedItem = m.item.replaceAll('"', '\\"');
      return '{"item":"$escapedItem","cost":${m.cost}}';
    }).join(',');

    return '[$items]';
  }

  /// Deserialize materials from JSON string
  List<domain.Material> _deserializeMaterials(String json) {
    if (json == '[]' || json.isEmpty) return [];

    try {
      // Remove brackets
      final content = json.substring(1, json.length - 1);
      if (content.isEmpty) return [];

      // Split by },{
      final items = <domain.Material>[];
      final parts = content.split('},{');

      for (var part in parts) {
        // Clean up the part
        var clean = part.replaceAll('{', '').replaceAll('}', '');

        // Extract item and cost
        final itemMatch = RegExp(r'"item":"([^"]*)"').firstMatch(clean);
        final costMatch = RegExp(r'"cost":([0-9.]+)').firstMatch(clean);

        if (itemMatch != null && costMatch != null) {
          final item = itemMatch.group(1)!.replaceAll('\\"', '"');
          final cost = double.parse(costMatch.group(1)!);
          items.add(domain.Material(item: item, cost: cost));
        }
      }

      return items;
    } catch (e) {
      ErrorHandler.warning(
          'Failed to deserialize materials', {'error': e, 'json': json});
      return [];
    }
  }
}

/// Provider for Job repository (now uses local DB)
final jobRepositoryProvider = Provider<IJobRepository>((ref) {
  final db = ref.watch(localdb.databaseProvider);
  return JobRepository(db);
});
