class BusinessProfile {
  final String id;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String? taxId;
  final double hourlyRate;
  final double taxRate;
  final String currencySymbol;
  final bool isPro;
  final String subscriptionStatus;

  // Document defaults
  final String invoicePrefix;
  final String quotePrefix;
  final int nextInvoiceNumber;
  final int defaultDueDays;
  final double defaultMarkupPercent;

  BusinessProfile({
    required this.id,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.taxId,
    required this.hourlyRate,
    required this.taxRate,
    required this.currencySymbol,
    this.isPro = false,
    this.subscriptionStatus = 'none',
    this.invoicePrefix = 'INV',
    this.quotePrefix = 'QUO',
    this.nextInvoiceNumber = 1,
    this.defaultDueDays = 14,
    this.defaultMarkupPercent = 0.0,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: (json['id'] ?? json['user_id'])?.toString() ?? '',
        businessName: json['business_name']?.toString() ?? 'My Trade Business',
        businessAddress: json['business_address']?.toString(),
        businessPhone: json['business_phone']?.toString(),
        businessEmail: json['business_email']?.toString(),
        taxId: json['tax_id']?.toString(),
        hourlyRate: ((json['hourly_rate'] ?? json['default_hourly_rate']) as num? ?? 85.0).toDouble(),
        taxRate: ((json['tax_rate'] ?? json['default_tax_rate']) as num? ?? 0.0).toDouble(),
        currencySymbol: json['currency_symbol']?.toString() ?? '\$',
        isPro: json['is_pro'] as bool? ?? false,
        subscriptionStatus: json['subscription_status']?.toString() ?? 'none',
        invoicePrefix: json['invoice_prefix']?.toString() ?? 'INV',
        quotePrefix: json['quote_prefix']?.toString() ?? 'QUO',
        nextInvoiceNumber: (json['next_invoice_number'] as num?)?.toInt() ?? 1,
        defaultDueDays: (json['default_due_days'] as num?)?.toInt() ?? 14,
        defaultMarkupPercent: (json['default_markup_percent'] as num?)?.toDouble() ?? 0.0,
      );
}