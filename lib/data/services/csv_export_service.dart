import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/database.dart';

/// Exports business data as CSV files for backup and portability.
class CsvExportService {
  /// Export all jobs for the current user as a CSV file and share it.
  static Future<void> exportJobs(String userId) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('jobs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data as List);

    final buffer = StringBuffer();
    buffer.writeln(
      'Invoice Number,Client,Type,Status,Description,Labor Hours,Hourly Rate,'
      'Tax Rate,Tax Amount,Subtotal,Total,Amount Paid,Amount Due,Due Date,Paid At,Created',
    );

    for (final row in rows) {
      buffer.writeln([
        _csvEscape(row['invoice_number']?.toString() ?? ''),
        _csvEscape(row['client_name']?.toString() ?? ''),
        _csvEscape(row['type']?.toString() ?? ''),
        _csvEscape(row['status']?.toString() ?? ''),
        _csvEscape(row['description']?.toString() ?? ''),
        row['labor_hours']?.toString() ?? '0',
        row['hourly_rate_at_time']?.toString() ?? '0',
        row['tax_rate_at_time']?.toString() ?? '0',
        row['tax_amount']?.toString() ?? '0',
        row['subtotal']?.toString() ?? '0',
        row['total_amount']?.toString() ?? '0',
        row['amount_paid']?.toString() ?? '0',
        row['amount_due']?.toString() ?? '0',
        _csvEscape(row['due_date']?.toString() ?? ''),
        _csvEscape(row['paid_at']?.toString() ?? ''),
        _csvEscape(row['created_at']?.toString() ?? ''),
      ].join(','));
    }

    await _shareFile(buffer.toString(), 'jobs_export.csv');
  }

  /// Export all expenses for the current user as a CSV file and share it.
  static Future<void> exportExpenses(String userId) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data as List);

    final buffer = StringBuffer();
    buffer.writeln(
      'Date,Description,Amount,Category,Vendor,Payment Method,Tax Deductible,Job ID,Notes,Created',
    );

    for (final row in rows) {
      buffer.writeln([
        _csvEscape(row['date']?.toString() ?? ''),
        _csvEscape(row['description']?.toString() ?? ''),
        row['amount']?.toString() ?? '0',
        _csvEscape(row['category']?.toString() ?? ''),
        _csvEscape(row['vendor']?.toString() ?? ''),
        _csvEscape(row['payment_method']?.toString() ?? ''),
        (row['tax_deductible'] == true) ? 'Yes' : 'No',
        _csvEscape(row['job_id']?.toString() ?? ''),
        _csvEscape(row['notes']?.toString() ?? ''),
        _csvEscape(row['created_at']?.toString() ?? ''),
      ].join(','));
    }

    await _shareFile(buffer.toString(), 'expenses_export.csv');
  }

  /// Export all clients for the current user as a CSV file and share it.
  static Future<void> exportClients(String userId) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('customers')
        .select()
        .eq('user_id', userId)
        .order('name');

    final rows = List<Map<String, dynamic>>.from(data as List);

    final buffer = StringBuffer();
    buffer.writeln(
      'Name,Email,Phone,Address,Notes,Created',
    );

    for (final row in rows) {
      buffer.writeln([
        _csvEscape(row['name']?.toString() ?? ''),
        _csvEscape(row['email']?.toString() ?? ''),
        _csvEscape(row['phone']?.toString() ?? ''),
        _csvEscape(row['address']?.toString() ?? ''),
        _csvEscape(row['notes']?.toString() ?? ''),
        _csvEscape(row['created_at']?.toString() ?? ''),
      ].join(','));
    }

    await _shareFile(buffer.toString(), 'clients_export.csv');
  }

  /// Export all payment records for the current user as a CSV file.
  ///
  /// Payment records are stored locally (Drift) and include per-transaction
  /// details like method, reference, and notes that aren't available on the
  /// aggregate job-level fields.
  static Future<void> exportPayments(String userId, AppDatabase db) async {
    final allPayments = await db.jobDao.getUserPayments(userId);

    // Build a job ID → invoice number + client name lookup for enrichment
    final jobIds = allPayments.map((p) => p.jobId).toSet();
    final jobInfoCache = <String, Map<String, String>>{};
    for (final jobId in jobIds) {
      try {
        final job = await db.jobDao.getJobById(jobId);
        if (job != null) {
          jobInfoCache[jobId] = {
            'invoiceNumber': job.title,
            'clientName': job.clientName,
          };
        }
      } catch (e) {
        debugPrint('Payment export: failed to fetch job $jobId: $e');
      }
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Date Received,Amount,Method,Reference,Notes,Invoice Number,Client,Created',
    );

    for (final p in allPayments) {
      final info = jobInfoCache[p.jobId] ?? {};
      buffer.writeln([
        _csvEscape(p.receivedAt.toIso8601String()),
        p.amount.toStringAsFixed(2),
        _csvEscape(p.method),
        _csvEscape(p.reference ?? ''),
        _csvEscape(p.notes ?? ''),
        _csvEscape(info['invoiceNumber'] ?? ''),
        _csvEscape(info['clientName'] ?? ''),
        _csvEscape(p.createdAt.toIso8601String()),
      ].join(','));
    }

    await _shareFile(buffer.toString(), 'payments_export.csv');
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<void> _shareFile(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], subject: fileName);
  }
}
