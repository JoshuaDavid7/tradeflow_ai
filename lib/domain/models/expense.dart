
/// Expense categories
enum ExpenseCategory {
  materials('Materials', true),
  labor('Subcontractor Labor', true),
  fuel('Fuel & Vehicle', true),
  tools('Tools & Equipment', true),
  supplies('Office Supplies', true),
  insurance('Insurance', true),
  utilities('Utilities', true),
  marketing('Marketing', true),
  fees('Fees & Permits', true),
  meals('Meals & Entertainment', false),
  other('Other', true);

  final String displayName;
  final bool taxDeductible;
  
  const ExpenseCategory(this.displayName, this.taxDeductible);
}

/// Payment methods
enum PaymentMethod {
  cash('Cash'),
  card('Credit/Debit Card'),
  check('Check'),
  bankTransfer('Bank Transfer'),
  other('Other');

  final String displayName;
  
  const PaymentMethod(this.displayName);
}

/// Expense model
class Expense {
  final String id;
  final String userId;
  final String? jobId;
  final String? customerId;

  final String description;
  final String? vendor;
  final ExpenseCategory category;
  
  final double amount;
  final DateTime expenseDate;
  
  // Receipt
  final String? receiptPath;
  final String? receiptUrl;
  final String? ocrText;
  
  // Tax
  final bool taxDeductible;
  final String? taxCategory;
  
  // Payment
  final PaymentMethod? paymentMethod;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const Expense({
    required this.id,
    required this.userId,
    this.jobId,
    this.customerId,
    required this.description,
    this.vendor,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.receiptPath,
    this.receiptUrl,
    this.ocrText,
    this.taxDeductible = true,
    this.taxCategory,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  /// Check if expense has receipt
  bool get hasReceipt => receiptPath != null || receiptUrl != null;

  /// Check if expense is job-specific
  bool get isJobExpense => jobId != null;

  /// Get formatted amount
  String getFormattedAmount(String currencySymbol) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Copy with updated fields
  Expense copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? customerId,
    String? description,
    String? vendor,
    ExpenseCategory? category,
    double? amount,
    DateTime? expenseDate,
    String? receiptPath,
    String? receiptUrl,
    String? ocrText,
    bool? taxDeductible,
    String? taxCategory,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptPath: receiptPath ?? this.receiptPath,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      ocrText: ocrText ?? this.ocrText,
      taxDeductible: taxDeductible ?? this.taxDeductible,
      taxCategory: taxCategory ?? this.taxCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
