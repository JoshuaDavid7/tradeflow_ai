import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/business_profile.dart';
import '../../presentation/providers/profile_provider.dart';

/// Documents & Defaults detail screen — prefixes, due date, markup.
class SettingsDocumentsScreen extends ConsumerStatefulWidget {
  const SettingsDocumentsScreen({super.key});

  @override
  ConsumerState<SettingsDocumentsScreen> createState() =>
      _SettingsDocumentsScreenState();
}

class _SettingsDocumentsScreenState
    extends ConsumerState<SettingsDocumentsScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _invoicePrefixCtrl = TextEditingController(text: 'INV');
  final _quotePrefixCtrl = TextEditingController(text: 'QUO');
  final _markupCtrl = TextEditingController(text: '0');
  int _nextInvoiceNumber = 1;
  int _defaultDueDays = 14;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _invoicePrefixCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _invoicePrefixCtrl.dispose();
    _quotePrefixCtrl.dispose();
    _markupCtrl.dispose();
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
        _invoicePrefixCtrl.text = p.invoicePrefix;
        _quotePrefixCtrl.text = p.quotePrefix;
        _nextInvoiceNumber = p.nextInvoiceNumber;
        _defaultDueDays = p.defaultDueDays;
        _markupCtrl.text =
            p.defaultMarkupPercent > 0 ? p.defaultMarkupPercent.toString() : '0';
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Document defaults load failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      final prefix = _invoicePrefixCtrl.text
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final quotePrefix = _quotePrefixCtrl.text
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');

      await _supabase.from('profiles').upsert({
        'id': userId,
        'invoice_prefix': prefix.isEmpty ? 'INV' : prefix,
        'quote_prefix': quotePrefix.isEmpty ? 'QUO' : quotePrefix,
        'default_due_days': _defaultDueDays,
        'default_markup_percent': double.tryParse(_markupCtrl.text) ?? 0.0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document defaults saved')),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents & Defaults'),
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
            // ── Numbering ──
            _subHeader('NUMBERING', textTheme, colorScheme),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoicePrefixCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Invoice Prefix',
                      hintText: 'INV',
                      prefixIcon: Icon(Icons.receipt_long,
                          size: 20, color: colorScheme.primary),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quotePrefixCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Quote Prefix',
                      hintText: 'QUO',
                      prefixIcon: Icon(Icons.request_quote,
                          size: 20, color: colorScheme.primary),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next invoice: ${_invoicePrefixCtrl.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}-${_nextInvoiceNumber.toString().padLeft(4, '0')}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Due Date ──
            _subHeader('DEFAULT DUE DATE', textTheme, colorScheme),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _defaultDueDays,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.calendar_today,
                    size: 20, color: colorScheme.primary),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 7, child: Text('Net 7 — Due in 7 days')),
                DropdownMenuItem(
                    value: 14, child: Text('Net 14 — Due in 14 days')),
                DropdownMenuItem(
                    value: 30, child: Text('Net 30 — Due in 30 days')),
                DropdownMenuItem(
                    value: 45, child: Text('Net 45 — Due in 45 days')),
                DropdownMenuItem(
                    value: 60, child: Text('Net 60 — Due in 60 days')),
                DropdownMenuItem(value: 0, child: Text('Due on receipt')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _defaultDueDays = v);
              },
            ),

            const SizedBox(height: 28),

            // ── Markup ──
            _subHeader('DEFAULT MATERIAL MARKUP', textTheme, colorScheme),
            const SizedBox(height: 10),
            TextFormField(
              controller: _markupCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Markup %',
                hintText: '0',
                prefixIcon: Icon(Icons.trending_up,
                    size: 20, color: colorScheme.primary),
                suffixText: '%',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Applied to receipt materials when added to invoices',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subHeader(String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(text,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ));
  }
}
