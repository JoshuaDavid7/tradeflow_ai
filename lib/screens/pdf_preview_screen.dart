import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_profile.dart' as legacy;
import '../services/pdf_service.dart';
import '../services/template_service.dart';
import '../data/services/supabase_service.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/providers/job_provider.dart';
import '../presentation/providers/analytics_provider.dart';
import '../presentation/providers/customer_ledger_provider.dart';
import '../presentation/widgets/record_payment_sheet.dart';
import '../presentation/widgets/material_cost_status.dart';
import 'draft_review_screen.dart';

/// Shows a polished PDF preview of the invoice/quote with integrated actions.
class PdfPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> jobData;

  const PdfPreviewScreen({super.key, required this.jobData});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  bool _isLoading = true;
  Uint8List? _pdfBytes;
  String? _error;

  /// Mutable snapshot of jobData — refreshed after payment recording.
  late Map<String, dynamic> _jobData;

  @override
  void initState() {
    super.initState();
    _jobData = Map<String, dynamic>.from(widget.jobData);
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      final domainProfile = ref.read(businessProfileProvider);
      if (domainProfile == null) {
        setState(() {
          _error = 'Business profile not loaded';
          _isLoading = false;
        });
        return;
      }

      // Convert domain model to legacy model for PdfService
      final profile = legacy.BusinessProfile(
        id: domainProfile.id,
        businessName: domainProfile.businessName,
        businessAddress: domainProfile.businessAddress,
        businessPhone: domainProfile.businessPhone,
        businessEmail: domainProfile.businessEmail,
        taxId: domainProfile.taxId,
        hourlyRate: domainProfile.defaultHourlyRate,
        taxRate: domainProfile.defaultTaxRate,
        currencySymbol: domainProfile.currencySymbol,
        isPro: domainProfile.isPro,
      );

      final template = await TemplateService.loadTemplate();
      final bytes = await PdfService.buildPdfBytes(
        jobData: _jobData,
        profile: profile,
        template: template,
      );

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Whether this is a sent invoice that can receive payments.
  bool get _canRecordPayment {
    final status = (_jobData['status']?.toString().toLowerCase()) ?? 'draft';
    final rawType = (_jobData['type']?.toString() ?? 'invoice').toLowerCase();
    if (rawType != 'invoice') return false;
    // Accept both 'sent' and legacy 'paid' (document state)
    if (status != 'sent' && status != 'paid') return false;
    final totalAmount = double.tryParse(
            (_jobData['total_amount'] ?? _jobData['totalAmount'] ?? '0')
                .toString()) ??
        0;
    final amountPaid = double.tryParse(
            (_jobData['amount_paid'] ?? _jobData['amountPaid'] ?? '0')
                .toString()) ??
        0;
    return totalAmount > 0 && amountPaid < totalAmount - 0.01;
  }

  Future<void> _recordPayment() async {
    final jobId = (_jobData['id'] ?? _jobData['jobId'])?.toString() ?? '';
    if (jobId.isEmpty) return;

    final total = double.tryParse(
            (_jobData['total_amount'] ?? _jobData['totalAmount'] ?? '0')
                .toString()) ??
        0;
    final amountPaid = double.tryParse(
            (_jobData['amount_paid'] ?? _jobData['amountPaid'] ?? '0')
                .toString()) ??
        0;
    final clientName =
        (_jobData['client_name'] ?? _jobData['clientName'] ?? 'Client')
            .toString();

    final recorded = await showRecordPaymentSheet(
      context,
      jobId: jobId,
      totalAmount: total,
      amountPaid: amountPaid,
      clientName: clientName,
    );

    if (recorded == true && mounted) {
      // Refresh providers so dashboard/history update
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.invalidate(customerLedgerListProvider);
      container.read(analyticsProvider.notifier).refresh();

      // Re-fetch the job to get updated payment state, then regenerate PDF
      try {
        final updatedJob = await Supabase.instance.client
            .from('jobs')
            .select('*')
            .eq('id', jobId)
            .maybeSingle();
        if (updatedJob != null && mounted) {
          _jobData
            ..clear()
            ..addAll(Map<String, dynamic>.from(updatedJob));
          await _generatePdf();
          setState(() {});
        }
      } catch (_) {
        // Best-effort refresh — still show stale data if fetch fails
      }
    }
  }

  void _openEditor() {
    final status = (_jobData['status']?.toString().toLowerCase()) ?? 'draft';
    final isSent =
        status == 'sent' || status == 'paid' || status == 'cancelled';

    if (isSent) {
      // Clone: strip id to force INSERT path, link back to original
      final clonedData = Map<String, dynamic>.from(_jobData)
        ..['revision_of'] = _jobData['id']
        ..remove('id')
        ..['status'] = 'draft'
        // Strip invoice number — clone gets a fresh one on send
        ..remove('invoice_number')
        ..remove('invoiceNumber')
        ..remove('invoice_sequence')
        ..remove('invoiceSequence')
        // Strip payment fields — new draft has no payments
        ..remove('amount_paid')
        ..remove('amountPaid')
        ..remove('paid_at')
        ..remove('paidAt')
        ..remove('payment_provider')
        ..remove('payment_checkout_url')
        ..remove('payment_checkout_session_id')
        ..remove('payment_status')
        ..remove('payment_currency')
        ..remove('payment_amount_minor');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DraftReviewScreen(jobData: clonedData),
        ),
      );
    } else {
      // Draft: direct edit (existing behavior)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DraftReviewScreen(jobData: _jobData),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    final rawType = _jobData['type']?.toString() ?? 'invoice';
    final clientName = _jobData['client_name']?.toString() ??
        _jobData['clientName']?.toString() ??
        'document';
    final invoiceNumber = _jobData['invoice_number']?.toString() ??
        _jobData['invoiceNumber']?.toString();
    final prefix = rawType == 'quote' ? 'QTE' : 'INV';
    final numberPart = (invoiceNumber != null && invoiceNumber.isNotEmpty)
        ? invoiceNumber
        : prefix;
    final fileName = '${numberPart}_$clientName.pdf'
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .toLowerCase();
    await Printing.sharePdf(bytes: _pdfBytes!, filename: fileName);

    // After sharing, mark the job as 'sent' if it's still a draft.
    await _markAsSentIfDraft();
  }

  /// Transitions the job from 'draft' to 'sent' on Supabase after sharing.
  /// Only applies when the job has an id and is currently a draft.
  Future<void> _markAsSentIfDraft() async {
    final jobId = (_jobData['id'] ?? _jobData['jobId'])?.toString();
    if (jobId == null || jobId.isEmpty) return;

    final currentStatus =
        _jobData['status']?.toString().toLowerCase() ?? 'draft';
    if (currentStatus != 'draft') return;

    try {
      await Supabase.instance.client
          .from('jobs')
          .update({'status': 'sent'}).eq('id', jobId);

      // Invalidate providers so the dashboard and job list refresh.
      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      container.invalidate(jobStatsProvider);
      container.invalidate(jobListProvider);
      container.read(analyticsProvider.notifier).refresh();
    } catch (_) {
      // Non-critical — the job was shared successfully, status update is best-effort.
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes!,
    );
  }

  String get _documentTitle {
    final rawType = _jobData['type']?.toString() ?? 'Invoice';
    final type = rawType[0].toUpperCase() + rawType.substring(1).toLowerCase();
    final number = _jobData['invoice_number']?.toString() ??
        _jobData['invoiceNumber']?.toString();
    if (number != null && number.isNotEmpty) {
      return '$type #$number';
    }
    return '$type Preview';
  }

  String? get _statusLabel {
    final status = _jobData['status']?.toString().toLowerCase();
    if (status == null || status.isEmpty) return null;

    final capitalised =
        status[0].toUpperCase() + status.substring(1).toLowerCase();

    // For sent invoices, show combined document + payment context.
    if (status == 'sent' || status == 'paid') {
      final rawType = (_jobData['type']?.toString() ?? 'invoice').toLowerCase();
      final isInvoice = rawType == 'invoice';
      final totalAmount = double.tryParse(
              (_jobData['total_amount'] ?? _jobData['totalAmount'] ?? '0')
                  .toString()) ??
          0;
      final amountPaid = double.tryParse(
              (_jobData['amount_paid'] ?? _jobData['amountPaid'] ?? '0')
                  .toString()) ??
          0;
      if (isInvoice && totalAmount > 0) {
        if (amountPaid >= totalAmount - 0.01) {
          return 'Sent \u00b7 Paid in full';
        }
        if (amountPaid > 0.01) {
          return 'Sent \u00b7 Partially paid';
        }
        return 'Sent \u00b7 Awaiting payment';
      }
    }

    if (status == 'cancelled') {
      return 'Cancelled \u00b7 Superseded by revision';
    }

    return capitalised;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Elegant dark viewer background
    const viewerBg = Color(0xFF2C2C2E);
    const viewerBgLight = Color(0xFFE8E8ED);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? viewerBg : viewerBgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: isDark ? Colors.white : colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _documentTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            if (_statusLabel != null)
              Text(
                _statusLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Cancelled/superseded invoices are read-only — no Edit button.
          if (_jobData['status']?.toString().toLowerCase() != 'cancelled')
            TextButton(
              onPressed: _openEditor,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : colorScheme.primary,
              ),
              child: const Text('Edit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Document skeleton shimmer
                  Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating\u2026',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color:
                              isDark ? Colors.red.shade300 : colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Could not generate preview',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openEditor,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit Instead'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // PDF viewer — the document, centered and prominent
                    Expanded(
                      child: PdfPreview(
                        build: (_) async => _pdfBytes!,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        canDebug: false,
                        useActions: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        scrollViewDecoration: BoxDecoration(
                          color: bgColor,
                        ),
                        pdfPreviewPageDecoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Material cost status (sent invoices only)
                    if (_jobData['status']?.toString().toLowerCase() ==
                            'sent' &&
                        _jobData['type']?.toString().toLowerCase() != 'quote' &&
                        (_jobData['id']?.toString().isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: MaterialCostStatusSection(
                          jobId: _jobData['id'].toString(),
                          userId: ref.watch(userIdProvider) ?? '',
                          currencySymbol: ref.watch(currencySymbolProvider),
                        ),
                      ),

                    // Action bar — context-aware buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Cancelled: no Pay or Edit. Active: Pay or Edit.
                            if (_jobData['status']?.toString().toLowerCase() !=
                                'cancelled')
                              Expanded(
                                child: _canRecordPayment
                                    ? _actionButton(
                                        icon: Icons.payments_rounded,
                                        label: 'Pay',
                                        onTap: _recordPayment,
                                        isDark: isDark,
                                        colorScheme: colorScheme,
                                      )
                                    : _actionButton(
                                        icon: Icons.edit_rounded,
                                        label: 'Edit',
                                        onTap: _openEditor,
                                        isDark: isDark,
                                        colorScheme: colorScheme,
                                      ),
                              ),
                            if (_jobData['status']?.toString().toLowerCase() !=
                                'cancelled')
                              const SizedBox(width: 10),
                            const SizedBox(width: 10),
                            // Share — primary action
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _sharePdf,
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: const Text('Share',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Print
                            Expanded(
                              child: _actionButton(
                                icon: Icons.print_rounded,
                                label: 'Print',
                                onTap: _printPdf,
                                isDark: isDark,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: isDark ? Colors.white70 : colorScheme.onSurface,
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
