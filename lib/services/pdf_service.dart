import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_profile.dart';
import '../models/invoice_template.dart';
import 'template_service.dart';

/// Professional PDF invoice/quote generator.
class PdfService {
  // ─── Colour palette ────────────────────────────────────────────────────────
  static const _darkText = PdfColor.fromInt(0xFF111827);
  static const _midGrey = PdfColor.fromInt(0xFF6B7280);
  static const _lightBorder = PdfColor.fromInt(0xFFD1D5DB);
  static const _white = PdfColors.white;
  static const _altRowBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _softPanel = PdfColor.fromInt(0xFFF8FAFC);
  static const double _fontScale = 1.08;
  static const double _logoScale = 1.2;
  static const double _modernLogoSlotWidth = 122;
  static const double _space1 = 4;
  static const double _space2 = 8;
  static const double _space3 = 12;
  static const double _space4 = 16;
  static const double _tableOuterBorder = 0.65;
  static const double _tableInnerBorder = 0.35;
  static const double _totalsLabelWidth = 170;
  static const double _totalsValueWidth = 120;

  /// Build the PDF bytes without printing — used for previews.
  ///
  /// Uses the same full document builder as [generateAndPrint], ensuring
  /// that the preview exactly matches the exported/printed PDF.
  static Future<Uint8List> buildPdfBytes({
    required Map<String, dynamic> jobData,
    required BusinessProfile profile,
    InvoiceTemplate? template,
  }) async {
    return _buildFullDocument(
      jobData: jobData,
      profile: profile,
      template: template,
    );
  }

