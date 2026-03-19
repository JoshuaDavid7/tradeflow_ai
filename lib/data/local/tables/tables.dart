import 'package:drift/drift.dart';

/// Jobs table - invoices, quotes, estimates
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get customerId => text().nullable()();
  
  // Basic info
  TextColumn get title => text()();
  TextColumn get clientName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get trade => text().nullable()();
  
  // Status & Type
  TextColumn get status => text()(); // draft, sent, paid, cancelled
  TextColumn get type => text()();   // invoice, quote, estimate
  
  // Financial - Labor
  RealColumn get laborHours => real().withDefault(const Constant(0))();
  RealColumn get laborRate => real()();
  
  // Financial - Materials (stored as JSON array)
  TextColumn get materialsJson => text().withDefault(const Constant('[]'))();
  
  // Financial - Totals
  RealColumn get subtotal => real()();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real()();
  RealColumn get total => real()();
  
  // Payment tracking
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  RealColumn get amountDue => real()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  
  // Sync status
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Expenses table - business spending
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get jobId => text().nullable()(); // Link to job if job-specific
  TextColumn get customerId => text().nullable()(); // Link to customer

  // Expense details
  TextColumn get description => text()();
  TextColumn get vendor => text().nullable()();
  TextColumn get category => text()(); // materials, labor, fuel, tools, etc.
  
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime()();
  
  // Receipt
  TextColumn get receiptPath => text().nullable()(); // Local file path
  TextColumn get receiptUrl => text().nullable()();  // Cloud storage URL
  TextColumn get ocrText => text().nullable()();     // Extracted text
  
  // Tax
  BoolColumn get taxDeductible => boolean().withDefault(const Constant(true))();
  TextColumn get taxCategory => text().nullable()(); // IRS category
  
  // Payment method
  TextColumn get paymentMethod => text().nullable()(); // cash, card, check
  
  // Sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Payments table - money received
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  TextColumn get userId => text()();
  
  RealColumn get amount => real()();
  TextColumn get method => text()(); // cash, check, card, bank_transfer, other
  TextColumn get reference => text().nullable()(); // check number, transaction ID
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // Sync
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Receipts table - scanned documents
class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get expenseId => text().nullable()();
  TextColumn get jobId => text().nullable()();
  TextColumn get customerId => text().nullable()();

  // Image storage
  TextColumn get imagePath => text()(); // Local path
  TextColumn get imageUrl => text().nullable()(); // Cloud URL
  TextColumn get thumbnailPath => text().nullable()();

  // OCR extracted data
  TextColumn get ocrText => text().nullable()();
  RealColumn get extractedAmount => real().nullable()();
  TextColumn get extractedVendor => text().nullable()();
  DateTimeColumn get extractedDate => dateTime().nullable()();
  TextColumn get extractedItemsJson => text().nullable()(); // AI-extracted line items JSON

  // Processing status
  TextColumn get ocrStatus => text().withDefault(const Constant('pending'))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Customers table - enhanced with financials
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  
  // Contact info
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  // Financial summary (denormalized for performance)
  RealColumn get totalBilled => real().withDefault(const Constant(0))();
  RealColumn get totalPaid => real().withDefault(const Constant(0))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  
  IntColumn get jobCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastJobDate => dateTime().nullable()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Templates table - reusable invoice/quote templates
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  
  TextColumn get name => text()();
  TextColumn get type => text()(); // invoice, quote, estimate
  
  // Default values
  RealColumn get defaultLaborRate => real().nullable()();
  RealColumn get defaultTaxRate => real().nullable()();
  TextColumn get defaultTerms => text().nullable()();
  TextColumn get defaultNotes => text().nullable()();
  
  // Line items (JSON array)
  TextColumn get lineItemsJson => text().withDefault(const Constant('[]'))();
  
  // Usage tracking
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// SyncQueue table - tracks pending sync operations
class SyncQueue extends Table {
  TextColumn get id => text()();
  
  TextColumn get targetTable => text()(); // Renamed from tableName to avoid conflict
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get dataJson => text()();
  
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Projects table - jobs/projects under a customer
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get customerId => text()();

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('active'))(); // active, completed, archived

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recognized material costs — canonical cost for each invoice material line.
/// Analytics sums canonical_cost (not raw invoice materials or raw expenses)
/// to prevent double-counting.
class RecognizedMaterialCosts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get jobId => text().nullable()();
  IntColumn get materialIndex => integer().nullable()();
  TextColumn get materialId => text().nullable()();
  TextColumn get description => text()();
  RealColumn get provisionalCost => real()();
  RealColumn get canonicalCost => real()();
  DateTimeColumn get recognitionDate => dateTime()();
  TextColumn get source => text().withDefault(const Constant('invoice'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Links between recognized material costs and expenses (many-to-many).
/// One receipt can cover multiple invoice material lines, and one material
/// line can be fulfilled by multiple receipts.
class MaterialCostLinks extends Table {
  TextColumn get id => text()();
  TextColumn get recognizedMaterialCostId => text()();
  TextColumn get expenseId => text()();
  RealColumn get allocatedAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Business settings table
class BusinessSettings extends Table {
  TextColumn get userId => text()();
  
  // Business profile
  TextColumn get businessName => text()();
  TextColumn get businessAddress => text().nullable()();
  TextColumn get businessPhone => text().nullable()();
  TextColumn get businessEmail => text().nullable()();
  TextColumn get taxId => text().nullable()();
  
  // Default rates
  RealColumn get defaultHourlyRate => real().withDefault(const Constant(85.0))();
  RealColumn get defaultTaxRate => real().withDefault(const Constant(0.0))();
  TextColumn get currencySymbol => text().withDefault(const Constant('\$'))();
  
  // Invoice settings
  TextColumn get invoicePrefix => text().nullable()();
  IntColumn get nextInvoiceNumber => integer().withDefault(const Constant(1))();
  TextColumn get defaultPaymentTerms => text().nullable()();
  
  // Subscription
  BoolColumn get isPro => boolean().withDefault(const Constant(false))();
  TextColumn get subscriptionStatus => text().withDefault(const Constant('none'))();
  
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {userId};
}
