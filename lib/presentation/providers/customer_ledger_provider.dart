import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

String _customerSortKey(Map<String, dynamic> customer) =>
    (customer['name']?.toString() ?? '').trim().toLowerCase();

/// Provider to get all customers for ledger — enriched with live job stats
final customerLedgerListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();

    // 1. Fetch customers
    List<Map<String, dynamic>> customers;
    try {
      final data = await supabase.client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('name', ascending: true);
      customers = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint(
          'Customer fetch with updated_at failed, falling back to created_at: $e');
      final data = await supabase.client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      customers = List<Map<String, dynamic>>.from(data as List);
    }

    // 2. Fetch all jobs for this user to compute live stats
    List<Map<String, dynamic>> allJobs = [];
    try {
      final jobData = await supabase.client
          .from('jobs')
          .select(
              'id,customer_id,client_name,type,status,total_amount,amount_paid')
          .eq('user_id', userId);
      allJobs = List<Map<String, dynamic>>.from(jobData as List);
    } catch (e) {
      // If jobs query fails, return customers with stored (possibly stale) stats
      debugPrint('Jobs query failed for ledger enrichment: $e');
      customers
          .sort((a, b) => _customerSortKey(a).compareTo(_customerSortKey(b)));
      return customers;
    }

    // 3. Build a lookup: customer_id -> list of jobs, plus name-based fallback
    final Map<String, List<Map<String, dynamic>>> jobsByCustomerId = {};
    final Map<String, String> customerNameById = {};
    for (final c in customers) {
      final cId = c['id']?.toString() ?? '';
      customerNameById[cId] =
          (c['name']?.toString() ?? '').trim().toLowerCase();
      jobsByCustomerId[cId] = [];
    }

    // Index by name for fallback matching
    final Map<String, List<String>> customerIdsByName = {};
    for (final entry in customerNameById.entries) {
      if (entry.value.isNotEmpty) {
        customerIdsByName.putIfAbsent(entry.value, () => []).add(entry.key);
      }
    }

    // Assign jobs to customers (by customer_id first, then name fallback)
    final Set<String> assignedJobIds = {};
    for (final job in allJobs) {
      final jobCustId = job['customer_id']?.toString() ?? '';
      if (jobCustId.isNotEmpty && jobsByCustomerId.containsKey(jobCustId)) {
        jobsByCustomerId[jobCustId]!.add(job);
        assignedJobIds.add(job['id'].toString());
      }
    }
    // Name-based fallback for jobs without customer_id link
    for (final job in allJobs) {
      if (assignedJobIds.contains(job['id'].toString())) continue;
      final clientName =
          (job['client_name']?.toString() ?? '').trim().toLowerCase();
      if (clientName.isNotEmpty && customerIdsByName.containsKey(clientName)) {
        for (final cId in customerIdsByName[clientName]!) {
          jobsByCustomerId[cId]!.add(job);
        }
        assignedJobIds.add(job['id'].toString());
      }
    }

    // 4. Enrich each customer with computed stats
    for (final c in customers) {
      final cId = c['id']?.toString() ?? '';
      final jobs = jobsByCustomerId[cId] ?? [];

      int jobCount = 0;
      double totalBilled = 0.0;
      double totalPaid = 0.0;

      for (final j in jobs) {
        final type = (j['type']?.toString().toLowerCase()) ?? 'invoice';
        final status = (j['status']?.toString().toLowerCase()) ?? 'draft';
        jobCount++;
        // Only invoices (not quotes) count toward billing totals
        if (type == 'quote') continue;
        if (status == 'cancelled' || status == 'superseded') continue;
        final total = (j['total_amount'] as num?)?.toDouble() ?? 0.0;
        final paid = (j['amount_paid'] as num?)?.toDouble() ?? 0.0;
        totalBilled += total;
        totalPaid += paid;
      }

      c['job_count'] = jobCount;
      c['total_billed'] = totalBilled;
      c['total_paid'] = totalPaid;
      c['balance'] = totalBilled - totalPaid;
    }

    customers
        .sort((a, b) => _customerSortKey(a).compareTo(_customerSortKey(b)));
    return customers;
  } catch (e) {
    ErrorHandler.warning(
        'Failed to load customers for ledger', {'error': e.toString()});
    return [];
  }
});

