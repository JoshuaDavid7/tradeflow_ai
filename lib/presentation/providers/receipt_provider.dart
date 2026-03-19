import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../domain/models/receipt.dart' as domain;
import '../../data/local/database.dart' as localdb;
import '../../data/services/ocr_service.dart';
import '../../data/services/receipt_ai_service.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';
import 'package:uuid/uuid.dart';

/// Receipt processing state
enum ReceiptProcessingState {
  idle,
  capturing,
  processing,
  completed,
  error,
}

/// Receipt state
class ReceiptState {
  final ReceiptProcessingState processingState;
  final domain.Receipt? currentReceipt;
  final String? error;
  final double? progress;

  const ReceiptState({
    this.processingState = ReceiptProcessingState.idle,
    this.currentReceipt,
    this.error,
    this.progress,
  });

  ReceiptState copyWith({
    ReceiptProcessingState? processingState,
    domain.Receipt? currentReceipt,
    String? error,
    double? progress,
  }) {
    return ReceiptState(
      processingState: processingState ?? this.processingState,
      currentReceipt: currentReceipt ?? this.currentReceipt,
      error: error,
      progress: progress ?? this.progress,
    );
  }

  bool get isProcessing => processingState == ReceiptProcessingState.processing;
  bool get hasError => processingState == ReceiptProcessingState.error;
  bool get isComplete => processingState == ReceiptProcessingState.completed;
}

/// Receipt notifier
class ReceiptNotifier extends StateNotifier<ReceiptState> {
  final localdb.AppDatabase _db;
  final OcrService _ocrService;
  final ReceiptAiService _aiService;
  final String? _userId;
  final SupabaseService _supabase;

  ReceiptNotifier(
      this._db, this._ocrService, this._aiService, this._userId, this._supabase)
      : super(const ReceiptState());

