import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

/// Provider to get all customers for ledger
final customerLedgerListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();
    // Try with updated_at ordering (requires migration)
    try {
      final data = await supabase.client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      // Fallback: updated_at column might not exist yet
      final data = await supabase.client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    }
  } catch (e) {
    ErrorHandler.warning('Failed to load customers for ledger', {'error': e.toString()});
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
    ErrorHandler.debug('Projects query failed (table may not exist yet)', {'error': e.toString()});
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
    } catch (_) {
      // customer_id column might not exist on jobs table
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
    } catch (_) {}

    // Sort by created_at descending
    jobs.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return jobs;
  } catch (e) {
    return [];
  }
});

/// Provider to get all expenses for a customer (by customer_id OR vendor matching)
final customerExpensesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  try {
    await supabase.ensureValidSession();
    final data = await supabase.client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .eq('customer_id', customerId)
        .order('expense_date', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
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
      final aDate = DateTime.tryParse(a['updated_at']?.toString() ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['updated_at']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return notes;
  } catch (_) {
    // Fallback: customer_id column may not exist yet (migration pending)
    try {
      final supabase2 = ref.read(supabaseServiceProvider);
      final data = await supabase2.client
          .from('project_notes')
          .select()
          .eq('user_id', userId!)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }
});