/// Provider to get projects for a specific customer
final customerProjectsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();
    final data = await supabase.client
        .from('projects')
        .select()
        .eq('user_id', userId)
        .eq('customer_id', customerId)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e) {
    ErrorHandler.debug('Projects query failed (table may not exist yet)',
        {'error': e.toString()});
    return [];
  }
});

/// Provider to get all jobs/invoices for a customer (by customer_id OR client_name fallback)
final customerJobsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();

    // First try by customer_id
    List<Map<String, dynamic>> jobs = [];
    try {
      final byId = await supabase.client
          .from('jobs')
          .select()
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      jobs = List<Map<String, dynamic>>.from(byId as List);
    } catch (e) {
      debugPrint('Jobs fetch by customer_id failed (column may not exist): $e');
    }

    // Also try by client_name match (for jobs created before linking was added)
    try {
      final customer = await supabase.client
          .from('customers')
          .select('name')
          .eq('id', customerId)
          .maybeSingle();
      if (customer != null) {
        final customerName = customer['name']?.toString().trim() ?? '';
        if (customerName.isNotEmpty) {
          final byName = await supabase.client
              .from('jobs')
              .select()
              .eq('user_id', userId)
              .ilike('client_name', customerName)
              .order('created_at', ascending: false);
          final nameJobs = List<Map<String, dynamic>>.from(byName as List);
          // Merge, avoiding duplicates
          final existingIds = jobs.map((j) => j['id']).toSet();
          for (final job in nameJobs) {
            if (!existingIds.contains(job['id'])) {
              jobs.add(job);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Jobs name-based fallback fetch failed: $e');
    }

    // Sort by created_at descending
    jobs.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return jobs;
  } catch (e) {
    return [];
  }
});

/// Provider to get all expenses for a customer.
/// Fetches expenses by direct customer_id AND by job_id for jobs belonging
/// to this customer (covers expenses assigned via jobs).
final customerExpensesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();
    final allExpenses = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    // 1. Direct customer_id match
    try {
      final byCustomer = await supabase.client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('expense_date', ascending: false);
      for (final row in List<Map<String, dynamic>>.from(byCustomer as List)) {
        final id = row['id']?.toString() ?? '';
        if (id.isNotEmpty && seenIds.add(id)) {
          allExpenses.add(row);
        }
      }
    } catch (_) {}

    // 2. Get this customer's job IDs, then fetch expenses by job_id
    try {
      final jobs = await ref.read(customerJobsProvider(customerId).future);
      final jobIds = jobs
          .map((j) => j['id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      if (jobIds.isNotEmpty) {
        final byJob = await supabase.client
            .from('expenses')
            .select()
            .eq('user_id', userId)
            .inFilter('job_id', jobIds)
            .order('expense_date', ascending: false);
        for (final row in List<Map<String, dynamic>>.from(byJob as List)) {
          final id = row['id']?.toString() ?? '';
          if (id.isNotEmpty && seenIds.add(id)) {
            allExpenses.add(row);
          }
        }
      }
    } catch (_) {}

    // Sort merged results by date descending
    allExpenses.sort((a, b) {
      final aDate = DateTime.tryParse(a['expense_date']?.toString() ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(b['expense_date']?.toString() ?? '') ??
          DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return allExpenses;
  } catch (e) {
    return [];
  }
});

/// Provider to get notes for a customer (pinned first, then by updated_at desc)
final customerNotesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();
    final data = await supabase.client
        .from('project_notes')
        .select()
        .eq('user_id', userId)
        .eq('customer_id', customerId)
        .order('updated_at', ascending: false);
    final notes = List<Map<String, dynamic>>.from(data as List);
    // Sort pinned notes first, then by updated_at descending
    notes.sort((a, b) {
      final aPinned = a['pinned'] == true ? 0 : 1;
      final bPinned = b['pinned'] == true ? 0 : 1;
      if (aPinned != bPinned) return aPinned.compareTo(bPinned);
      final aDate = DateTime.tryParse(a['updated_at']?.toString() ?? '') ??
          DateTime(2000);
      final bDate = DateTime.tryParse(b['updated_at']?.toString() ?? '') ??
          DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return notes;
  } catch (e) {
    // customer_id column may not exist yet — return empty rather than
    // leaking all notes to every customer.
    debugPrint('Customer notes fetch failed (column may not exist): $e');
    return [];
  }
});
