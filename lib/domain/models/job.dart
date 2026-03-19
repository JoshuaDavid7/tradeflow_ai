
/// Job types
enum JobType {
  invoice,
  quote;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

/// Job status
enum JobStatus {
  draft,
  sent,
  paid,
  cancelled;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  bool get isActive => this == draft || this == sent;
  /// Whether the DB status column is 'paid'. Prefer [Job.isFullyPaid] for
  /// payment-aware checks — it derives from amounts, not from this field.
  bool get isPaid => this == paid;
  bool get isCancelled => this == cancelled;
}

/// Material item
class Material {
  final String item;
  final double cost;

  const Material({
    required this.item,
    required this.cost,
  });

  factory Material.fromJson(Map<String, dynamic> json) => Material(
        item: json['item']?.toString() ?? '',
        cost: (json['cost'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'item': item,
        'cost': cost,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Material &&
          runtimeType == other.runtimeType &&
          item == other.item &&
          cost == other.cost;

  @override
  int get hashCode => item.hashCode ^ cost.hashCode;
}

/// Job domain model
class Job {
  final String id;
  final String userId;
  final String? customerId;
  final String clientName;
  final String title;
  final String? description;
  final String? trade;
  final JobStatus status;
  final JobType type;
  final double laborHours;
  final double hourlyRateAtTime;
  final List<Material> materials;
  final double taxRateAtTime;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.userId,
    this.customerId,
    required this.clientName,
    required this.title,
    this.description,
    this.trade,
    required this.status,
    required this.type,
    required this.laborHours,
    required this.hourlyRateAtTime,
    required this.materials,
    required this.taxRateAtTime,
    required this.totalAmount,
    this.amountPaid = 0.0,
    double? amountDue,
    this.dueDate,
    this.paidAt,
    required this.createdAt,
  }) : amountDue = amountDue ?? (totalAmount - amountPaid);

  // ── Payment-state helpers (derived from amounts, not status) ─────────────

  /// True when the full invoice amount has been collected.
  bool get isFullyPaid =>
      totalAmount > 0 && amountPaid > 0.01 && amountDue <= 0.01;

  /// True when some payment has been recorded but the balance isn't settled.
  bool get isPartiallyPaid => amountPaid > 0.01 && !isFullyPaid;

  /// True when this is a sent invoice that still has an outstanding balance.
  bool get isAwaitingPayment =>
      type == JobType.invoice && status == JobStatus.sent && amountDue > 0.01;

  /// Calculate labor cost
  double get laborCost => laborHours * hourlyRateAtTime;

  /// Calculate materials cost
  double get materialsCost =>
      materials.fold(0.0, (sum, material) => sum + material.cost);

  /// Calculate subtotal
  double get subtotal => laborCost + materialsCost;

  /// Calculate tax amount
  double get taxAmount => subtotal * (taxRateAtTime / 100);

  /// Verify total is calculated correctly
  bool get isTotalCorrect {
    final calculatedTotal = subtotal + taxAmount;
    return (calculatedTotal - totalAmount).abs() < 0.01; // Allow for rounding
  }

  /// Create from JSON
  factory Job.fromJson(Map<String, dynamic> json) {
    // Parse materials
    final materialsJson = json['materials'] as List? ?? [];
    final materials = materialsJson
        .map((m) => Material.fromJson(m as Map<String, dynamic>))
        .toList();

    // Parse enums
    final statusStr = (json['status'] as String? ?? 'draft').toLowerCase();
    final typeStr = (json['type'] as String? ?? 'invoice').toLowerCase();

    return Job(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerId: json['customer_id'] as String?,
      clientName: json['client_name']?.toString() ?? 'Unknown Client',
      title: json['title']?.toString() ?? 'Untitled Job',
      description: json['description'] as String?,
      trade: json['trade'] as String?,
      status: JobStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => JobStatus.draft,
      ),
      type: JobType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => JobType.invoice,
      ),
      laborHours: (json['labor_hours'] as num? ?? 0).toDouble(),
      hourlyRateAtTime: (json['hourly_rate_at_time'] as num? ?? 0).toDouble(),
      materials: materials,
      taxRateAtTime: (json['tax_rate_at_time'] as num? ?? 0).toDouble(),
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      amountPaid: (json['amount_paid'] as num? ?? 0).toDouble(),
      amountDue: (json['amount_due'] as num?)?.toDouble(),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Convert to JSON for database
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'customer_id': customerId,
        'client_name': clientName,
        'title': title,
        'description': description,
        'trade': trade,
        'status': status.name,
        'type': type.name,
        'labor_hours': laborHours,
        'hourly_rate_at_time': hourlyRateAtTime,
        'materials': materials.map((m) => m.toJson()).toList(),
        'tax_rate_at_time': taxRateAtTime,
        'total_amount': totalAmount,
        'amount_paid': amountPaid,
        'amount_due': amountDue,
        'due_date': dueDate?.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
      };

  /// Create a copy with updated fields
  Job copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? clientName,
    String? title,
    String? description,
    String? trade,
    JobStatus? status,
    JobType? type,
    double? laborHours,
    double? hourlyRateAtTime,
    List<Material>? materials,
    double? taxRateAtTime,
    double? totalAmount,
    double? amountPaid,
    double? amountDue,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      clientName: clientName ?? this.clientName,
      title: title ?? this.title,
      description: description ?? this.description,
      trade: trade ?? this.trade,
      status: status ?? this.status,
      type: type ?? this.type,
      laborHours: laborHours ?? this.laborHours,
      hourlyRateAtTime: hourlyRateAtTime ?? this.hourlyRateAtTime,
      materials: materials ?? this.materials,
      taxRateAtTime: taxRateAtTime ?? this.taxRateAtTime,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
