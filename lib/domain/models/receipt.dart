/// Receipt with OCR data
class Receipt {
  final String id;
  final String userId;
  final String? expenseId;
  final String? jobId;
  final String? customerId;

  // Image storage
  final String imagePath; // Local file path
  final String? imageUrl; // Cloud storage URL
  final String? thumbnailPath;

  // OCR extracted data
  final String? ocrText;
  final double? extractedAmount;
  final String? extractedVendor;
  final DateTime? extractedDate;
  final String? extractedItemsJson; // AI-extracted line items as JSON string

  // Processing status
  final String ocrStatus; // pending, processing, completed, failed

  // Timestamps
  final DateTime createdAt;
  final bool synced;

  const Receipt({
    required this.id,
    required this.userId,
    this.expenseId,
    this.jobId,
    this.customerId,
    required this.imagePath,
    this.imageUrl,
    this.thumbnailPath,
    this.ocrText,
    this.extractedAmount,
    this.extractedVendor,
    this.extractedDate,
    this.extractedItemsJson,
    this.ocrStatus = 'pending',
    required this.createdAt,
    this.synced = false,
  });

  /// Check if receipt has been processed
  bool get isProcessed => ocrStatus == 'completed';

  /// Check if receipt is being processed
  bool get isProcessing => ocrStatus == 'processing';

  /// Check if OCR failed
  bool get hasFailed => ocrStatus == 'failed';

  /// Check if receipt is linked to expense
  bool get isLinkedToExpense => expenseId != null;

  /// Check if receipt is linked to job
  bool get isLinkedToJob => jobId != null;

  /// Check if we have extracted line items
  bool get hasExtractedItems =>
      extractedItemsJson != null && extractedItemsJson!.isNotEmpty;

  /// Get formatted extracted amount
  String? getFormattedAmount(String currencySymbol) {
    if (extractedAmount == null) return null;
    return '$currencySymbol${extractedAmount!.toStringAsFixed(2)}';
  }

  /// Copy with updated fields
  Receipt copyWith({
    String? id,
    String? userId,
    String? expenseId,
    String? jobId,
    String? customerId,
    String? imagePath,
    String? imageUrl,
    String? thumbnailPath,
    String? ocrText,
    double? extractedAmount,
    String? extractedVendor,
    DateTime? extractedDate,
    String? extractedItemsJson,
    String? ocrStatus,
    DateTime? createdAt,
    bool? synced,
  }) {
    return Receipt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      expenseId: expenseId ?? this.expenseId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      ocrText: ocrText ?? this.ocrText,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedVendor: extractedVendor ?? this.extractedVendor,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedItemsJson: extractedItemsJson ?? this.extractedItemsJson,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Receipt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