  /// Process receipt image with OCR
  Future<domain.Receipt?> processReceipt(String imagePath) async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(
        processingState: ReceiptProcessingState.error,
        error: 'User not authenticated',
      );
      return null;
    }

    state = state.copyWith(
      processingState: ReceiptProcessingState.processing,
      progress: 0.2,
      error: null,
    );

    String? receiptId;
    try {
      // Create receipt record
      receiptId = const Uuid().v4();
      await _db.receiptDao.createReceipt(
        localdb.ReceiptsCompanion.insert(
          id: receiptId,
          userId: userId,
          imagePath: imagePath,
          ocrStatus: const drift.Value('processing'),
          // createdAt defaults in DB table definition
        ),
      );

      state = state.copyWith(progress: 0.35);

      String? cloudImageUrl;
      try {
        cloudImageUrl = await _backupReceiptImage(
          receiptId: receiptId,
          userId: userId,
          imagePath: imagePath,
        );
        if (cloudImageUrl != null && cloudImageUrl.isNotEmpty) {
          await _db.receiptDao.updateReceipt(
            receiptId,
            localdb.ReceiptsCompanion(
              imageUrl: drift.Value(cloudImageUrl),
            ),
          );
        }
      } catch (error, stackTrace) {
        ErrorHandler.warning('Receipt cloud backup skipped', {
          'receiptId': receiptId,
          'error': error.toString(),
        });
        ErrorHandler.handle(error, stackTrace);
      }

      state = state.copyWith(progress: 0.55);

      // Process with OCR
      ErrorHandler.info('Processing receipt with OCR', {'path': imagePath});
      final ocrResult = await _ocrService.processReceipt(imagePath);

      state = state.copyWith(progress: 0.65);

      // Use Gemini AI to extract itemized line items from OCR text
      String? extractedItemsJson;
      try {
        final aiResult = await _aiService.extractItems(ocrResult.fullText);
        if (aiResult.items.isNotEmpty) {
          extractedItemsJson = aiResult.toJsonString();
          ErrorHandler.info('AI receipt extraction complete', {
            'itemCount': aiResult.items.length,
          });
        }
      } catch (e) {
        ErrorHandler.warning('AI receipt extraction skipped', {'error': e.toString()});
      }

      state = state.copyWith(progress: 0.8);

      // Update receipt with OCR results + AI extracted items
      await _db.receiptDao.updateOcrResults(
        receiptId: receiptId,
        ocrText: ocrResult.fullText,
        amount: ocrResult.amount,
        vendor: ocrResult.vendor,
        date: ocrResult.date,
      );
      // Update extracted items separately
      if (extractedItemsJson != null) {
        await _db.receiptDao.updateReceipt(
          receiptId,
          localdb.ReceiptsCompanion(
            extractedItemsJson: drift.Value(extractedItemsJson),
          ),
        );
      }

      final receipt = await _db.receiptDao.getReceiptById(receiptId);
      if (receipt == null) {
        throw Exception('Receipt not found after processing');
      }

      await _upsertReceiptMetadata(receipt);

      state = state.copyWith(
        processingState: ReceiptProcessingState.completed,
        currentReceipt: _convertFromDb(receipt),
        progress: 1.0,
      );

      ErrorHandler.info('Receipt processed successfully', {
        'receiptId': receiptId,
        'hasAmount': ocrResult.amount != null,
        'hasVendor': ocrResult.vendor != null,
      });

      return _convertFromDb(receipt);
    } catch (error, stackTrace) {
      if (receiptId != null) {
        try {
          await _db.receiptDao.updateReceipt(
            receiptId,
            const localdb.ReceiptsCompanion(
              ocrStatus: drift.Value('failed'),
            ),
          );
        } catch (_) {}
      }

      final errorMessage = ErrorHandler.handle(error, stackTrace);

      state = state.copyWith(
        processingState: ReceiptProcessingState.error,
        error: errorMessage,
      );

      return null;
    }
  }

  /// Link receipt to expense
  Future<bool> linkToExpense(String receiptId, String expenseId) async {
    try {
      await _db.receiptDao.linkToExpense(receiptId, expenseId);
      final updated = await _db.receiptDao.getReceiptById(receiptId);
      if (updated != null) {
        await _upsertReceiptMetadata(updated);
      }
      ErrorHandler.info('Receipt linked to expense', {
        'receiptId': receiptId,
        'expenseId': expenseId,
      });
      return true;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return false;
    }
  }

  /// Link receipt to job
  Future<bool> linkToJob(String receiptId, String jobId) async {
    try {
      await _db.receiptDao.linkToJob(receiptId, jobId);
      final updated = await _db.receiptDao.getReceiptById(receiptId);
      if (updated != null) {
        await _upsertReceiptMetadata(updated);
      }
      ErrorHandler.info('Receipt linked to job', {
        'receiptId': receiptId,
        'jobId': jobId,
      });
      return true;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const ReceiptState();
  }

  Future<domain.Receipt?> getReceiptById(String receiptId) async {
    final dbReceipt = await _db.receiptDao.getReceiptById(receiptId);
    if (dbReceipt == null) return null;
    return _convertFromDb(dbReceipt);
  }

  Future<String?> _backupReceiptImage({
    required String receiptId,
    required String userId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return null;
    }

    await _supabase.ensureValidSession();

    final now = DateTime.now();
    final ext = _normalizedFileExtension(imagePath);
    final storagePath = [
      userId,
      'receipts',
      '${now.year}${now.month.toString().padLeft(2, '0')}',
      '$receiptId.$ext',
    ].join('/');

    await _supabase.uploadFile(
      bucket: 'receipts',
      path: storagePath,
      file: file,
      contentType: _imageContentType(ext),
    );

    return await _supabase.client.storage
        .from('receipts')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  Future<void> _upsertReceiptMetadata(localdb.Receipt receipt) async {
    try {
      await _supabase.ensureValidSession();

      await _supabase.client.from('receipts').upsert({
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
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _db.receiptDao.markAsSynced(receipt.id);
    } catch (error, stackTrace) {
      ErrorHandler.warning('Receipt metadata sync skipped', {
        'receiptId': receipt.id,
        'error': error.toString(),
      });
      ErrorHandler.handle(error, stackTrace);
    }
  }

  String _normalizedFileExtension(String path) {
    final segments = path.split('.');
    if (segments.length < 2) return 'jpg';
    final ext = segments.last.trim().toLowerCase();
    if (ext.isEmpty) return 'jpg';
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  String _imageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Convert database receipt to domain model
  domain.Receipt _convertFromDb(localdb.Receipt dbReceipt) {
    return domain.Receipt(
      id: dbReceipt.id,
      userId: dbReceipt.userId,
      expenseId: dbReceipt.expenseId,
      jobId: dbReceipt.jobId,
      customerId: dbReceipt.customerId,
      imagePath: dbReceipt.imagePath,
      imageUrl: dbReceipt.imageUrl,
      thumbnailPath: dbReceipt.thumbnailPath,
      ocrText: dbReceipt.ocrText,
      extractedAmount: dbReceipt.extractedAmount,
      extractedVendor: dbReceipt.extractedVendor,
      extractedDate: dbReceipt.extractedDate,
      extractedItemsJson: dbReceipt.extractedItemsJson,
      ocrStatus: dbReceipt.ocrStatus,
      createdAt: dbReceipt.createdAt,
      synced: dbReceipt.synced,
    );
  }
}

/// Provider for receipt processing
final receiptProvider =
    StateNotifierProvider<ReceiptNotifier, ReceiptState>((ref) {
  final db = ref.watch(localdb.databaseProvider);
  final ocrService = ref.watch(ocrServiceProvider);
  final aiService = ref.watch(receiptAiServiceProvider);
  final userId = ref.watch(userIdProvider);
  final supabase = ref.watch(supabaseServiceProvider);

  return ReceiptNotifier(db, ocrService, aiService, userId, supabase);
});

/// Provider for all receipts
final allReceiptsProvider = FutureProvider<List<domain.Receipt>>((ref) async {
  final db = ref.watch(localdb.databaseProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) return [];

  final dbReceipts = await db.receiptDao.getAllReceipts(userId);

  return dbReceipts.map((dbReceipt) {
    return domain.Receipt(
      id: dbReceipt.id,
      userId: dbReceipt.userId,
      expenseId: dbReceipt.expenseId,
      jobId: dbReceipt.jobId,
      customerId: dbReceipt.customerId,
      imagePath: dbReceipt.imagePath,
      imageUrl: dbReceipt.imageUrl,
      thumbnailPath: dbReceipt.thumbnailPath,
      ocrText: dbReceipt.ocrText,
      extractedAmount: dbReceipt.extractedAmount,
      extractedVendor: dbReceipt.extractedVendor,
      extractedDate: dbReceipt.extractedDate,
      extractedItemsJson: dbReceipt.extractedItemsJson,
      ocrStatus: dbReceipt.ocrStatus,
      createdAt: dbReceipt.createdAt,
      synced: dbReceipt.synced,
    );
  }).toList();
});

/// Provider for unlinked receipts (not attached to anything)
final unlinkedReceiptsProvider =
    FutureProvider<List<domain.Receipt>>((ref) async {
  final db = ref.watch(localdb.databaseProvider);
  final userId = ref.watch(userIdProvider);

  if (userId == null) return [];

  final dbReceipts = await db.receiptDao.getUnlinkedReceipts(userId);

  return dbReceipts.map((dbReceipt) {
    return domain.Receipt(
      id: dbReceipt.id,
      userId: dbReceipt.userId,
      expenseId: dbReceipt.expenseId,
      jobId: dbReceipt.jobId,
      customerId: dbReceipt.customerId,
      imagePath: dbReceipt.imagePath,
      imageUrl: dbReceipt.imageUrl,
      thumbnailPath: dbReceipt.thumbnailPath,
      ocrText: dbReceipt.ocrText,
      extractedAmount: dbReceipt.extractedAmount,
      extractedVendor: dbReceipt.extractedVendor,
      extractedDate: dbReceipt.extractedDate,
      extractedItemsJson: dbReceipt.extractedItemsJson,
      ocrStatus: dbReceipt.ocrStatus,
      createdAt: dbReceipt.createdAt,
      synced: dbReceipt.synced,
    );
  }).toList();
});
