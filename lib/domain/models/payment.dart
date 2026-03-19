/// Payment received for a job
class Payment {
  final String id;
  final String jobId;
  final String userId;
  
  final double amount;
  final String method; // cash, check, card, bank_transfer, other
  final String? reference; // check number, transaction ID, etc.
  final String? notes;
  
  final DateTime receivedAt;
  final DateTime createdAt;
  final bool synced;

  const Payment({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
    required this.receivedAt,
    required this.createdAt,
    this.synced = false,
  });

  /// Get formatted amount
  String getFormattedAmount(String currencySymbol) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Get payment method display name
  String get methodDisplayName {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'check':
        return 'Check';
      case 'card':
        return 'Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }

  /// Copy with updated fields
  Payment copyWith({
    String? id,
    String? jobId,
    String? userId,
    double? amount,
    String? method,
    String? reference,
    String? notes,
    DateTime? receivedAt,
    DateTime? createdAt,
    bool? synced,
  }) {
    return Payment(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
