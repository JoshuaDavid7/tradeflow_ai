import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/payment_receipt.dart';
import '../domain/models/business_profile.dart';

/// Service for generating, storing, and sharing payment receipts.
class PaymentReceiptService {
  static const _uuid = Uuid();
  static final _supabase = Supabase.instance.client;

  /// Generate a payment receipt after a payment is recorded.
  static Future<PaymentReceipt> createReceipt({
    required String paymentId,
    required String jobId,
    required String userId,
    required BusinessProfile profile,
    required String customerName,
    String? customerEmail,
    required String invoiceNumber,
    required double invoiceTotal,
    required double paymentAmount,
    required String paymentMethod,
    String? transactionReference,
    required DateTime paymentDate,
    required double balanceBefore,
    required double balanceAfter,
  }) async {
    final receiptId = _uuid.v4();
    final isFullyPaid = balanceAfter <= 0.01;

    // Generate receipt number: REC-YYYYMMDD-XXXX
    final dateStr = DateFormat('yyyyMMdd').format(paymentDate);
    final seq = receiptId.substring(0, 4).toUpperCase();
    final receiptNumber = 'REC-$dateStr-$seq';

    final receipt = PaymentReceipt(
      id: receiptId,
      paymentId: paymentId,
      jobId: jobId,
      userId: userId,
      receiptNumber: receiptNumber,
      businessName: profile.businessName,
      businessAddress: profile.businessAddress,
      businessPhone: profile.businessPhone,
      businessEmail: profile.businessEmail,
      customerName: customerName,
      customerEmail: customerEmail,
      invoiceNumber: invoiceNumber,
      invoiceTotal: invoiceTotal,
      paymentAmount: paymentAmount,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      paymentDate: paymentDate,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      isFullyPaid: isFullyPaid,
      createdAt: DateTime.now(),
    );

    // Store in Supabase
    try {
      final json = receipt.toJson();
      // Remove null values that might cause issues
      json.removeWhere((key, value) => value == null);
      await _supabase.from('payment_receipts').upsert(
        json,
        onConflict: 'payment_id',
      );
    } catch (e) {
      debugPrint('Receipt storage error: $e');
    }

    return receipt;
  }

  /// Get all receipts for a specific job/invoice.
  static Future<List<PaymentReceipt>> getReceiptsForJob(String jobId) async {
    try {
      final data = await _supabase
          .from('payment_receipts')
          .select()
          .eq('job_id', jobId)
          .order('payment_date', ascending: false);
      return (data as List)
          .map((e) => PaymentReceipt.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch payment receipts: $e');
      return [];
    }
  }

  /// Generate a receipt PDF.
  static Future<Uint8List> generatePdf(
    PaymentReceipt receipt, {
    String currencySymbol = '\$',
  }) async {
    final f = NumberFormat.currency(symbol: currencySymbol);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        receipt.receiptNumber,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  // Status badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: receipt.isFullyPaid
                          ? PdfColors.green100
                          : PdfColors.amber100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      receipt.statusLabel.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: receipt.isFullyPaid
                            ? PdfColors.green800
                            : PdfColors.amber800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ── Business & Customer ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FROM',
                            style: _labelStyle()),
                        pw.SizedBox(height: 4),
                        pw.Text(receipt.businessName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12)),
                        if (receipt.businessAddress != null &&
                            receipt.businessAddress!.isNotEmpty)
                          pw.Text(receipt.businessAddress!,
                              style: const pw.TextStyle(fontSize: 10)),
                        if (receipt.businessPhone != null &&
                            receipt.businessPhone!.isNotEmpty)
                          pw.Text(receipt.businessPhone!,
                              style: const pw.TextStyle(fontSize: 10)),
                        if (receipt.businessEmail != null &&
                            receipt.businessEmail!.isNotEmpty)
                          pw.Text(receipt.businessEmail!,
                              style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TO',
                            style: _labelStyle()),
                        pw.SizedBox(height: 4),
                        pw.Text(receipt.customerName,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12)),
                        if (receipt.customerEmail != null &&
                            receipt.customerEmail!.isNotEmpty)
                          pw.Text(receipt.customerEmail!,
                              style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // ── Payment Details Table ──
              _buildDetailRow('Invoice Number', receipt.invoiceNumber),
              _buildDetailRow('Invoice Total', f.format(receipt.invoiceTotal)),
              _buildDetailRow(
                  'Payment Date', dateFormat.format(receipt.paymentDate)),
              _buildDetailRow('Payment Method', receipt.methodDisplayName),
              if (receipt.transactionReference != null &&
                  receipt.transactionReference!.isNotEmpty)
                _buildDetailRow('Reference', receipt.transactionReference!),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── Amount ──
              _buildDetailRow(
                'Balance Before Payment',
                f.format(receipt.balanceBefore),
              ),
              _buildAmountRow(
                'Payment Amount',
                f.format(receipt.paymentAmount),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey400, thickness: 1.5),
              pw.SizedBox(height: 4),
              _buildDetailRow(
                'Remaining Balance',
                receipt.isFullyPaid
                    ? '${f.format(0.0)} (Paid in full)'
                    : f.format(receipt.balanceAfter),
                bold: true,
              ),

              pw.SizedBox(height: 32),

              // ── Footer ──
              pw.Center(
                child: pw.Text(
                  'Thank you for your payment!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated by Tradesman Ledger',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.TextStyle _labelStyle() => pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey500,
        letterSpacing: 1.2,
      );

  static pw.Widget _buildDetailRow(String label, String value,
      {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              )),
        ],
      ),
    );
  }

  /// Share/print the receipt PDF.
  static Future<void> sharePdf(Uint8List pdfBytes, String receiptNumber) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$receiptNumber.pdf',
    );
  }
}
