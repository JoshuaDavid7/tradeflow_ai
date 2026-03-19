import 'dart:convert';

/// Represents a fully customisable invoice/quote template.
/// Stored as JSON in Supabase `invoice_templates` table.
class InvoiceTemplate {
  static const String headerStyleModern = 'modern';
  static const String headerStyleClassic = 'classic';
  static const String headerStyleStatement = 'statement';
  static const String paymentMethodCheck = 'check';
  static const String paymentMethodStripe = 'stripe';
  static const String paymentMethodZelle = 'zelle';
  static const String paymentMethodVenmo = 'venmo';
  static const String paymentMethodCashApp = 'cash_app';
  static const String paymentMethodPaypal = 'paypal';
  static const String paymentMethodBankTransfer = 'bank_transfer';
  static const String logoPositionLeft = 'left';
  static const String logoPositionCenter = 'center';
  static const String logoPositionRight = 'right';
  static const Set<String> supportedHeaderStyles = {
    headerStyleModern,
    headerStyleClassic,
    headerStyleStatement,
  };
  static const Set<String> supportedLogoPositions = {
    logoPositionLeft,
    logoPositionCenter,
    logoPositionRight,
  };
  static const List<String> supportedPaymentMethods = [
    paymentMethodStripe,
    paymentMethodCheck,
    paymentMethodZelle,
    paymentMethodVenmo,
    paymentMethodCashApp,
    paymentMethodPaypal,
    paymentMethodBankTransfer,
  ];

  static const Map<String, String> paymentMethodLabels = {
    paymentMethodStripe: 'Stripe Checkout',
    paymentMethodCheck: 'Check',
    paymentMethodZelle: 'Zelle',
    paymentMethodVenmo: 'Venmo',
    paymentMethodCashApp: 'Cash App',
    paymentMethodPaypal: 'PayPal',
    paymentMethodBankTransfer: 'Bank Transfer',
  };

  static String normalizeHeaderStyle(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return supportedHeaderStyles.contains(normalized)
        ? normalized
        : headerStyleModern;
  }

  static String normalizeLogoPosition(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return supportedLogoPositions.contains(normalized)
        ? normalized
        : logoPositionLeft;
  }

  static String normalizePaymentMethod(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return supportedPaymentMethods.contains(normalized) ? normalized : '';
  }

  static List<String> normalizePaymentMethods(dynamic value) {
    final raw = value is List
        ? value
        : value is String
            ? value.split(',')
            : const [];
    final set = <String>{};
    for (final item in raw) {
      final method = normalizePaymentMethod(item?.toString());
      if (method.isNotEmpty) set.add(method);
    }
    return supportedPaymentMethods.where(set.contains).toList();
  }

  static Map<String, String> normalizePaymentMethodDetails(dynamic value) {
    if (value == null) return const {};
    if (value is! Map) return const {};

    final result = <String, String>{};
    for (final entry in value.entries) {
      final method = normalizePaymentMethod(entry.key.toString());
      if (method.isEmpty) continue;
      final detail = sanitizePaymentDetail(entry.value?.toString() ?? '');
      if (detail.isNotEmpty) {
        result[method] = detail;
      }
    }
    return result;
  }

  static String sanitizePaymentDetail(String value) {
    final normalized = value
        .replaceAll('•', '*')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('…', '...')
        .replaceAll('\u00A0', ' ');
    final withoutControl =
        normalized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    final trimmed = withoutControl.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > 600 ? trimmed.substring(0, 600) : trimmed;
  }

  /// Normalises colour strings to '#RRGGBB' for reliable PDF/UI rendering.
  static String normalizeHexColor(
    String? value, {
    required String fallback,
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return fallback;

    var normalized = raw.toUpperCase();
    if (normalized.startsWith('0X')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('#')) {
      normalized = normalized.substring(1);
    }

    // Drop alpha channel from AARRGGBB.
    if (normalized.length == 8) {
      normalized = normalized.substring(2);
    }

    // Expand shorthand RGB.
    if (normalized.length == 3) {
      normalized =
          '${normalized[0]}${normalized[0]}${normalized[1]}${normalized[1]}${normalized[2]}${normalized[2]}';
    }

    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)) {
      return fallback;
    }

