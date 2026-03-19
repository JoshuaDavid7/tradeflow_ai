import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../services/supabase_service.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/retry_util.dart';

/// Sync service for offline-first data synchronization
class SyncService {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(this._db, this._supabase, this._connectivity);

  /// Start automatic background sync
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });

    ErrorHandler.info('Periodic sync started', {
      'interval': interval.inMinutes,
    });
  }

  /// Stop background sync
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Sync all unsynced data
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      ErrorHandler.debug('Sync already in progress');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (_connectivity.isOffline) {
      ErrorHandler.debug('Cannot sync - offline');
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;

    try {
      ErrorHandler.info('Starting full sync');

      int synced = 0;
      int failed = 0;

      // Sync jobs
      final jobResult = await _syncJobs();
      synced += jobResult.synced;
      failed += jobResult.failed;

      // Sync expenses
      final expenseResult = await _syncExpenses();
      synced += expenseResult.synced;
      failed += expenseResult.failed;

      // Sync customers
      final customerResult = await _syncCustomers();
      synced += customerResult.synced;
      failed += customerResult.failed;

      // Sync receipts
      final receiptResult = await _syncReceipts();
      synced += receiptResult.synced;
      failed += receiptResult.failed;

      ErrorHandler.info('Sync completed', {
        'synced': synced,
        'failed': failed,
      });

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        message: failed == 0
            ? 'All data synced successfully'
            : '$synced synced, $failed failed',
      );
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return SyncResult(
        success: false,
        message: 'Sync failed: ${error.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync jobs to cloud
  Future<_SyncBatchResult> _syncJobs() async {
    try {
      final unsyncedJobs = await _db.jobDao.getUnsyncedJobs();
      int synced = 0;
      int failed = 0;

      for (final job in unsyncedJobs) {
        try {
          await RetryUtil.retry(
            () async {
              // Convert to JSON
              final jobData = {
                'id': job.id,
                'user_id': job.userId,
                'customer_id': job.customerId,
                'title': job.title,
                'client_name': job.clientName,
                'description': job.description,
                'trade': job.trade,
                'status': job.status,
                'type': job.type,
                'labor_hours': job.laborHours,
                'labor_rate': job.laborRate,
                'materials': job.materialsJson,
                'subtotal': job.subtotal,
                'tax_rate': job.taxRate,
                'tax_amount': job.taxAmount,
                'total': job.total,
                'amount_paid': job.amountPaid,
                'amount_due': job.amountDue,
                'created_at': job.createdAt.toIso8601String(),
                'updated_at': job.updatedAt.toIso8601String(),
                'due_date': job.dueDate?.toIso8601String(),
                'paid_at': job.paidAt?.toIso8601String(),
              };

              // Upsert to Supabase
              await _supabase.client
                  .from('jobs')
                  .upsert(jobData);

              // Mark as synced
              await _db.jobDao.markAsSynced(job.id);
              synced++;
            },
            config: const RetryConfig.conservative(),
          );
        } catch (error) {
          ErrorHandler.warning('Failed to sync job', {
            'jobId': job.id,
            'error': error,
          });
          failed++;
        }
      }

      return _SyncBatchResult(synced: synced, failed: failed);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return _SyncBatchResult(synced: 0, failed: 0);
    }
  }

  /// Sync expenses to cloud
  Future<_SyncBatchResult> _syncExpenses() async {
    try {
      final unsyncedExpenses = await _db.expenseDao.getUnsyncedExpenses();
      int synced = 0;
      int failed = 0;

      for (final expense in unsyncedExpenses) {
        try {
          await RetryUtil.retry(
            () async {
              final expenseData = {
                'id': expense.id,
                'user_id': expense.userId,
                'job_id': expense.jobId,
                'description': expense.description,
                'vendor': expense.vendor,
                'category': expense.category,
                'amount': expense.amount,
                'expense_date': expense.expenseDate.toIso8601String(),
                'receipt_path': expense.receiptPath,
                'receipt_url': expense.receiptUrl,
                'ocr_text': expense.ocrText,
                'tax_deductible': expense.taxDeductible,
                'tax_category': expense.taxCategory,
                'payment_method': expense.paymentMethod,
                'created_at': expense.createdAt.toIso8601String(),
                'updated_at': expense.updatedAt.toIso8601String(),
              };

              await _supabase.client
                  .from('expenses')
                  .upsert(expenseData);

              await _db.expenseDao.markAsSynced(expense.id);
              synced++;
            },
            config: const RetryConfig.conservative(),
          );
        } catch (error) {
          ErrorHandler.warning('Failed to sync expense', {
            'expenseId': expense.id,
            'error': error,
          });
          failed++;
        }
      }

      return _SyncBatchResult(synced: synced, failed: failed);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return _SyncBatchResult(synced: 0, failed: 0);
    }
  }

  /// Sync customers to cloud
  Future<_SyncBatchResult> _syncCustomers() async {
    try {
      final unsyncedCustomers = await _db.customerDao.getUnsyncedCustomers();
      int synced = 0;
      int failed = 0;

      for (final customer in unsyncedCustomers) {
        try {
          await RetryUtil.retry(
            () async {
              final customerData = {
                'id': customer.id,
                'user_id': customer.userId,
                'name': customer.name,
                'email': customer.email,
                'phone': customer.phone,
                'address': customer.address,
                'notes': customer.notes,
                'total_billed': customer.totalBilled,
                'total_paid': customer.totalPaid,
                'balance': customer.balance,
                'job_count': customer.jobCount,
                'last_job_date': customer.lastJobDate?.toIso8601String(),
                'created_at': customer.createdAt.toIso8601String(),
                'updated_at': customer.updatedAt.toIso8601String(),
              };

              await _supabase.client
                  .from('customers')
                  .upsert(customerData);

              await _db.customerDao.markAsSynced(customer.id);
              synced++;
            },
            config: const RetryConfig.conservative(),
          );
        } catch (error) {
          ErrorHandler.warning('Failed to sync customer', {
            'customerId': customer.id,
            'error': error,
          });
          failed++;
        }
      }

      return _SyncBatchResult(synced: synced, failed: failed);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return _SyncBatchResult(synced: 0, failed: 0);
    }
  }

  /// Sync receipts to cloud
  Future<_SyncBatchResult> _syncReceipts() async {
    try {
      final unsyncedReceipts = await _db.receiptDao.getUnsyncedReceipts();
      int synced = 0;
      int failed = 0;

      for (final receipt in unsyncedReceipts) {
        try {
          await RetryUtil.retry(
            () async {
              final receiptData = {
                'id': receipt.id,
                'user_id': receipt.userId,
                'expense_id': receipt.expenseId,
                'job_id': receipt.jobId,
                'image_path': receipt.imagePath,
                'image_url': receipt.imageUrl,
                'thumbnail_path': receipt.thumbnailPath,
                'ocr_text': receipt.ocrText,
                'extracted_amount': receipt.extractedAmount,
                'extracted_vendor': receipt.extractedVendor,
                'extracted_date': receipt.extractedDate?.toIso8601String(),
                'ocr_status': receipt.ocrStatus,
                'created_at': receipt.createdAt.toIso8601String(),
              };

              await _supabase.client
                  .from('receipts')
                  .upsert(receiptData);

              await _db.receiptDao.markAsSynced(receipt.id);
              synced++;
            },
            config: const RetryConfig.conservative(),
          );
        } catch (error) {
          ErrorHandler.warning('Failed to sync receipt', {
            'receiptId': receipt.id,
            'error': error,
          });
          failed++;
        }
      }

      return _SyncBatchResult(synced: synced, failed: failed);
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return _SyncBatchResult(synced: 0, failed: 0);
    }
  }

  /// Force sync specific job
  Future<bool> syncJob(String jobId) async {
    try {
      final job = await _db.jobDao.getJobById(jobId);
      if (job == null) return false;

      final jobData = {
        'id': job.id,
        'user_id': job.userId,
        'customer_id': job.customerId,
        'title': job.title,
        'client_name': job.clientName,
        'description': job.description,
        'status': job.status,
        'type': job.type,
        'labor_hours': job.laborHours,
        'labor_rate': job.laborRate,
        'materials': job.materialsJson,
        'subtotal': job.subtotal,
        'tax_rate': job.taxRate,
        'tax_amount': job.taxAmount,
        'total': job.total,
        'amount_paid': job.amountPaid,
        'amount_due': job.amountDue,
        'created_at': job.createdAt.toIso8601String(),
        'updated_at': job.updatedAt.toIso8601String(),
      };

      await _supabase.client
          .from('jobs')
          .upsert(jobData);

      await _db.jobDao.markAsSynced(jobId);
      return true;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
  }
}

/// Sync result
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;

  SyncResult({
    required this.success,
    this.synced = 0,
    this.failed = 0,
    this.message = '',
  });
}

/// Internal batch result
class _SyncBatchResult {
  final int synced;
  final int failed;

  _SyncBatchResult({required this.synced, required this.failed});
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final connectivity = ConnectivityService.instance;

  final service = SyncService(db, supabase, connectivity);
  ref.onDispose(() => service.dispose());

  // Start automatic sync
  service.startPeriodicSync();

  return service;
});
