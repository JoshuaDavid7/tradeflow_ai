/// A payment receipt generated for each payment event against an invoice.
class PaymentReceipt {
  final String id;
  final String paymentId;
  final String jobId;
  final String userId;
  final String receiptNumber;

  // Business info
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;

  // Customer info
  final String customerName;
  final String? customerEmail;

  // Invoice info
  final String invoiceNumber;
  final double invoiceTotal;

  // Payment info
  final double paymentAmount;
  final String paymentMethod;
  final String? transactionReference;
  final DateTime paymentDate;

  // Balance info
  final double balanceBefore;
  final double balanceAfter;
  final bool isFullyPaid;

  // Storage
  final String? pdfUrl;
  final String? pdfPath;
  final DateTime createdAt;

  const PaymentReceipt({
    required this.id,
    required this.paymentId,
    required this.jobId,
    required this.userId,
    required this.receiptNumber,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    required this.customerName,
    this.customerEmail,
    required this.invoiceNumber,
    required this.invoiceTotal,
    required this.paymentAmount,
    required this.paymentMethod,
    this.transactionReference,
    required this.paymentDate,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.isFullyPaid,
    this.pdfUrl,
    this.pdfPath,
    required this.createdAt,
  });

  String get statusLabel =>
      isFullyPaid ? 'Invoice paid in full' : 'Partial payment received';

  String get methodDisplayName {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'check':
        return 'Check';
      case 'card':
        return 'Credit/Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'zelle':
        return 'Zelle';
      case 'venmo':
        return 'Venmo';
      case 'cashapp':
        return 'Cash App';
      case 'paypal':
        return 'PayPal';
      case 'stripe':
        return 'Stripe';
      default:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_id': paymentId,
        'job_id': jobId,
        'user_id': userId,
        'receipt_number': receiptNumber,
        'business_name': businessName,
        'business_address': businessAddress,
        'business_phone': businessPhone,
        'business_email': businessEmail,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'invoice_number': invoiceNumber,
        'invoice_total': invoiceTotal,
        'payment_amount': paymentAmount,
        'payment_method': paymentMethod,
        'transaction_reference': transactionReference,
        'payment_date': paymentDate.toIso8601String(),
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'is_fully_paid': isFullyPaid,
        'pdf_url': pdfUrl,
        'pdf_path': pdfPath,
        'created_at': createdAt.toIso8601String(),
      };

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      id: json['id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      businessAddress: json['business_address']?.toString(),
      businessPhone: json['business_phone']?.toString(),
      businessEmail: json['business_email']?.toString(),
      customerName: json['customer_name']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceTotal: (json['invoice_total'] as num?)?.toDouble() ?? 0.0,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'other',
      transactionReference: json['transaction_reference']?.toString(),
      paymentDate: DateTime.tryParse(
              json['payment_date']?.toString() ?? '') ??
          DateTime.now(),
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      isFullyPaid: json['is_fully_paid'] == true,
      pdfUrl: json['pdf_url']?.toString(),
      pdfPath: json['pdf_path']?.toString(),
      createdAt: DateTime.tryParse(
              json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
