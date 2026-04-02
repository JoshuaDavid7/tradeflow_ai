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

  // Document defaults
  final String invoicePrefix;
  final String quotePrefix;
  final int nextInvoiceNumber;
  final int defaultDueDays;
  final double defaultMarkupPercent;

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
    this.invoicePrefix = 'INV',
    this.quotePrefix = 'QUO',
    this.nextInvoiceNumber = 1,
    this.defaultDueDays = 14,
    this.defaultMarkupPercent = 0.0,
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
      invoicePrefix: json['invoice_prefix'] as String? ?? 'INV',
      quotePrefix: json['quote_prefix'] as String? ?? 'QUO',
      nextInvoiceNumber: (json['next_invoice_number'] as num?)?.toInt() ?? 1,
      defaultDueDays: (json['default_due_days'] as num?)?.toInt() ?? 14,
      defaultMarkupPercent: (json['default_markup_percent'] as num?)?.toDouble() ?? 0.0,
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
      'invoice_prefix': invoicePrefix,
      'quote_prefix': quotePrefix,
      'next_invoice_number': nextInvoiceNumber,
      'default_due_days': defaultDueDays,
      'default_markup_percent': defaultMarkupPercent,
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
    String? invoicePrefix,
    String? quotePrefix,
    int? nextInvoiceNumber,
    int? defaultDueDays,
    double? defaultMarkupPercent,
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
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      quotePrefix: quotePrefix ?? this.quotePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      defaultDueDays: defaultDueDays ?? this.defaultDueDays,
      defaultMarkupPercent: defaultMarkupPercent ?? this.defaultMarkupPercent,
    );
  }
}