    return '#$normalized';
  }

  final String id;
  final String name;

  // Branding
  final String? logoUrl; // Supabase Storage public URL
  final String primaryColor; // hex e.g. '#1565C0'
  final String accentColor; // hex e.g. '#0D47A1'
  final String fontFamily; // 'helvetica' | 'times' | 'courier'
  final String headerStyle; // 'modern' | 'classic' | 'statement'
  final String logoPosition; // 'left' | 'center' | 'right'

  // Layout toggles
  final bool showLogo;
  final bool showBusinessAddress;
  final bool showBusinessPhone;
  final bool showBusinessEmail;
  final bool showTaxId;
  final bool showInvoiceNumber;
  final bool showDueDate;
  final bool showPaymentTerms;

  // Custom text blocks
  final String headerTagline; // shown under business name
  final String footerNote; // e.g. "Payment due within 30 days"
  final String paymentTerms; // e.g. "Bank Transfer: BSB 123-456 Acc 789012"
  final String thankYouMessage; // e.g. "Thank you for your business!"
  final List<String> preferredPaymentMethods;
  final Map<String, String> paymentMethodDetails;

  // Custom fields (list of label strings the user wants shown)
  final List<String>
      customFields; // e.g. ['Licence No: 123456', 'ABN: 99 999 999 999']

  // Table header labels (user can rename columns)
  final String colDescription;
  final String colQty;
  final String colRate;
  final String colAmount;

  const InvoiceTemplate({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor = '#1565C0',
    this.accentColor = '#0D47A1',
    this.fontFamily = 'helvetica',
    this.headerStyle = headerStyleModern,
    this.logoPosition = logoPositionLeft,
    this.showLogo = true,
    this.showBusinessAddress = true,
    this.showBusinessPhone = true,
    this.showBusinessEmail = true,
    this.showTaxId = true,
    this.showInvoiceNumber = true,
    this.showDueDate = true,
    this.showPaymentTerms = true,
    this.headerTagline = '',
    this.footerNote = 'Payment due within 14 days',
    this.paymentTerms = '',
    this.thankYouMessage = 'Thank you for your business!',
    this.preferredPaymentMethods = const [],
    this.paymentMethodDetails = const {},
    this.customFields = const [],
    this.colDescription = 'DESCRIPTION',
    this.colQty = 'QTY',
    this.colRate = 'RATE',
    this.colAmount = 'AMOUNT',
  });

  factory InvoiceTemplate.defaultTemplate() => const InvoiceTemplate(
        id: 'default',
        name: 'Reference Clean',
      );

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    final settingsRaw = json['settings'];
    final Map<String, dynamic> s = settingsRaw is String
        ? (jsonDecode(settingsRaw) as Map<String, dynamic>)
        : (settingsRaw as Map<String, dynamic>? ?? {});

    List<String> parseCustomFields() {
      final raw = s['custom_fields'];
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return InvoiceTemplate(
      id: json['id']?.toString() ?? 'default',
      name: json['name']?.toString() ?? 'My Template',
      logoUrl: s['logo_url']?.toString(),
      primaryColor: normalizeHexColor(
        s['primary_color']?.toString(),
        fallback: '#1565C0',
      ),
      accentColor: normalizeHexColor(
        s['accent_color']?.toString(),
        fallback: '#0D47A1',
      ),
      fontFamily: s['font_family']?.toString() ?? 'helvetica',
      headerStyle: normalizeHeaderStyle(s['header_style']?.toString()),
      logoPosition: normalizeLogoPosition(s['logo_position']?.toString()),
      showLogo: s['show_logo'] as bool? ?? true,
      showBusinessAddress: s['show_business_address'] as bool? ?? true,
      showBusinessPhone: s['show_business_phone'] as bool? ?? true,
      showBusinessEmail: s['show_business_email'] as bool? ?? true,
      showTaxId: s['show_tax_id'] as bool? ?? true,
      showInvoiceNumber: s['show_invoice_number'] as bool? ?? true,
      showDueDate: s['show_due_date'] as bool? ?? true,
      showPaymentTerms: s['show_payment_terms'] as bool? ?? true,
      headerTagline: s['header_tagline']?.toString() ?? '',
      footerNote: s['footer_note']?.toString() ?? 'Payment due within 14 days',
      paymentTerms: s['payment_terms']?.toString() ?? '',
      thankYouMessage:
          s['thank_you_message']?.toString() ?? 'Thank you for your business!',
      preferredPaymentMethods:
          normalizePaymentMethods(s['preferred_payment_methods']),
      paymentMethodDetails:
          normalizePaymentMethodDetails(s['payment_method_details']),
      customFields: parseCustomFields(),
      colDescription: s['col_description']?.toString() ?? 'DESCRIPTION',
      colQty: s['col_qty']?.toString() ?? 'QTY',
      colRate: s['col_rate']?.toString() ?? 'RATE',
      colAmount: s['col_amount']?.toString() ?? 'AMOUNT',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'settings': jsonEncode({
          'logo_url': logoUrl,
          'primary_color': primaryColor,
          'accent_color': accentColor,
          'font_family': fontFamily,
          'header_style': headerStyle,
          'logo_position': logoPosition,
          'show_logo': showLogo,
          'show_business_address': showBusinessAddress,
          'show_business_phone': showBusinessPhone,
          'show_business_email': showBusinessEmail,
          'show_tax_id': showTaxId,
          'show_invoice_number': showInvoiceNumber,
          'show_due_date': showDueDate,
          'show_payment_terms': showPaymentTerms,
          'header_tagline': headerTagline,
          'footer_note': footerNote,
          'payment_terms': paymentTerms,
          'thank_you_message': thankYouMessage,
          'preferred_payment_methods': preferredPaymentMethods,
          'payment_method_details': paymentMethodDetails,
          'custom_fields': customFields,
          'col_description': colDescription,
          'col_qty': colQty,
          'col_rate': colRate,
          'col_amount': colAmount,
        }),
      };

  InvoiceTemplate copyWith({
    String? id,
    String? name,
    String? logoUrl,
    bool clearLogo = false,
    String? primaryColor,
    String? accentColor,
    String? fontFamily,
    String? headerStyle,
    String? logoPosition,
    bool? showLogo,
    bool? showBusinessAddress,
    bool? showBusinessPhone,
    bool? showBusinessEmail,
    bool? showTaxId,
    bool? showInvoiceNumber,
    bool? showDueDate,
    bool? showPaymentTerms,
    String? headerTagline,
    String? footerNote,
    String? paymentTerms,
    String? thankYouMessage,
    List<String>? preferredPaymentMethods,
    Map<String, String>? paymentMethodDetails,
    List<String>? customFields,
    String? colDescription,
    String? colQty,
    String? colRate,
    String? colAmount,
  }) {
    return InvoiceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      primaryColor: normalizeHexColor(
        primaryColor ?? this.primaryColor,
        fallback: '#1565C0',
      ),
      accentColor: normalizeHexColor(
        accentColor ?? this.accentColor,
        fallback: '#0D47A1',
      ),
      fontFamily: fontFamily ?? this.fontFamily,
      headerStyle: normalizeHeaderStyle(headerStyle ?? this.headerStyle),
      logoPosition: normalizeLogoPosition(logoPosition ?? this.logoPosition),
      showLogo: showLogo ?? this.showLogo,
      showBusinessAddress: showBusinessAddress ?? this.showBusinessAddress,
      showBusinessPhone: showBusinessPhone ?? this.showBusinessPhone,
      showBusinessEmail: showBusinessEmail ?? this.showBusinessEmail,
      showTaxId: showTaxId ?? this.showTaxId,
      showInvoiceNumber: showInvoiceNumber ?? this.showInvoiceNumber,
      showDueDate: showDueDate ?? this.showDueDate,
      showPaymentTerms: showPaymentTerms ?? this.showPaymentTerms,
      headerTagline: headerTagline ?? this.headerTagline,
      footerNote: footerNote ?? this.footerNote,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      preferredPaymentMethods: normalizePaymentMethods(
        preferredPaymentMethods ?? this.preferredPaymentMethods,
      ),
      paymentMethodDetails: normalizePaymentMethodDetails(
        paymentMethodDetails ?? this.paymentMethodDetails,
      ),
      customFields: customFields ?? this.customFields,
      colDescription: colDescription ?? this.colDescription,
      colQty: colQty ?? this.colQty,
      colRate: colRate ?? this.colRate,
      colAmount: colAmount ?? this.colAmount,
    );
  }
}
