import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'customer_dao.g.dart';

/// Customer Data Access Object
@DriftAccessor(tables: [Customers])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(AppDatabase db) : super(db);

  /// Get all customers
  Future<List<Customer>> getAllCustomers(String userId) {
    return (select(customers)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String id) {
    return (select(customers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Search customers by name
  Future<List<Customer>> searchCustomers(String userId, String query) {
    return (select(customers)
          ..where((t) =>
              t.userId.equals(userId) &
              t.name.lower().like('%${query.toLowerCase()}%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get customers with outstanding balance
  Future<List<Customer>> getCustomersWithBalance(String userId) {
    return (select(customers)
          ..where((t) =>
              t.userId.equals(userId) & t.balance.isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm.desc(t.balance)]))
        .get();
  }

  /// Create new customer
  Future<Customer> createCustomer(CustomersCompanion customer) async {
    await into(customers).insert(customer);
    return await getCustomerById(customer.id.value)
        .then((c) => c ?? (throw Exception('Customer not found after insert')));
  }

  /// Update customer
  Future<bool> updateCustomer(String id, CustomersCompanion customer) async {
    final updated = await (update(customers)..where((t) => t.id.equals(id)))
        .write(customer.copyWith(
      updatedAt: Value(DateTime.now()),
      synced: const Value(false),
    ));
    return updated > 0;
  }

  /// Delete customer
  Future<int> deleteCustomer(String id) {
    return (delete(customers)..where((t) => t.id.equals(id))).go();
  }

  /// Update customer financials
  Future<void> updateFinancials({
    required String customerId,
    required double totalBilled,
    required double totalPaid,
    DateTime? lastJobDate,
  }) {
    return (update(customers)..where((t) => t.id.equals(customerId))).write(
      CustomersCompanion(
        totalBilled: Value(totalBilled),
        totalPaid: Value(totalPaid),
        balance: Value(totalBilled - totalPaid),
        lastJobDate: Value(lastJobDate),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  /// Increment job count
  Future<void> incrementJobCount(String customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    await (update(customers)..where((t) => t.id.equals(customerId))).write(
      CustomersCompanion(
        jobCount: Value(customer.jobCount + 1),
        lastJobDate: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
  }

  /// Mark as synced
  Future<void> markAsSynced(String id) {
    return (update(customers)..where((t) => t.id.equals(id))).write(
      const CustomersCompanion(synced: Value(true)),
    );
  }

  /// Get unsynced customers
  Future<List<Customer>> getUnsyncedCustomers() {
    return (select(customers)..where((t) => t.synced.equals(false))).get();
  }

  /// Watch all customers (stream)
  Stream<List<Customer>> watchAllCustomers(String userId) {
    return (select(customers)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Watch customer by ID (stream)
  Stream<Customer?> watchCustomerById(String id) {
    return (select(customers)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }
}
