import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Seeds realistic sample data for new users so they can evaluate the app
/// immediately. All demo data is tagged and can be cleanly removed.
class DemoDataService {
  static const _uuid = Uuid();
  static const _prefKey = 'demo_data_loaded';
  static const _demoTag = '__demo__';

  /// Whether demo data has been loaded for this user.
  static Future<bool> isDemoLoaded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_prefKey}_$userId') ?? false;
  }

  /// Seed demo data into Supabase for the given user.
  static Future<void> seed(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // ── Clients ──
      final clientA = _uuid.v4();
      final clientB = _uuid.v4();
      final clientC = _uuid.v4();

      await supabase.from('customers').upsert([
        {
          'id': clientA,
          'user_id': userId,
          'name': 'Sarah Mitchell',
          'email': 'sarah@example.com',
          'phone': '(555) 123-4567',
          'address': '42 Oak Lane, Denver, CO 80202',
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'id': clientB,
          'user_id': userId,
          'name': 'Metro Property Group',
          'email': 'maintenance@metroprop.example.com',
          'phone': '(555) 987-6543',
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'id': clientC,
          'user_id': userId,
          'name': 'James & Linda Park',
          'phone': '(555) 456-7890',
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ]);

      // ── Jobs ──
      final jobA = _uuid.v4(); // Paid invoice
      final jobB = _uuid.v4(); // Sent invoice (awaiting payment)
      final jobC = _uuid.v4(); // Draft quote
      final jobD = _uuid.v4(); // Sent quote

      await supabase.from('jobs').upsert([
        // Paid invoice — kitchen faucet replacement
        {
          'id': jobA,
          'user_id': userId,
          'customer_id': clientA,
          'client_name': 'Sarah Mitchell',
          'title': 'Sarah Mitchell',
          'description': 'Kitchen faucet replacement and under-sink plumbing repair',
          'type': 'invoice',
          'status': 'paid',
          'total_amount': 485.0,
          'amount_paid': 485.0,
          'amount_due': 0.0,
          'labor_hours': 3.0,
          'hourly_rate_at_time': 85.0,
          'tax_rate_at_time': 0.0,
          'materials': [
            {'id': _uuid.v4(), 'name': 'Delta kitchen faucet', 'cost': 189.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Supply lines (2-pack)', 'cost': 24.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Plumber\'s putty', 'cost': 7.0, 'qty': 1},
          ],
          'invoice_number': 'INV-0001',
          'invoice_sequence': 1,
          'created_at': now.subtract(const Duration(days: 21)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 18)).toIso8601String(),
        },
        // Sent invoice — bathroom renovation (awaiting payment)
        {
          'id': jobB,
          'user_id': userId,
          'customer_id': clientB,
          'client_name': 'Metro Property Group',
          'title': 'Metro Property Group',
          'description': 'Unit 4B bathroom renovation — tile, fixtures, and vanity install',
          'type': 'invoice',
          'status': 'sent',
          'total_amount': 2350.0,
          'amount_paid': 0.0,
          'amount_due': 2350.0,
          'labor_hours': 16.0,
          'hourly_rate_at_time': 85.0,
          'tax_rate_at_time': 0.0,
          'materials': [
            {'id': _uuid.v4(), 'name': 'Porcelain floor tile (12 sqft)', 'cost': 156.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Vanity with sink', 'cost': 420.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Toilet (Kohler)', 'cost': 289.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Tile adhesive & grout', 'cost': 65.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Shower valve + trim kit', 'cost': 178.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Misc supplies', 'cost': 42.0, 'qty': 1},
          ],
          'invoice_number': 'INV-0002',
          'invoice_sequence': 2,
          'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        },
        // Draft quote — deck repair
        {
          'id': jobC,
          'user_id': userId,
          'customer_id': clientC,
          'client_name': 'James & Linda Park',
          'title': 'James & Linda Park',
          'description': 'Rear deck board replacement and railing repair — 12x16 ft deck',
          'type': 'quote',
          'status': 'draft',
          'total_amount': 1890.0,
          'labor_hours': 12.0,
          'hourly_rate_at_time': 85.0,
          'tax_rate_at_time': 0.0,
          'materials': [
            {'id': _uuid.v4(), 'name': 'Pressure-treated deck boards (20)', 'cost': 540.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Cedar railing sections (4)', 'cost': 280.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Deck screws (5 lb box)', 'cost': 38.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Post brackets (6)', 'cost': 12.0, 'qty': 1},
          ],
          'invoice_number': 'QUO-0003',
          'invoice_sequence': 3,
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
        // Sent quote — electrical panel upgrade
        {
          'id': jobD,
          'user_id': userId,
          'customer_id': clientA,
          'client_name': 'Sarah Mitchell',
          'title': 'Sarah Mitchell',
          'description': 'Electrical panel upgrade from 100A to 200A service',
          'type': 'quote',
          'status': 'sent',
          'total_amount': 3200.0,
          'labor_hours': 8.0,
          'hourly_rate_at_time': 85.0,
          'tax_rate_at_time': 0.0,
          'materials': [
            {'id': _uuid.v4(), 'name': '200A main panel (Square D)', 'cost': 890.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Circuit breakers assorted (12)', 'cost': 264.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': '#2 copper wire (50 ft)', 'cost': 385.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Conduit and fittings', 'cost': 121.0, 'qty': 1},
            {'id': _uuid.v4(), 'name': 'Permit fee', 'cost': 160.0, 'qty': 1},
          ],
          'invoice_number': 'QUO-0004',
          'invoice_sequence': 4,
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
          'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ]);

      // ── Expenses ──
      await supabase.from('expenses').upsert([
        {
          'id': _uuid.v4(),
          'user_id': userId,
          'job_id': jobA,
          'description': 'Delta faucet + supply lines',
          'amount': 220.0,
          'category': 'Materials',
          'vendor': 'Home Depot',
          'date': now.subtract(const Duration(days: 22)).toIso8601String(),
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 22)).toIso8601String(),
        },
        {
          'id': _uuid.v4(),
          'user_id': userId,
          'job_id': jobB,
          'description': 'Tile and vanity for Unit 4B',
          'amount': 576.0,
          'category': 'Materials',
          'vendor': 'Floor & Decor',
          'date': now.subtract(const Duration(days: 7)).toIso8601String(),
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        },
        {
          'id': _uuid.v4(),
          'user_id': userId,
          'description': 'Monthly truck insurance',
          'amount': 185.0,
          'category': 'Insurance',
          'vendor': 'State Farm',
          'date': now.subtract(const Duration(days: 15)).toIso8601String(),
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        },
        {
          'id': _uuid.v4(),
          'user_id': userId,
          'description': 'Fuel for work truck',
          'amount': 92.50,
          'category': 'Fuel',
          'vendor': 'Shell',
          'date': now.subtract(const Duration(days: 3)).toIso8601String(),
          'notes': _demoTag,
          'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        },
      ]);

      // Update next invoice number to avoid conflicts
      await supabase.from('profiles').update({
        'next_invoice_number': 5,
      }).eq('id', userId);

      // Mark demo data as loaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_prefKey}_$userId', true);

      debugPrint('DemoDataService: seeded demo data for $userId');
    } catch (e) {
      debugPrint('DemoDataService: seed failed: $e');
      rethrow;
    }
  }

  /// Remove all demo data for the given user.
  static Future<void> clear(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // Delete demo expenses (tagged via notes field)
      await supabase
          .from('expenses')
          .delete()
          .eq('user_id', userId)
          .eq('notes', _demoTag);

      // Delete demo jobs — find jobs linked to demo customers
      final demoCustomers = await supabase
          .from('customers')
          .select('id')
          .eq('user_id', userId)
          .eq('notes', _demoTag);

      final customerIds =
          (demoCustomers as List).map((c) => c['id'] as String).toList();

      if (customerIds.isNotEmpty) {
        await supabase
            .from('jobs')
            .delete()
            .eq('user_id', userId)
            .inFilter('customer_id', customerIds);
      }

      // Delete demo customers
      await supabase
          .from('customers')
          .delete()
          .eq('user_id', userId)
          .eq('notes', _demoTag);

      // Only reset next invoice number if the user has no real (non-demo) jobs
      final realJobs = await supabase
          .from('jobs')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      if ((realJobs as List).isEmpty) {
        await supabase.from('profiles').update({
          'next_invoice_number': 1,
        }).eq('id', userId);
      }

      // Clear the flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_prefKey}_$userId');

      debugPrint('DemoDataService: cleared demo data for $userId');
    } catch (e) {
      debugPrint('DemoDataService: clear failed: $e');
      rethrow;
    }
  }
}
