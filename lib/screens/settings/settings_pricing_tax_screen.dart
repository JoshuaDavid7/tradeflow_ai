import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/business_profile.dart';
import '../../presentation/providers/profile_provider.dart';

/// Pricing & Tax detail screen — tax ID, hourly rate, tax rate, currency.
class SettingsPricingTaxScreen extends ConsumerStatefulWidget {
  const SettingsPricingTaxScreen({super.key});

  @override
  ConsumerState<SettingsPricingTaxScreen> createState() =>
      _SettingsPricingTaxScreenState();
}

class _SettingsPricingTaxScreenState
    extends ConsumerState<SettingsPricingTaxScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _taxIdCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  String _currencySymbol = '\$';

  static const _currencies = [
    ('\$', 'USD (\$)'),
    ('£', 'GBP (£)'),
    ('€', 'EUR (€)'),
    ('A\$', 'AUD (A\$)'),
    ('C\$', 'CAD (C\$)'),
    ('NZ\$', 'NZD (NZ\$)'),
    ('R', 'ZAR (R)'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _taxIdCtrl.dispose();
    _rateCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        final p = BusinessProfile.fromJson(data);
        _taxIdCtrl.text = p.taxId ?? '';
        _rateCtrl.text = p.hourlyRate.toString();
        _taxRateCtrl.text = p.taxRate.toString();
        _currencySymbol = p.currencySymbol;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Pricing load failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'tax_id': _taxIdCtrl.text.trim(),
        'hourly_rate': double.tryParse(_rateCtrl.text) ?? 85.0,
        'tax_rate': double.tryParse(_taxRateCtrl.text) ?? 0.0,
        'currency_symbol': _currencySymbol,
        'updated_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing & tax saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Save failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing & Tax'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _taxIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Tax Registration / ID',
                  prefixIcon: Icon(Icons.assignment_ind,
                      size: 20, color: colorScheme.primary),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hourly Rate',
                        prefixIcon: Icon(Icons.monetization_on,
                            size: 20, color: colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _taxRateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tax Rate %',
                        prefixIcon: Icon(Icons.percent,
                            size: 20, color: colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: _currencies.any((c) => c.$1 == _currencySymbol)
                    ? _currencySymbol
                    : '\$',
                decoration: InputDecoration(
                  labelText: 'Currency',
                  prefixIcon: Icon(Icons.currency_exchange,
                      size: 20, color: colorScheme.primary),
                ),
                items: _currencies
                    .map((c) =>
                        DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _currencySymbol = v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
