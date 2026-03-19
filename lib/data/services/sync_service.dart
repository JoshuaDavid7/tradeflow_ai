import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import 'supabase_service.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/retry_util.dart';

/// Sync service for offline-first data synchronization
class SyncService {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService(this._db, this._supabase, this._connectivity) {
    _startAutoSync();
  }

  /// Start automatic background sync
  void _startAutoSync() {
    // Sync every 5 minutes when online
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });

    // Also sync when connection is restored
    _connectivitySubscription = _connectivity.statusStream.listen((status) {
      if (status == ConnectivityStatus.online && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Sync all unsynced data
  Future<void> syncAll() async {
    if (_isSyncing || _connectivity.isOffline) {
      ErrorHandler.debug('Sync skipped', {
        'isSyncing': _isSyncing,
        'isOffline': _connectivity.isOffline,
      });
      return;
    }

    _isSyncing = true;

    try {
      ErrorHandler.info('Starting sync');

      // Sync in order of dependencies
      await _syncJobs();
      await _syncExpenses();
      await _syncReceipts();
      await _syncCustomers();

      ErrorHandler.info('Sync completed successfully');
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync jobs
  Future<void> _syncJobs() async {
    final unsyncedJobs = await _db.jobDao.getUnsyncedJobs();

    for (final job in unsyncedJobs) {
      try {
        await RetryUtil.retry(() async {
          // Convert to map for Supabase
          final data = {
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
            'materials_json': job.materialsJson,
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
          await _supabase.insert(table: 'jobs', data: data);

          // Mark as synced locally
          await _db.jobDao.markAsSynced(job.id);

          ErrorHandler.debug('Job synced', {'jobId': job.id});
        });
      } catch (error) {
        ErrorHandler.warning('Failed to sync job', {
          'jobId': job.id,
          'error': error,
        });
      }
    }
  }

  /// Sync expenses
  Future<void> _syncExpenses() async {
    final unsyncedExpenses = await _db.expenseDao.getUnsyncedExpenses();

    for (final expense in unsyncedExpenses) {
      try {
        await RetryUtil.retry(() async {
          final data = {
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

          await _supabase.insert(table: 'expenses', data: data);
          await _db.expenseDao.markAsSynced(expense.id);

          ErrorHandler.debug('Expense synced', {'expenseId': expense.id});
        });
      } catch (error) {
        ErrorHandler.warning('Failed to sync expense', {
          'expenseId': expense.id,
          'error': error,
        });
      }
    }
  }

  /// Sync receipts
  Future<void> _syncReceipts() async {
    final unsyncedReceipts = await _db.receiptDao.getUnsyncedReceipts();

    for (final receipt in unsyncedReceipts) {
      try {
        await RetryUtil.retry(() async {
          final data = {
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

          await _supabase.insert(table: 'receipts', data: data);
          await _db.receiptDao.markAsSynced(receipt.id);

          ErrorHandler.debug('Receipt synced', {'receiptId': receipt.id});
        });
      } catch (error) {
        ErrorHandler.warning('Failed to sync receipt', {
          'receiptId': receipt.id,
          'error': error,
        });
      }
    }
  }

  /// Sync customers
  Future<void> _syncCustomers() async {
    final unsyncedCustomers = await _db.customerDao.getUnsyncedCustomers();

    for (final customer in unsyncedCustomers) {
      try {
        await RetryUtil.retry(() async {
          final data = {
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

          await _supabase.insert(table: 'customers', data: data);
          await _db.customerDao.markAsSynced(customer.id);

          ErrorHandler.debug('Customer synced', {'customerId': customer.id});
        });
      } catch (error) {
        ErrorHandler.warning('Failed to sync customer', {
          'customerId': customer.id,
          'error': error,
        });
      }
    }
  }

  /// Force immediate sync
  Future<void> forceSyncNow() async {
    if (_connectivity.isOffline) {
      throw Exception('Cannot sync while offline');
    }

    await syncAll();
  }

  /// Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    return {
      'unsyncedJobs': (await _db.jobDao.getUnsyncedJobs()).length,
      'unsyncedExpenses': (await _db.expenseDao.getUnsyncedExpenses()).length,
      'unsyncedReceipts': (await _db.receiptDao.getUnsyncedReceipts()).length,
      'unsyncedCustomers': (await _db.customerDao.getUnsyncedCustomers()).length,
    };
  }

  /// Dispose resources
  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final connectivity = ConnectivityService.instance;

  final service = SyncService(db, supabase, connectivity);
  ref.onDispose(() => service.dispose());

  return service;
});
