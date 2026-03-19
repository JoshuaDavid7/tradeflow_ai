import 'package:flutter/material.dart';

import '../models/invoice_template.dart';
import '../services/template_service.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late InvoiceTemplate _template;
  late TextEditingController _paymentTermsCtrl;
  late Map<String, TextEditingController> _paymentMethodCtrls;
  late List<String> _selectedMethods;
  bool _showPaymentTerms = true;

  static const _manualPaymentMethodOptions = [
    {
      'id': InvoiceTemplate.paymentMethodStripe,
      'label': 'Stripe Checkout',
      'icon': Icons.lock_outline,
      'hint': '',
      'security':
          'Adds secure pay link + QR code when you generate a secure payment PDF.',
    },
    {
      'id': InvoiceTemplate.paymentMethodCheck,
      'label': 'Check',
      'icon': Icons.receipt_long_outlined,
      'hint': 'Payable to: Business Name\nMail to: Address',
      'security':
          'Use business name and mailing address. Avoid personal addresses.',
    },
    {
      'id': InvoiceTemplate.paymentMethodZelle,
      'label': 'Zelle',
      'icon': Icons.account_balance_wallet_outlined,
      'hint': 'Send to: business@email.com or business phone',
      'security': 'Use business email/phone only.',
    },
    {
      'id': InvoiceTemplate.paymentMethodVenmo,
      'label': 'Venmo',
      'icon': Icons.alternate_email,
      'hint': 'Venmo business: @yourhandle',
      'security': 'Prefer a business profile handle.',
    },
    {
      'id': InvoiceTemplate.paymentMethodCashApp,
      'label': 'Cash App',
      'icon': Icons.qr_code_2_outlined,
      'hint': 'Cash App: \$yourcashtag',
      'security': 'Verify cashtag carefully before sharing invoices.',
    },
    {
      'id': InvoiceTemplate.paymentMethodPaypal,
      'label': 'PayPal',
      'icon': Icons.payments_outlined,
      'hint': 'PayPal: paypal.me/yourname or business@email.com',
      'security': 'Use a verified business PayPal account.',
    },
    {
      'id': InvoiceTemplate.paymentMethodBankTransfer,
      'label': 'Bank Transfer',
      'icon': Icons.account_balance_outlined,
      'hint':
          'Bank: Name\nAccount name: Business Name\nRouting: *****123\nAccount: ****1234',
      'security': 'Only include masked account details in invoices.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _template = InvoiceTemplate.defaultTemplate();
    _paymentTermsCtrl = TextEditingController(text: _template.paymentTerms);
    _paymentMethodCtrls = {
      for (final method in InvoiceTemplate.supportedPaymentMethods)
        method: TextEditingController(
          text: _template.paymentMethodDetails[method] ?? '',
        ),
    };
    _selectedMethods = List<String>.from(_template.preferredPaymentMethods);
    _showPaymentTerms = _template.showPaymentTerms;
    _load();
  }

  @override
  void dispose() {
    _paymentTermsCtrl.dispose();
    for (final ctrl in _paymentMethodCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await TemplateService.loadTemplate();
    if (!mounted) return;

    setState(() {
      _template = loaded;
      _paymentTermsCtrl.text = loaded.paymentTerms;
      _selectedMethods = List<String>.from(loaded.preferredPaymentMethods);
      _showPaymentTerms = loaded.showPaymentTerms;
      for (final method in InvoiceTemplate.supportedPaymentMethods) {
        _paymentMethodCtrls[method]?.text =
            loaded.paymentMethodDetails[method] ?? '';
      }
      _isLoading = false;
    });
  }

  void _togglePaymentMethod(String id, bool enabled) {
    final updated = List<String>.from(_selectedMethods);
    if (enabled) {
      if (!updated.contains(id)) updated.add(id);
    } else {
      updated.remove(id);
    }
    setState(() {
      _selectedMethods = InvoiceTemplate.normalizePaymentMethods(updated);
    });
  }

  String? _validatePaymentMethods() {
    for (final method in _selectedMethods) {
      if (method == InvoiceTemplate.paymentMethodStripe) continue;
      final detail = InvoiceTemplate.sanitizePaymentDetail(
        _paymentMethodCtrls[method]?.text ?? '',
      );
      if (detail.isEmpty) {
        final label = InvoiceTemplate.paymentMethodLabels[method] ?? method;
        return 'Add payment details for $label or unselect it.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validatePaymentMethods();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final paymentDetails = <String, String>{};
    for (final method in InvoiceTemplate.supportedPaymentMethods) {
      final normalized = InvoiceTemplate.sanitizePaymentDetail(
        _paymentMethodCtrls[method]?.text ?? '',
      );
      if (normalized.isNotEmpty) {
        paymentDetails[method] = normalized;
      }
    }

    setState(() => _isSaving = true);
    try {
      final updated = _template.copyWith(
        showPaymentTerms: _showPaymentTerms,
        paymentTerms: _paymentTermsCtrl.text.trim(),
        preferredPaymentMethods:
            InvoiceTemplate.normalizePaymentMethods(_selectedMethods),
        paymentMethodDetails: paymentDetails,
      );
      final saved = await TemplateService.saveTemplate(updated);
      if (!mounted) return;
      setState(() {
        _template = saved;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment settings saved'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Save failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('PAYMENT TERMS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        )),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _showPaymentTerms,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() => _showPaymentTerms = value);
                  },
                  title: const Text('Show additional payment terms'),
                  subtitle: const Text(
                    'Shows your payment terms block in invoice PDFs.',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _paymentTermsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Payment Terms',
                    hintText:
                        'e.g. Payment due in 14 days. Late fee applies after due date.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('PAYMENT METHODS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        )),
                const SizedBox(height: 8),
                Text(
                  'Select accepted methods and provide exact details customers should use.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                ..._manualPaymentMethodOptions.map((option) {
                  final id = option['id']! as String;
                  final label = option['label']! as String;
                  final icon = option['icon']! as IconData;
                  final hint = option['hint']! as String;
                  final security = option['security']! as String;
                  final selected = _selectedMethods.contains(id);
                  final ctrl = _paymentMethodCtrls[id]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: selected,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: colorScheme.primary,
                          onChanged: (checked) =>
                              _togglePaymentMethod(id, checked ?? false),
                          title: Row(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(height: 8),
                          if (id == InvoiceTemplate.paymentMethodStripe)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                security,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            TextField(
                              controller: ctrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: hint,
                                helperText: security,
                                helperMaxLines: 2,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: colorScheme.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: colorScheme.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text('SAVE PAYMENT SETTINGS'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