  /// Generate a PDF invoice/quote and open the system print/share dialog.
  ///
  /// Builds the full document via [_buildFullDocument] then delegates to
  /// the platform share/print sheet.
  static Future<void> generateAndPrint({
    required Map<String, dynamic> jobData,
    required BusinessProfile profile,
    InvoiceTemplate? template,
  }) async {
    final bytes = await _buildFullDocument(
      jobData: jobData,
      profile: profile,
      template: template,
    );

    // ── Derive file name ──────────────────────────────────────────────────
    final rawType =
        (jobData['type']?.toString() ?? 'invoice').trim().toLowerCase();
    final isQuote =
        rawType == 'quote' || rawType == 'quotation' || rawType == 'estimate';
    final clientName = _pdfSafeText(
            (jobData['clientName'] ?? jobData['client_name'] ?? 'Customer')
                .toString())
        .trim();
    final safeClientName = clientName.isEmpty ? 'Customer' : clientName;
    final fileClient = _sanitizeFileSegment(safeClientName);
    final invoiceNumber = jobData['invoice_number']?.toString() ??
        jobData['invoiceNumber']?.toString();
    final prefix = isQuote ? 'QTE' : 'INV';
    final numberPart = (invoiceNumber != null && invoiceNumber.isNotEmpty)
        ? invoiceNumber
        : prefix;
    final fileName = '${numberPart}_$fileClient.pdf'
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .toLowerCase();

    // ── Share / Print ─────────────────────────────────────────────────────
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      return;
    }
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED DOCUMENT BUILDER — single source of truth for both preview & export
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds the complete professional PDF document and returns the raw bytes.
  ///
  /// This is the **single source of truth** for the invoice/quote layout.
  /// Both [buildPdfBytes] (preview) and [generateAndPrint] (export) call this.
  static Future<Uint8List> _buildFullDocument({
    required Map<String, dynamic> jobData,
    required BusinessProfile profile,
    InvoiceTemplate? template,
  }) async {
    final InvoiceTemplate tmpl =
        template ?? await TemplateService.loadTemplate();

    // ── Dates ───────────────────────────────────────────────────────────────
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final dueDays = (jobData['default_due_days'] as int?) ?? 14;
    final dueDateStr = dueDays == 0
        ? 'Due on receipt'
        : DateFormat('MMMM d, yyyy').format(now.add(Duration(days: dueDays)));

    // ── Document type ───────────────────────────────────────────────────────
    final rawType =
        (jobData['type']?.toString() ?? 'invoice').trim().toLowerCase();
    final isQuote =
        rawType == 'quote' || rawType == 'quotation' || rawType == 'estimate';
    final docLabel = isQuote ? 'QUOTE' : 'INVOICE';

    // ── Identifiers ─────────────────────────────────────────────────────────
    final rawId = jobData['id']?.toString() ?? '';
    final rawInvoiceNumber =
        (jobData['invoiceNumber'] ?? jobData['invoice_number'] ?? '')
            .toString()
            .trim();
    final invoiceSequence = int.tryParse(
      (jobData['invoiceSequence'] ?? jobData['invoice_sequence'] ?? '')
          .toString(),
    );
    final documentNum = _resolveDocumentNumber(
      explicitNumber: rawInvoiceNumber,
      sequence: invoiceSequence,
      fallbackId: rawId,
    );
    final clientName = _pdfSafeText(
            (jobData['clientName'] ?? jobData['client_name'] ?? 'Customer')
                .toString())
        .trim();
    final safeClientName = clientName.isEmpty ? 'Customer' : clientName;
    final clientAddress = _pdfSafeText(
            (jobData['clientAddress'] ?? jobData['client_address'] ?? '')
                .toString())
        .trim();
    final clientAddressLines = _formatAddressLines(clientAddress);
    final clientPhone = _pdfSafeText(
            (jobData['clientPhone'] ?? jobData['client_phone'] ?? '')
                .toString())
        .trim();
    final clientEmail = _pdfSafeText(
            (jobData['clientEmail'] ?? jobData['client_email'] ?? '')
                .toString())
        .trim();
    final description =
        _pdfSafeText(jobData['description']?.toString() ?? '').trim();

    // ── Currency ────────────────────────────────────────────────────────────
    final cs = _pdfSafeText(profile.currencySymbol).trim().isEmpty
        ? '\$'
        : _pdfSafeText(profile.currencySymbol).trim();

    // ── Labour ──────────────────────────────────────────────────────────────
    final laborHours = double.tryParse(
            (jobData['laborHours'] ?? jobData['labor_hours'] ?? '0')
                .toString()) ??
        0.0;
    final hourlyRate = double.tryParse((jobData['hourlyRateAtTime'] ??
                jobData['hourly_rate_at_time'] ??
                profile.hourlyRate)
            .toString()) ??
        profile.hourlyRate;
    final laborTotal = laborHours * hourlyRate;

    // ── Materials ───────────────────────────────────────────────────────────
    double materialsTotal = 0.0;
    final rawMaterials = jobData['materials'] as List? ?? const [];
    final materials = rawMaterials
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    for (final m in materials) {
      materialsTotal += (double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0);
    }

    // ── Totals ──────────────────────────────────────────────────────────────
    final subtotal = laborTotal + materialsTotal;
    final taxRate = double.tryParse(
            (jobData['taxRateAtTime'] ?? jobData['tax_rate_at_time'] ?? '')
                .toString()) ??
        profile.taxRate;
    final taxAmount = subtotal * (taxRate / 100);
    final grandTotal = subtotal + taxAmount;

    // ── Payment state ────────────────────────────────────────────────────────
    final amountPaid = double.tryParse(
            (jobData['amountPaid'] ?? jobData['amount_paid'] ?? '0')
                .toString()) ??
        0.0;
    final balanceDue = (grandTotal - amountPaid).clamp(0.0, double.infinity);
    final hasPayments = amountPaid > 0.01;

    // ── Cancelled / superseded state ─────────────────────────────────────────
    final rawStatus =
        (jobData['status']?.toString() ?? '').trim().toLowerCase();
    final isCancelled = rawStatus == 'cancelled';

    // ── Logo ────────────────────────────────────────────────────────────────
    pw.MemoryImage? logoImage;
    if (tmpl.showLogo && tmpl.logoUrl != null && tmpl.logoUrl!.isNotEmpty) {
      try {
        final bytes = await TemplateService.downloadLogoBytes(tmpl.logoUrl!);
        if (bytes != null) logoImage = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint('PdfService: logo download failed: $e');
      }
    }

    // ── Template colours ────────────────────────────────────────────────────
    final userPrimary = _hexToPdf(tmpl.primaryColor);
    final userAccent = _hexToPdf(tmpl.accentColor);

    // ── Build line items ────────────────────────────────────────────────────
    final lineItems = <_LineItem>[];
    if (laborHours > 0 || materials.isEmpty) {
      // Use job description for the labor line item; fall back to 'Labour'
      final laborDesc = description.isNotEmpty ? description : 'Labour';
      lineItems.add(_LineItem(
        desc: laborDesc,
        qty: laborHours,
        qtyDisplay: laborHours > 0 ? '${_formatQty(laborHours)} hrs' : '-',
        rate: hourlyRate,
        amount: laborTotal,
      ));
    }
    for (final m in materials) {
      final totalCost = double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0;
      final qty = (m['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = (m['unitPrice'] as num?)?.toDouble() ??
          (qty > 0 ? totalCost / qty : totalCost);
      final itemName = (m['item']?.toString().trim().isNotEmpty ?? false)
          ? _pdfSafeText(m['item'].toString()).trim()
          : (m['name']?.toString().trim().isNotEmpty ?? false)
              ? _pdfSafeText(m['name'].toString()).trim()
              : 'Material';
      lineItems.add(_LineItem(
        desc: itemName,
        qty: qty.toDouble(),
        qtyDisplay: _formatQty(qty.toDouble()),
        rate: unitPrice,
        amount: totalCost,
      ));
    }

    // ── Footer/payment text ────────────────────────────────────────────────
    final paymentTerms = _pdfSafeText(tmpl.paymentTerms).trim();
    final thankYou = _pdfSafeText(tmpl.thankYouMessage).trim();
    final footerNote = _pdfSafeText(tmpl.footerNote).trim();
    final securePaymentUrl =
        (jobData['securePaymentUrl'] ?? jobData['payment_checkout_url'] ?? '')
            .toString()
            .trim();
    final securePaymentProvider = _pdfSafeText(
            (jobData['securePaymentProvider'] ??
                    jobData['payment_provider'] ??
                    '')
                .toString())
        .trim();
    final securePaymentMethods = _coerceStringList(
      jobData['securePaymentMethods'] ?? jobData['secure_payment_methods'],
    );
    final pdfSafeSecurePaymentUrl = _pdfSafePaymentUrl(securePaymentUrl);
    final preferredPaymentMethods = InvoiceTemplate.normalizePaymentMethods(
      jobData['preferredPaymentMethods'] ??
          jobData['preferred_payment_methods'] ??
          tmpl.preferredPaymentMethods,
    );
    final paymentMethodDetails = InvoiceTemplate.normalizePaymentMethodDetails(
      jobData['paymentMethodDetails'] ??
          jobData['payment_method_details'] ??
          tmpl.paymentMethodDetails,
    );
    final hasManualPaymentMethods = preferredPaymentMethods.any((methodId) {
      final detail = _sanitizePaymentMethodDetail(
        methodId,
        paymentMethodDetails[methodId] ?? '',
      );
      return detail.isNotEmpty;
    });
    final fontFamily = _resolveFontFamily(
      requestedFontFamily: tmpl.fontFamily,
    );

    final pdf = pw.Document();
    final pdfTheme = await _themeForFont(fontFamily);
    final showPaymentSection = !isQuote &&
        ((tmpl.showPaymentTerms && paymentTerms.isNotEmpty) ||
            pdfSafeSecurePaymentUrl.isNotEmpty ||
            hasManualPaymentMethods);
    final footerWidget = _buildFooterNotes(
      thankYou: thankYou,
      footerNote: footerNote,
      isQuote: isQuote,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          // Use Letter (612×792 pt) — fits US Letter printers natively and
          // is only marginally shorter than A4 (842 pt). A4 printers scale
          // Letter up safely; Letter printers clip A4 at the bottom.
          // Top margin 50 pt keeps content clear of the non-printable zone
          // on both formats.
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.fromLTRB(34, 50, 34, 30),
          theme: pdfTheme,
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _white),
          ),
        ),
        footer: (_) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              footerWidget,
              if (!profile.isPro) pw.SizedBox(height: 4),
              if (!profile.isPro)
                pw.Center(
                  child: pw.Text(
                    'Generated by Tradesman Ledger - Streamlining your business.',
                    style: pw.TextStyle(
                      fontSize: _fs(8),
                      color: _midGrey,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
            ],
          );
        },
        build: (pw.Context ctx) => [
          _buildHeader(
            profile: profile,
            tmpl: tmpl,
            logoImage: logoImage,
            docLabel: docLabel,
            documentNum: documentNum,
            dateStr: dateStr,
            userPrimary: userPrimary,
            userAccent: userAccent,
          ),
          if (isCancelled) ...[
            pw.SizedBox(height: _space2),
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFEF2F2),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFDC2626), width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'SUPERSEDED \u2014 This invoice has been replaced by a revised version. Do not pay.',
                style: pw.TextStyle(
                  fontSize: _fs(9),
                  color: const PdfColor.fromInt(0xFFDC2626),
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: _space4),
          _buildBillToRow(
            clientName: safeClientName,
            clientAddressLines: clientAddressLines,
            clientPhone: clientPhone,
            clientEmail: clientEmail,
            dueDate: dueDateStr,
            isQuote: isQuote,
            showDueDate: tmpl.showDueDate,
            userPrimary: userPrimary,
            userAccent: userAccent,
          ),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: _space2),
            _buildJobDescription(
              description: description,
              userPrimary: userPrimary,
            ),
          ],
          pw.SizedBox(height: _space3),
          _buildLineItemsTable(
            items: lineItems,
            cs: cs,
            tmpl: tmpl,
            userPrimary: userPrimary,
          ),
          pw.SizedBox(height: _space1),
          _buildTotals(
            subtotal: subtotal,
            taxAmount: taxAmount,
            taxRate: taxRate,
            grandTotal: grandTotal,
            amountPaid: amountPaid,
            balanceDue: balanceDue,
            hasPayments: hasPayments,
            cs: cs,
            totalLabel: isQuote ? 'TOTAL ESTIMATE' : 'TOTAL',
            isQuote: isQuote,
            userPrimary: userPrimary,
          ),
          if (showPaymentSection) pw.SizedBox(height: _space2),
          if (showPaymentSection)
            _buildPaymentInstructions(
              paymentTerms: paymentTerms,
              includeGeneralPaymentTerms: tmpl.showPaymentTerms,
              isQuote: isQuote,
              userPrimary: userPrimary,
              securePaymentUrl: securePaymentUrl,
              securePaymentProvider: securePaymentProvider,
              securePaymentMethods: securePaymentMethods,
              preferredPaymentMethods: preferredPaymentMethods,
              paymentMethodDetails: paymentMethodDetails,
            ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    required String docLabel,
    required String documentNum,
    required String dateStr,
    required PdfColor userPrimary,
    required PdfColor userAccent,
  }) {
    switch (InvoiceTemplate.normalizeHeaderStyle(tmpl.headerStyle)) {
      case InvoiceTemplate.headerStyleClassic:
        return _buildHeaderClassic(
          profile: profile,
          tmpl: tmpl,
          logoImage: logoImage,
          docLabel: docLabel,
          documentNum: documentNum,
          dateStr: dateStr,
          userPrimary: userPrimary,
          userAccent: userAccent,
        );
      case InvoiceTemplate.headerStyleStatement:
        return _buildHeaderStatement(
          profile: profile,
          tmpl: tmpl,
          logoImage: logoImage,
          docLabel: docLabel,
          documentNum: documentNum,
          dateStr: dateStr,
          userPrimary: userPrimary,
          userAccent: userAccent,
        );
      case InvoiceTemplate.headerStyleModern:
      default:
        return _buildHeaderModern(
          profile: profile,
          tmpl: tmpl,
          logoImage: logoImage,
          docLabel: docLabel,
          documentNum: documentNum,
          dateStr: dateStr,
          userPrimary: userPrimary,
          userAccent: userAccent,
        );
    }
  }

  static pw.Widget _buildHeaderModern({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    required String docLabel,
    required String documentNum,
    required String dateStr,
    required PdfColor userPrimary,
    required PdfColor userAccent,
  }) {
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(tmpl.logoPosition);
    final logo = _buildHeaderLogoSlot(
      tmpl: tmpl,
      logoImage: logoImage,
      imageHeight: _logoSize(46),
    );
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _lightBorder, width: 0.45),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 2, color: userPrimary),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 12, 0, 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null &&
                    logoPosition == InvoiceTemplate.logoPositionLeft) ...[
                  pw.SizedBox(width: _modernLogoSlotWidth, child: logo),
                  pw.SizedBox(width: 14),
                ],
                pw.Expanded(
                  child: _buildBusinessInfo(
                    profile: profile,
                    tmpl: tmpl,
                    nameColor: _darkText,
                  ),
                ),
                if (logo != null &&
                    logoPosition == InvoiceTemplate.logoPositionCenter) ...[
                  pw.SizedBox(width: 14),
                  pw.SizedBox(width: _modernLogoSlotWidth, child: logo),
                ],
                pw.SizedBox(width: 14),
                pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        docLabel,
                        style: pw.TextStyle(
                          fontSize: _fs(24),
                          fontWeight: pw.FontWeight.bold,
                          color: userPrimary,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(width: 140, height: 1, color: _lightBorder),
                      pw.SizedBox(height: 8),
                      if (tmpl.showInvoiceNumber)
                        _metaRow('$docLabel #', documentNum, alignEnd: true),
                      _metaRow('Date', dateStr, alignEnd: true),
                    ],
                  ),
                ),
                if (logo != null &&
                    logoPosition == InvoiceTemplate.logoPositionRight) ...[
                  pw.SizedBox(width: 14),
                  pw.SizedBox(width: _modernLogoSlotWidth, child: logo),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderClassic({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    required String docLabel,
    required String documentNum,
    required String dateStr,
    required PdfColor userPrimary,
    required PdfColor userAccent,
  }) {
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(tmpl.logoPosition);
    final logo = _buildLogoBox(
      tmpl: tmpl,
      logoImage: logoImage,
      height: _logoSize(40),
    );
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _lightBorder, width: 0.45),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 2, color: userPrimary),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 12, 0, 12),
            child: pw.Column(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            docLabel,
                            style: pw.TextStyle(
                              fontSize: _fs(22),
                              fontWeight: pw.FontWeight.bold,
                              color: userPrimary,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(width: 62, height: 2, color: userAccent),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Container(
                      width: 192,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: _white,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _lightBorder, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (tmpl.showInvoiceNumber)
                            _metaRow('$docLabel #', documentNum),
                          _metaRow('Date', dateStr),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Container(height: 1, color: _lightBorder),
                pw.SizedBox(height: 10),
                if (logo != null &&
                    logoPosition == InvoiceTemplate.logoPositionCenter) ...[
                  pw.Center(child: logo),
                  pw.SizedBox(height: 10),
                ],
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null &&
                        logoPosition == InvoiceTemplate.logoPositionLeft) ...[
                      logo,
                      pw.SizedBox(width: 10),
                    ],
                    pw.Expanded(
                      child: _buildBusinessInfo(
                        profile: profile,
                        tmpl: tmpl,
                        nameColor: _darkText,
                      ),
                    ),
                    if (logo != null &&
                        logoPosition == InvoiceTemplate.logoPositionRight) ...[
                      pw.SizedBox(width: 10),
                      logo,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderStatement({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    required String docLabel,
    required String documentNum,
    required String dateStr,
    required PdfColor userPrimary,
    required PdfColor userAccent,
  }) {
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(tmpl.logoPosition);
    final logo = _buildLogoBox(
      tmpl: tmpl,
      logoImage: logoImage,
      height: _logoSize(48),
    );
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _lightBorder, width: 0.45),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 12, 0, 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null) ...[
                        pw.Align(
                          alignment:
                              logoPosition == InvoiceTemplate.logoPositionRight
                                  ? pw.Alignment.centerRight
                                  : logoPosition ==
                                          InvoiceTemplate.logoPositionCenter
                                      ? pw.Alignment.center
                                      : pw.Alignment.centerLeft,
                          child: logo,
                        ),
                        pw.SizedBox(height: 8),
                      ],
                      _buildBusinessInfo(
                        profile: profile,
                        tmpl: tmpl,
                        nameColor: _darkText,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      docLabel,
                      style: pw.TextStyle(
                        fontSize: _fs(21),
                        fontWeight: pw.FontWeight.bold,
                        color: userPrimary,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(width: 70, height: 3, color: userPrimary),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            color: _softPanel,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Row(
              children: [
                if (tmpl.showInvoiceNumber) ...[
                  pw.Expanded(
                    child: _inlineMetaBox('$docLabel #', documentNum),
                  ),
                  pw.SizedBox(width: 8),
                ],
                pw.Expanded(
                  child: _inlineMetaBox('Date', dateStr, alignEnd: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget? _buildLogoBox({
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    double height = 52,
  }) {
    if (!tmpl.showLogo || logoImage == null) return null;
    return pw.Image(
      logoImage,
      height: height,
      fit: pw.BoxFit.contain,
    );
  }

  static pw.Widget? _buildHeaderLogoSlot({
    required InvoiceTemplate tmpl,
    required pw.MemoryImage? logoImage,
    required double imageHeight,
  }) {
    if (!tmpl.showLogo || logoImage == null) return null;
    return _buildLogoBox(tmpl: tmpl, logoImage: logoImage, height: imageHeight);
  }

  static pw.Widget _buildBusinessInfo({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
    required PdfColor nameColor,
  }) {
    final tagline = _pdfSafeText(tmpl.headerTagline).trim();
    final businessName = _pdfSafeText(profile.businessName).trim();
    final detailLines = _businessDetailLines(profile: profile, tmpl: tmpl);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          businessName.isEmpty ? 'Business' : businessName,
          style: pw.TextStyle(
            fontSize: _fs(14),
            fontWeight: pw.FontWeight.bold,
            color: nameColor,
          ),
        ),
        if (tagline.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              tagline,
              style: pw.TextStyle(fontSize: _fs(9), color: _midGrey),
            ),
          ),
        if (detailLines.isNotEmpty) pw.SizedBox(height: 5),
        ...detailLines.asMap().entries.map(
              (entry) => pw.Padding(
                padding: pw.EdgeInsets.only(top: entry.key == 0 ? 0 : 2),
                child: pw.Text(
                  entry.value,
                  style: pw.TextStyle(
                    fontSize: _fs(9),
                    color: _midGrey,
                    lineSpacing: 1.2,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  static List<String> _businessDetailLines({
    required BusinessProfile profile,
    required InvoiceTemplate tmpl,
  }) {
    final lines = <String>[];

    void addIf(bool enabled, String? value) {
      final trimmed = _pdfSafeText(value ?? '').trim();
      if (enabled && trimmed.isNotEmpty) lines.add(trimmed);
    }

    if (tmpl.showBusinessAddress) {
      lines.addAll(_formatAddressLines(profile.businessAddress ?? ''));
    }
    addIf(tmpl.showBusinessPhone, profile.businessPhone);
    addIf(tmpl.showBusinessEmail, profile.businessEmail);

    if (tmpl.showTaxId) {
      final taxId = _pdfSafeText(profile.taxId ?? '').trim();
      if (taxId.isNotEmpty) lines.add('Tax ID: $taxId');
    }

    for (final field in tmpl.customFields) {
      final trimmed = _pdfSafeText(field).trim();
      if (trimmed.isNotEmpty) lines.add(trimmed);
    }

    return lines;
  }

  static pw.Widget _metaRow(String label, String value,
      {bool alignEnd = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        textAlign: alignEnd ? pw.TextAlign.right : pw.TextAlign.left,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontSize: _fs(8.5), color: _midGrey),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: _fs(8.5),
                color: _darkText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _inlineMetaBox(String label, String value,
      {bool alignEnd = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _lightBorder, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment:
            alignEnd ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: _fs(8),
              color: _midGrey,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            textAlign: alignEnd ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: _fs(9),
              fontWeight: pw.FontWeight.bold,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — BILL TO / PAYMENT DUE
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildBillToRow({
    required String clientName,
    required List<String> clientAddressLines,
    required String clientPhone,
    required String clientEmail,
    required String dueDate,
    required bool isQuote,
    required bool showDueDate,
    required PdfColor userPrimary,
    required PdfColor userAccent,
  }) {
    final clientDetailLines = <String>[
      ...clientAddressLines,
      if (clientPhone.isNotEmpty) clientPhone,
      if (clientEmail.isNotEmpty) clientEmail,
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isQuote ? 'PREPARED FOR:' : 'BILL TO:',
                style: pw.TextStyle(
                  fontSize: _fs(9),
                  fontWeight: pw.FontWeight.bold,
                  color: userPrimary,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                clientName,
                style: pw.TextStyle(
                  fontSize: _fs(12),
                  fontWeight: pw.FontWeight.bold,
                  color: _darkText,
                ),
              ),
              if (clientDetailLines.isNotEmpty) pw.SizedBox(height: 3),
              ...clientDetailLines.asMap().entries.map(
                    (entry) => pw.Padding(
                      padding: pw.EdgeInsets.only(top: entry.key == 0 ? 0 : 2),
                      child: pw.Text(
                        entry.value,
                        style: pw.TextStyle(fontSize: _fs(9), color: _midGrey),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        if (showDueDate)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                isQuote ? 'VALID UNTIL:' : 'PAYMENT DUE:',
                style: pw.TextStyle(
                  fontSize: _fs(9),
                  fontWeight: pw.FontWeight.bold,
                  color: userPrimary,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                dueDate,
                style: pw.TextStyle(
                  fontSize: _fs(12),
                  fontWeight: pw.FontWeight.bold,
                  color: userAccent,
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildJobDescription({
    required String description,
    required PdfColor userPrimary,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _softPanel,
        border: pw.Border(
          left: pw.BorderSide(color: userPrimary, width: 1.4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'JOB DESCRIPTION',
            style: pw.TextStyle(
              fontSize: _fs(8.5),
              fontWeight: pw.FontWeight.bold,
              color: userPrimary,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            description,
            style: pw.TextStyle(
              fontSize: _fs(9.5),
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — LINE ITEMS TABLE
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildLineItemsTable({
    required List<_LineItem> items,
    required String cs,
    required InvoiceTemplate tmpl,
    required PdfColor userPrimary,
  }) {
    final borderColor = _mix(userPrimary, _white, 0.78);
    final qtyHeader = _normalizedQtyHeader(tmpl.colQty);
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: _tableOuterBorder),
        bottom: pw.BorderSide(color: borderColor, width: _tableOuterBorder),
        left: pw.BorderSide(color: borderColor, width: _tableOuterBorder),
        right: pw.BorderSide(color: borderColor, width: _tableOuterBorder),
        horizontalInside:
            pw.BorderSide(color: _lightBorder, width: _tableInnerBorder),
        verticalInside:
            pw.BorderSide(color: _lightBorder, width: _tableInnerBorder),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FixedColumnWidth(56),
        2: pw.FixedColumnWidth(92),
        3: pw.FixedColumnWidth(92),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: userPrimary),
          children: [
            _tableHeaderCell(
              _pdfSafeText(tmpl.colDescription),
              align: pw.TextAlign.left,
            ),
            _tableHeaderCell(qtyHeader, align: pw.TextAlign.center),
            _tableHeaderCell(_pdfSafeText(tmpl.colRate),
                align: pw.TextAlign.center),
            _tableHeaderCell(_pdfSafeText(tmpl.colAmount),
                align: pw.TextAlign.center),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isOdd ? _altRowBg : _white,
            ),
            children: [
              _tableBodyCell(item.desc, align: pw.TextAlign.left),
              _tableBodyCell(
                item.qtyDisplay ?? _formatQty(item.qty),
                align: pw.TextAlign.center,
              ),
              _tableBodyCell(
                _formatMoney(cs, item.rate),
                align: pw.TextAlign.center,
                numeric: true,
              ),
              _tableBodyCell(
                _formatMoney(cs, item.amount),
                align: pw.TextAlign.center,
                bold: true,
                numeric: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: _space2),
      child: pw.Text(
        _pdfSafeText(text).toUpperCase(),
        textAlign: align,
        style: pw.TextStyle(
          fontSize: _fs(9),
          fontWeight: pw.FontWeight.bold,
          color: _white,
        ),
      ),
    );
  }

  static pw.Widget _tableBodyCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    bool numeric = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: _space2),
      child: pw.Text(
        _pdfSafeText(text),
        textAlign: align,
        style: pw.TextStyle(
          fontSize: _fs(10),
          color: _darkText,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          letterSpacing: numeric ? 0.15 : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — TOTALS
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildTotals({
    required double subtotal,
    required double taxAmount,
    required double taxRate,
    required double grandTotal,
    required double amountPaid,
    required double balanceDue,
    required bool hasPayments,
    required String cs,
    required String totalLabel,
    required bool isQuote,
    required PdfColor userPrimary,
  }) {
    final taxLabel =
        taxRate > 0 ? 'Tax (${taxRate.toStringAsFixed(0)}%)' : 'Tax';

    // Determine the "hero" bottom line — either TOTAL (when no payments)
    // or BALANCE DUE (when partial payments exist).
    final showPaymentBreakdown = hasPayments && !isQuote;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: _totalsLabelWidth + _totalsValueWidth + _space2,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.SizedBox(height: _space2),
            _totalsRow(
              label: 'Subtotal',
              value: _formatMoney(cs, subtotal),
              labelColor: _midGrey,
              valueColor: _darkText,
              valueIsMoney: true,
            ),
            pw.SizedBox(height: _space1),
            _totalsRow(
              label: taxLabel,
              value: _formatMoney(cs, taxAmount),
              labelColor: _midGrey,
              valueColor: _darkText,
              valueIsMoney: true,
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 1, color: _lightBorder),
            pw.SizedBox(height: 6),
            _totalsRow(
              label: totalLabel,
              value: _formatMoney(cs, grandTotal),
              labelColor: showPaymentBreakdown ? _midGrey : userPrimary,
              valueColor: showPaymentBreakdown ? _darkText : userPrimary,
              bold: !showPaymentBreakdown,
              fontSize: showPaymentBreakdown ? 10 : 12,
              valueIsMoney: true,
            ),
            // Payment breakdown — only shown when payments have been recorded
            if (showPaymentBreakdown) ...[
              pw.SizedBox(height: _space1),
              _totalsRow(
                label: 'Amount Paid',
                value: '- ${_formatMoney(cs, amountPaid)}',
                labelColor: _midGrey,
                valueColor: const PdfColor.fromInt(0xFF16A34A), // green
                valueIsMoney: true,
              ),
              pw.SizedBox(height: 6),
              pw.Container(height: 1, color: _lightBorder),
              pw.SizedBox(height: 6),
              _totalsRow(
                label: balanceDue <= 0.01 ? 'PAID IN FULL' : 'BALANCE DUE',
                value: _formatMoney(cs, balanceDue),
                labelColor: userPrimary,
                valueColor: userPrimary,
                bold: true,
                fontSize: 12,
                valueIsMoney: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalsRow({
    required String label,
    required String value,
    required PdfColor labelColor,
    required PdfColor valueColor,
    bool bold = false,
    double fontSize = 10,
    bool valueIsMoney = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: _totalsLabelWidth,
          child: pw.Text(
            _pdfSafeText(label),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: _fs(fontSize),
              color: labelColor,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.SizedBox(width: _space2),
        pw.SizedBox(
          width: _totalsValueWidth,
          child: pw.Text(
            _pdfSafeText(value),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: _fs(fontSize + (bold ? 1 : 0)),
              color: valueColor,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              letterSpacing: valueIsMoney ? 0.18 : null,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5 — PAYMENT INSTRUCTIONS + FOOTER NOTES
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildPaymentInstructions({
    required String paymentTerms,
    required bool includeGeneralPaymentTerms,
    required bool isQuote,
    required PdfColor userPrimary,
    required String securePaymentUrl,
    required String securePaymentProvider,
    required List<String> securePaymentMethods,
    required List<String> preferredPaymentMethods,
    required Map<String, String> paymentMethodDetails,
  }) {
    if (isQuote) {
      return pw.SizedBox.shrink();
    }

    final lines = <String>[];
    if (includeGeneralPaymentTerms) {
      for (final line in paymentTerms.split(RegExp(r'\r?\n'))) {
        final trimmed = _sanitizeInstructionText(line);
        if (trimmed.isNotEmpty) lines.add(trimmed);
      }
    }

    final normalizedMethodIds =
        InvoiceTemplate.normalizePaymentMethods(preferredPaymentMethods);
    final stripeEnabled =
        normalizedMethodIds.contains(InvoiceTemplate.paymentMethodStripe);

    final manualMethodIds = normalizedMethodIds.where((methodId) {
      if (methodId == InvoiceTemplate.paymentMethodStripe) return false;
      final detail = _sanitizePaymentMethodDetail(
        methodId,
        paymentMethodDetails[methodId] ?? '',
      );
      return detail.isNotEmpty;
    }).toList();

    final pdfSafeSecurePaymentUrl = _pdfSafePaymentUrl(securePaymentUrl);
    final hasSecurePay = pdfSafeSecurePaymentUrl.isNotEmpty;
    final effectiveStripeEnabled = stripeEnabled || hasSecurePay;
    if (lines.isEmpty && !hasSecurePay && manualMethodIds.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final providerLabel = securePaymentProvider.trim().isEmpty
        ? 'Secure Checkout'
        : '${_titleCaseWords(securePaymentProvider)} Checkout';
    final qrPaymentUrl = _qrSafePaymentUrl(pdfSafeSecurePaymentUrl);
    final normalizedProvider = securePaymentProvider.trim().toLowerCase();
    final methodsLabel =
        (normalizedProvider.contains('stripe') || effectiveStripeEnabled)
            ? 'Credit or debit card, Apple Pay, Google Pay, bank transfer'
            : securePaymentMethods.isEmpty
                ? null
                : securePaymentMethods.map(_pdfSafeText).join(', ');
    final ruleColor = _mix(userPrimary, _white, 0.78);
    final manualMethodLabels = manualMethodIds.map((methodId) {
      final methodLabel = InvoiceTemplate.paymentMethodLabels[methodId] ??
          _titleCaseWords(methodId.replaceAll('_', ' '));
      return _pdfSafeText(methodLabel);
    }).toList();
    final manualMethodDetails = manualMethodIds
        .map((methodId) {
          final methodLabel = InvoiceTemplate.paymentMethodLabels[methodId] ??
              _titleCaseWords(methodId.replaceAll('_', ' '));
          final detail = _sanitizePaymentMethodDetail(
            methodId,
            paymentMethodDetails[methodId] ?? '',
          );
          final compactDetail = detail
              .split(RegExp(r'\r?\n'))
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .join(' | ');
          if (compactDetail.isEmpty) return '';
          return '${_pdfSafeText(methodLabel)}: ${_pdfSafeText(compactDetail)}';
        })
        .where((line) => line.isNotEmpty)
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 0.6, color: ruleColor),
        pw.SizedBox(height: 4),
        pw.Text(
          isQuote ? 'Notes' : 'Payment Instructions',
          style: pw.TextStyle(
            fontSize: _fs(9.3),
            fontWeight: pw.FontWeight.bold,
            color: userPrimary,
          ),
        ),
        pw.SizedBox(height: 3),
        if (hasSecurePay) ...[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 62,
                height: 62,
                child: pw.BarcodeWidget(
                  data: qrPaymentUrl,
                  barcode: pw.Barcode.qrCode(),
                  drawText: false,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Secure online payment ($providerLabel)',
                      style: pw.TextStyle(
                        fontSize: _fs(8.2),
                        fontWeight: pw.FontWeight.bold,
                        color: userPrimary,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.UrlLink(
                      destination: pdfSafeSecurePaymentUrl,
                      child: pw.Text(
                        'Click here to pay securely',
                        style: pw.TextStyle(
                          fontSize: _fs(8.05),
                          color: userPrimary,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (methodsLabel != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Accepted: $methodsLabel',
                        style: pw.TextStyle(
                          fontSize: _fs(7.85),
                          color: _midGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (manualMethodIds.isNotEmpty || lines.isNotEmpty)
            pw.SizedBox(height: 4),
        ],
        if (manualMethodIds.isNotEmpty) ...[
          pw.Text(
            'Other payment options:',
            style: pw.TextStyle(
              fontSize: _fs(7.75),
              fontWeight: pw.FontWeight.bold,
              color: userPrimary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Wrap(
            spacing: 5,
            runSpacing: 4,
            children: manualMethodLabels
                .map(
                  (label) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _altRowBg,
                      border: pw.Border.all(color: _lightBorder, width: 0.4),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: _fs(7.25),
                        color: _darkText,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (manualMethodDetails.isNotEmpty) pw.SizedBox(height: 3),
          ...manualMethodDetails.asMap().entries.map(
                (entry) => pw.Padding(
                  padding: pw.EdgeInsets.only(top: entry.key == 0 ? 0 : 1.6),
                  child: pw.Text(
                    entry.value,
                    style: pw.TextStyle(
                      fontSize: _fs(7.75),
                      color: _midGrey,
                      lineSpacing: 1.1,
                    ),
                  ),
                ),
              ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Security: Confirm payment details by calling the business phone listed on this invoice. We never request payment changes by text or social media.',
            style: pw.TextStyle(
              fontSize: _fs(7.2),
              color: _midGrey,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (lines.isNotEmpty) pw.SizedBox(height: 4),
        ],
        if (lines.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Additional Terms',
                style: pw.TextStyle(
                  fontSize: _fs(7.8),
                  fontWeight: pw.FontWeight.bold,
                  color: userPrimary,
                ),
              ),
              pw.SizedBox(height: 2),
              ...lines.asMap().entries.map(
                    (entry) => pw.Padding(
                      padding:
                          pw.EdgeInsets.only(top: entry.key == 0 ? 0 : 1.8),
                      child: pw.Text(
                        entry.value,
                        style: pw.TextStyle(
                          fontSize: _fs(7.9),
                          color: _midGrey,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        pw.SizedBox(height: 3),
        pw.Container(height: 0.6, color: ruleColor),
      ],
    );
  }

  static pw.Widget _buildFooterNotes({
    required String thankYou,
    required String footerNote,
    required bool isQuote,
  }) {
    final safeThankYou = thankYou.isNotEmpty
        ? thankYou
        : (isQuote
            ? 'Thank you for the opportunity.'
            : 'Thank you for your business!');

    if (safeThankYou.isEmpty && footerNote.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (safeThankYou.isNotEmpty)
            pw.Text(
              safeThankYou,
              style: pw.TextStyle(
                fontSize: _fs(8.6),
                fontWeight: pw.FontWeight.bold,
                color: _darkText,
              ),
            ),
          if (footerNote.isNotEmpty) ...[
            if (safeThankYou.isNotEmpty) pw.SizedBox(height: 2),
            pw.Text(
              footerNote,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: _fs(7.8), color: _midGrey),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _formatQty(double qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  static String _resolveDocumentNumber({
    required String explicitNumber,
    required int? sequence,
    required String fallbackId,
  }) {
    final cleanedExplicit = _pdfSafeText(explicitNumber).trim();
    if (cleanedExplicit.isNotEmpty) return cleanedExplicit;
    if (sequence != null && sequence > 0) {
      return 'INV-${sequence.toString().padLeft(4, '0')}';
    }
    if (fallbackId.length >= 8) {
      return 'INV-${fallbackId.substring(0, 6).toUpperCase()}';
    }
    return 'INV-0001';
  }

  static String _sanitizeInstructionText(String value) {
    final withoutControl = _pdfSafeText(value)
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    final trimmed = withoutControl.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
  }

  static String _sanitizePaymentMethodDetail(String methodId, String value) {
    var detail = InvoiceTemplate.sanitizePaymentDetail(value);
    if (detail.isEmpty) return '';
    detail = _pdfSafeText(detail);

    if (methodId == InvoiceTemplate.paymentMethodBankTransfer) {
      detail = detail.replaceAllMapped(
        RegExp(r'\b\d{8,17}\b'),
        (match) {
          final full = match.group(0)!;
          if (full.length <= 4) return full;
          final masked = '*' * (full.length - 4);
          return '$masked${full.substring(full.length - 4)}';
        },
      );
    }

    return detail;
  }

  static String _formatMoney(String currencySymbol, double amount) {
    final formatted = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(amount);
    return _pdfSafeText(formatted);
  }

  static String _normalizedQtyHeader(String value) {
    final cleaned = _pdfSafeText(value).trim();
    final normalized = cleaned.toUpperCase().replaceAll(' ', '');
    if (normalized == 'QTY/HRS' || normalized == 'QTY/HOUR') return 'QTY';
    return cleaned.isEmpty ? 'QTY' : cleaned;
  }

  static List<String> _coerceStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => _pdfSafeText(e.toString()).trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,\n]'))
          .map((e) => _pdfSafeText(e).trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _formatAddressLines(String value) {
    final cleaned = _pdfSafeText(value).trim();
    if (cleaned.isEmpty) return const [];

    final explicitLines = cleaned
        .split(RegExp(r'\r?\n'))
        .map((part) => _pdfSafeText(part).trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (explicitLines.length > 1) {
      return explicitLines;
    }

    final commaParts = cleaned
        .split(',')
        .map((part) => _pdfSafeText(part).trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (commaParts.length <= 1) {
      return cleaned.isEmpty ? const [] : [cleaned];
    }

    // Each comma-separated part gets its own line
    return commaParts;
  }

  static String _pdfSafePaymentUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return trimmed;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return '';
    return uri.toString();
  }

  static String _qrSafePaymentUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    return uri.replace(fragment: '').toString();
  }

  static String _titleCaseWords(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((p) => p.isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _resolveFontFamily({
    required String requestedFontFamily,
  }) {
    final requested = requestedFontFamily.trim().toLowerCase();
    if (requested == 'times' || requested == 'courier') {
      return requested;
    }
    return requestedFontFamily;
  }

  static String _pdfSafeText(String value) {
    return value
        .replaceAll('•', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('…', '...')
        .replaceAll('\u00A0', ' ');
  }

  static Future<pw.ThemeData> _themeForFont(String fontFamily) async {
    try {
      switch (fontFamily.trim().toLowerCase()) {
        case 'courier':
          return pw.ThemeData.withFont(
            base: await PdfGoogleFonts.courierPrimeRegular(),
            bold: await PdfGoogleFonts.courierPrimeBold(),
            italic: await PdfGoogleFonts.courierPrimeItalic(),
            boldItalic: await PdfGoogleFonts.courierPrimeBoldItalic(),
          );
        case 'times':
          return pw.ThemeData.withFont(
            base: await PdfGoogleFonts.loraRegular(),
            bold: await PdfGoogleFonts.loraBold(),
            italic: await PdfGoogleFonts.loraItalic(),
            boldItalic: await PdfGoogleFonts.loraBoldItalic(),
          );
        case 'helvetica':
        default:
          return pw.ThemeData.withFont(
            base: await PdfGoogleFonts.openSansRegular(),
            bold: await PdfGoogleFonts.openSansBold(),
            italic: await PdfGoogleFonts.openSansItalic(),
            boldItalic: await PdfGoogleFonts.openSansBoldItalic(),
          );
      }
    } catch (e) {
      debugPrint('Google Fonts theme load failed, using legacy: $e');
      return _legacyThemeForFont(fontFamily);
    }
  }

  static pw.ThemeData _legacyThemeForFont(String fontFamily) {
    switch (fontFamily.trim().toLowerCase()) {
      case 'times':
        return pw.ThemeData.withFont(
          base: pw.Font.times(),
          bold: pw.Font.timesBold(),
          italic: pw.Font.timesItalic(),
          boldItalic: pw.Font.timesBoldItalic(),
        );
      case 'courier':
        return pw.ThemeData.withFont(
          base: pw.Font.courier(),
          bold: pw.Font.courierBold(),
          italic: pw.Font.courierOblique(),
          boldItalic: pw.Font.courierBoldOblique(),
        );
      case 'helvetica':
      default:
        return pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
          boldItalic: pw.Font.helveticaBoldOblique(),
        );
    }
  }

  static PdfColor _mix(PdfColor a, PdfColor b, double t) {
    final tt = t.clamp(0.0, 1.0).toDouble();
    return PdfColor(
      a.red + (b.red - a.red) * tt,
      a.green + (b.green - a.green) * tt,
      a.blue + (b.blue - a.blue) * tt,
      a.alpha + (b.alpha - a.alpha) * tt,
    );
  }

  static double _fs(num base) => base.toDouble() * _fontScale;

  static double _logoSize(num base) => base.toDouble() * _logoScale;

  static PdfColor _hexToPdf(String hex) {
    final i = TemplateService.hexToInt(hex);
    final r = ((i >> 16) & 0xFF) / 255.0;
    final g = ((i >> 8) & 0xFF) / 255.0;
    final b = (i & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  static String _sanitizeFileSegment(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'Document' : cleaned;
  }
}

/// Simple data holder for a line item.
class _LineItem {
  final String desc;
  final double qty;
  final String? qtyDisplay;
  final double rate;
  final double amount;

  const _LineItem({
    required this.desc,
    required this.qty,
    this.qtyDisplay,
    required this.rate,
    required this.amount,
  });
}
