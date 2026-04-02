import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/tables.dart';
import 'daos/job_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/receipt_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/project_dao.dart';
import 'daos/material_cost_dao.dart';

part 'database.g.dart';

/// Main application database
@DriftDatabase(
  tables: [
    Jobs,
    Expenses,
    Payments,
    Receipts,
    Customers,
    Templates,
    SyncQueue,
    BusinessSettings,
    Projects,
    RecognizedMaterialCosts,
    MaterialCostLinks,
  ],
  daos: [
    JobDao,
    ExpenseDao,
    ReceiptDao,
    CustomerDao,
    ProjectDao,
    MaterialCostDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  Future<bool> _tableExists(String tableName) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    if (!await _tableExists(tableName)) {
      return false;
    }

    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  Future<void> _ensureColumnSql(
    String tableName,
    String columnName,
    String alterStatement,
  ) async {
    if (!await _columnExists(tableName, columnName)) {
      await customStatement(alterStatement);
    }
  }

  Future<void> _repairLegacySchema() async {
    await _ensureColumnSql(
      'expenses',
      'customer_id',
      'ALTER TABLE expenses ADD COLUMN customer_id TEXT',
    );
    await _ensureColumnSql(
      'receipts',
      'customer_id',
      'ALTER TABLE receipts ADD COLUMN customer_id TEXT',
    );
    await _ensureColumnSql(
      'receipts',
      'extracted_items_json',
      'ALTER TABLE receipts ADD COLUMN extracted_items_json TEXT',
    );
    await _ensureColumnSql(
      'recognized_material_costs',
      'material_id',
      'ALTER TABLE recognized_material_costs ADD COLUMN material_id TEXT',
    );
    await _ensureColumnSql(
      'business_settings',
      'quote_prefix',
      'ALTER TABLE business_settings ADD COLUMN quote_prefix TEXT',
    );
    await _ensureColumnSql(
      'business_settings',
      'default_due_days',
      'ALTER TABLE business_settings ADD COLUMN default_due_days INTEGER NOT NULL DEFAULT 14',
    );
    await _ensureColumnSql(
      'business_settings',
      'default_markup_percent',
      'ALTER TABLE business_settings ADD COLUMN default_markup_percent REAL NOT NULL DEFAULT 0.0',
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add Projects table
          await m.createTable(projects);
          // Add customerId to expenses
          await m.addColumn(expenses, expenses.customerId);
          // Add customerId and extractedItemsJson to receipts
          await m.addColumn(receipts, receipts.customerId);
          await m.addColumn(receipts, receipts.extractedItemsJson);
        }
        if (from < 3) {
          await m.createTable(recognizedMaterialCosts);
          await m.createTable(materialCostLinks);
        }
        if (from < 6) {
          // Add document default columns to business_settings
          await _ensureColumnSql(
            'business_settings',
            'quote_prefix',
            "ALTER TABLE business_settings ADD COLUMN quote_prefix TEXT",
          );
          await _ensureColumnSql(
            'business_settings',
            'default_due_days',
            "ALTER TABLE business_settings ADD COLUMN default_due_days INTEGER NOT NULL DEFAULT 14",
          );
          await _ensureColumnSql(
            'business_settings',
            'default_markup_percent',
            "ALTER TABLE business_settings ADD COLUMN default_markup_percent REAL NOT NULL DEFAULT 0.0",
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        await _repairLegacySchema();
        if (details.wasCreated) {
          // Insert default business settings on first run
          await into(businessSettings).insert(
            BusinessSettingsCompanion.insert(
              userId: '', // Will be updated when user authenticates
              businessName: 'My Trade Business',
              defaultHourlyRate: const Value(85.0),
              defaultTaxRate: const Value(0.0),
              currencySymbol: const Value('\$'),
            ),
          );
        }
      },
    );
  }
}

/// Database connection.
///
/// Uses [getApplicationDocumentsDirectory] with a fallback for environments
/// where `path_provider_foundation`'s `objective_c` FFI layer fails (e.g.
/// iOS 26 beta simulators).
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    Directory dbFolder;
    try {
      dbFolder = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('getApplicationDocumentsDirectory failed, using temp dir fallback: $e');
      // Fallback: derive the app's Documents dir from the temp directory.
      // On iOS / simulators, Directory.systemTemp resolves to
      //   <app-sandbox>/tmp  –  so we go up one level to reach the sandbox
      //   root and then into Documents.
      final tmpPath = Directory.systemTemp.path; // e.g. …/tmp
      final sandboxRoot = p.dirname(tmpPath); // strip /tmp
      dbFolder = Directory(p.join(sandboxRoot, 'Documents'));
      if (!dbFolder.existsSync()) {
        dbFolder.createSync(recursive: true);
      }
    }
    final file = File(p.join(dbFolder.path, 'tradeflow.db'));

    return NativeDatabase.createInBackground(file);
  });
}

/// Provider for database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});
