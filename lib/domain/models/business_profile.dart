/// Business profile information
class BusinessProfile {
  final String id;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String? taxId;
  final double defaultHourlyRate;
  final double defaultTaxRate;
  final String currencySymbol;
  final bool isPro;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.taxId,
    this.defaultHourlyRate = 85.0,
    this.defaultTaxRate = 0.0,
    this.currencySymbol = '\$',
    this.isPro = false,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    // Support both 'id' and 'user_id' as the primary key field name
    final id = (json['id'] ?? json['user_id'])?.toString() ?? '';
    // Support both column naming conventions (default_hourly_rate vs hourly_rate)
    final hourlyRate = (json['default_hourly_rate'] ?? json['hourly_rate'] as num?)?.toDouble() ?? 85.0;
    final taxRate = (json['default_tax_rate'] ?? json['tax_rate'] as num?)?.toDouble() ?? 0.0;
    return BusinessProfile(
      id: id,
      businessName: json['business_name'] as String? ?? 'My Business',
      businessAddress: json['business_address'] as String?,
      businessPhone: json['business_phone'] as String?,
      businessEmail: json['business_email'] as String?,
      taxId: json['tax_id'] as String?,
      defaultHourlyRate: hourlyRate,
      defaultTaxRate: taxRate,
      currencySymbol: json['currency_symbol'] as String? ?? '\$',
      isPro: json['is_pro'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'business_address': businessAddress,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'tax_id': taxId,
      'default_hourly_rate': defaultHourlyRate,
      'default_tax_rate': defaultTaxRate,
      'currency_symbol': currencySymbol,
      'is_pro': isPro,
    };
  }

  BusinessProfile copyWith({
    String? id,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? taxId,
    double? defaultHourlyRate,
    double? defaultTaxRate,
    String? currencySymbol,
    bool? isPro,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      taxId: taxId ?? this.taxId,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isPro: isPro ?? this.isPro,
    );
  }
}
