import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../models/invoice_template.dart';
import '../models/business_profile.dart';
import '../services/template_service.dart';
import 'payment_settings_screen.dart';

class TemplateEditorScreen extends StatefulWidget {
  final BusinessProfile? profile;
  const TemplateEditorScreen({super.key, this.profile});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen>
    with SingleTickerProviderStateMixin {
  late InvoiceTemplate _template;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _pendingLogoFile; // logo selected but not yet uploaded
  late TabController _tabCtrl;

  // Text controllers for editable fields
  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _paymentCtrl;
  late TextEditingController _thankYouCtrl;
  late TextEditingController _colDescCtrl;
  late TextEditingController _colQtyCtrl;
  late TextEditingController _colRateCtrl;
  late TextEditingController _colAmountCtrl;
  late final Map<String, TextEditingController> _paymentMethodCtrls;

  static const _colorPresets = [
    {'name': 'Midnight Red', 'primary': '#111827', 'accent': '#D32F2F'},
    {'name': 'Navy Blue', 'primary': '#1565C0', 'accent': '#0D47A1'},
    {'name': 'Forest Green', 'primary': '#2E7D32', 'accent': '#1B5E20'},
    {'name': 'Charcoal', 'primary': '#37474F', 'accent': '#263238'},
    {'name': 'Deep Red', 'primary': '#C62828', 'accent': '#B71C1C'},
    {'name': 'Purple', 'primary': '#6A1B9A', 'accent': '#4A148C'},
    {'name': 'Teal', 'primary': '#00695C', 'accent': '#004D40'},
    {'name': 'Orange', 'primary': '#E65100', 'accent': '#BF360C'},
    {'name': 'Black', 'primary': '#212121', 'accent': '#000000'},
  ];

  static const _headerStylePresets = [
    {
      'id': InvoiceTemplate.headerStyleModern,
      'label': 'Modern',
      'subtitle':
          'Simple 3-column layout: logo, business details, invoice info',
      'icon': Icons.view_agenda_outlined,
    },
    {
      'id': InvoiceTemplate.headerStyleClassic,
      'label': 'Classic',
      'subtitle': 'Big title row with clean invoice number/date columns',
      'icon': Icons.receipt_long_outlined,
    },
    {
      'id': InvoiceTemplate.headerStyleStatement,
      'label': 'Statement',
      'subtitle': 'Title-first layout with invoice details in a separate strip',
      'icon': Icons.splitscreen_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _template = InvoiceTemplate.defaultTemplate();
    _initControllers();
    _load();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _template.name);
    _taglineCtrl = TextEditingController(text: _template.headerTagline);
    _footerCtrl = TextEditingController(text: _template.footerNote);
    _paymentCtrl = TextEditingController(text: _template.paymentTerms);
    _thankYouCtrl = TextEditingController(text: _template.thankYouMessage);
    _colDescCtrl = TextEditingController(text: _template.colDescription);
    _colQtyCtrl = TextEditingController(text: _template.colQty);
    _colRateCtrl = TextEditingController(text: _template.colRate);
    _colAmountCtrl = TextEditingController(text: _template.colAmount);
    _paymentMethodCtrls = {
      for (final method in InvoiceTemplate.supportedPaymentMethods)
        method: TextEditingController(
          text: _template.paymentMethodDetails[method] ?? '',
        ),
    };
  }

  void _syncControllersToTemplate() {
    final paymentDetails = <String, String>{};
    for (final method in InvoiceTemplate.supportedPaymentMethods) {
      var value = InvoiceTemplate.sanitizePaymentDetail(
          _paymentMethodCtrls[method]!.text);
      if (method == InvoiceTemplate.paymentMethodBankTransfer) {
        value = value.replaceAllMapped(
          RegExp(r'\b\d{8,17}\b'),
          (match) {
            final full = match.group(0)!;
            if (full.length <= 4) return full;
            final masked = '*' * (full.length - 4);
            return '$masked${full.substring(full.length - 4)}';
          },
        );
      }
      if (value.isNotEmpty) {
        paymentDetails[method] = value;
      }
    }

    _template = _template.copyWith(
      name: _nameCtrl.text,
      headerTagline: _taglineCtrl.text,
      footerNote: _footerCtrl.text,
      paymentTerms: _paymentCtrl.text,
      thankYouMessage: _thankYouCtrl.text,
      preferredPaymentMethods: InvoiceTemplate.normalizePaymentMethods(
          _template.preferredPaymentMethods),
      paymentMethodDetails: paymentDetails,
      colDescription: _colDescCtrl.text,
      colQty: _colQtyCtrl.text,
      colRate: _colRateCtrl.text,
      colAmount: _colAmountCtrl.text,
    );
  }

  Future<void> _load() async {
    final t = await TemplateService.loadTemplate();
    setState(() {
      _template = t;
      _nameCtrl.text = t.name;
      _taglineCtrl.text = t.headerTagline;
      _footerCtrl.text = t.footerNote;
      _paymentCtrl.text = t.paymentTerms;
      _thankYouCtrl.text = t.thankYouMessage;
      _colDescCtrl.text = t.colDescription;
      _colQtyCtrl.text = t.colQty;
      _colRateCtrl.text = t.colRate;
      _colAmountCtrl.text = t.colAmount;
      for (final method in InvoiceTemplate.supportedPaymentMethods) {
        _paymentMethodCtrls[method]?.text =
            t.paymentMethodDetails[method] ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pendingLogoFile = File(picked.path));
  }

  Future<void> _save() async {
    _syncControllersToTemplate();

    setState(() => _isSaving = true);
    try {
      var t = _template;

      // Upload new logo if one was selected
      if (_pendingLogoFile != null) {
        final url = await TemplateService.uploadLogo(_pendingLogoFile!);
        t = t.copyWith(logoUrl: url);
        _pendingLogoFile = null;
      }

      final saved = await TemplateService.saveTemplate(t);
      setState(() {
        _template = saved;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Template saved!'),
            backgroundColor: AppColors.paid(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, saved);
      }
    } catch (_) {
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
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _footerCtrl.dispose();
    _paymentCtrl.dispose();
    _thankYouCtrl.dispose();
    _colDescCtrl.dispose();
    _colQtyCtrl.dispose();
    _colRateCtrl.dispose();
    _colAmountCtrl.dispose();
    for (final ctrl in _paymentMethodCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Template'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Brand'),
            Tab(icon: Icon(Icons.image), text: 'Logo'),
            Tab(icon: Icon(Icons.text_fields), text: 'Text'),
            Tab(icon: Icon(Icons.visibility), text: 'Preview'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('SAVE',
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _brandTab(),
                _logoTab(),
                _textTab(),
                _previewTab(),
              ],
            ),
    );
  }

  // ─── Tab 1: Brand (colours, font, toggle sections) ───────────────────────

  Widget _brandTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionLabel('TEMPLATE NAME'),
        _field(_nameCtrl, 'Template Name', Icons.label_outline),
        const SizedBox(height: 24),
        _sectionLabel('COLOUR SCHEME'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _colorPresets.map((p) {
            final isSelected = _template.primaryColor == p['primary'];
            return GestureDetector(
              onTap: () => setState(() {
                _template = _template.copyWith(
                  primaryColor: p['primary'],
                  accentColor: p['accent'],
                );
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color(TemplateService.hexToInt(p['primary']!)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.white, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      p['name']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _sectionLabel('FONT STYLE'),
        const SizedBox(height: 12),
        Row(
          children: [
            _fontChip('helvetica', 'Modern'),
            const SizedBox(width: 10),
            _fontChip('times', 'Classic'),
            const SizedBox(width: 10),
            _fontChip('courier', 'Typewriter'),
          ],
        ),
        const SizedBox(height: 24),
        _sectionLabel('HEADER STYLE'),
        const SizedBox(height: 8),
        ..._headerStylePresets.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _headerStyleTile(
                id: p['id']! as String,
                label: p['label']! as String,
                subtitle: p['subtitle']! as String,
                icon: p['icon']! as IconData,
              ),
            )),
        const SizedBox(height: 14),
        _sectionLabel('SHOW / HIDE SECTIONS'),
        _toggle('Show Logo', _template.showLogo,
            (v) => setState(() => _template = _template.copyWith(showLogo: v))),
        _toggle(
            'Business Address',
            _template.showBusinessAddress,
            (v) => setState(
                () => _template = _template.copyWith(showBusinessAddress: v))),
        _toggle(
            'Business Phone',
            _template.showBusinessPhone,
            (v) => setState(
                () => _template = _template.copyWith(showBusinessPhone: v))),
        _toggle(
            'Business Email',
            _template.showBusinessEmail,
            (v) => setState(
                () => _template = _template.copyWith(showBusinessEmail: v))),
        _toggle(
            'Tax / Registration ID',
            _template.showTaxId,
            (v) =>
                setState(() => _template = _template.copyWith(showTaxId: v))),
        _toggle(
            'Invoice Number',
            _template.showInvoiceNumber,
            (v) => setState(
                () => _template = _template.copyWith(showInvoiceNumber: v))),
        _toggle(
            'Due Date',
            _template.showDueDate,
            (v) =>
                setState(() => _template = _template.copyWith(showDueDate: v))),
        _toggle(
            'Payment Terms',
            _template.showPaymentTerms,
            (v) => setState(
                () => _template = _template.copyWith(showPaymentTerms: v))),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _fontChip(String value, String label) {
    final selected = _template.fontFamily == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _template = _template.copyWith(fontFamily: value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Color(TemplateService.hexToInt(_template.primaryColor))
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Color(TemplateService.hexToInt(_template.primaryColor))
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerStyleTile({
    required String id,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _template.headerStyle == id;
    final primary = Color(TemplateService.hexToInt(_template.primaryColor));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () =>
          setState(() => _template = _template.copyWith(headerStyle: id)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: selected
                  ? primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Logo ──────────────────────────────────────────────────────────

  Widget _logoTab() {
    final hasLogo =
        _pendingLogoFile != null || (_template.logoUrl?.isNotEmpty ?? false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionLabel('YOUR BUSINESS LOGO'),
        const SizedBox(height: 8),
        Text(
          'Upload a PNG or JPG. Max 800×400px recommended.\nThe logo will appear at the top of your invoice.',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Logo preview area
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasLogo
                    ? Color(TemplateService.hexToInt(_template.primaryColor))
                    : Theme.of(context).colorScheme.outlineVariant,
                width: hasLogo ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildLogoPreview(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.upload_rounded),
                label: Text(hasLogo ? 'Replace Logo' : 'Upload Logo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color(TemplateService.hexToInt(_template.primaryColor)),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (hasLogo) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _pendingLogoFile = null;
                  _template = _template.copyWith(clearLogo: true);
                }),
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                label: Text('Remove',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 52),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        _sectionLabel('LOGO POSITION'),
        const SizedBox(height: 12),
        Row(
          children: [
            _positionChip(Icons.format_align_left, 'Left', 'left'),
            const SizedBox(width: 10),
            _positionChip(Icons.format_align_center, 'Centre', 'center'),
            const SizedBox(width: 10),
            _positionChip(Icons.format_align_right, 'Right', 'right'),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLogoPreview() {
    if (_pendingLogoFile != null) {
      return Image.file(_pendingLogoFile!, fit: BoxFit.contain);
    }
    if (_template.logoUrl != null && _template.logoUrl!.isNotEmpty) {
      return Image.network(
        _template.logoUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _logoPlaceholder(),
      );
    }
    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 8),
        Text('Tap to upload logo',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14)),
      ],
    );
  }

  Widget _positionChip(IconData icon, String label, String value) {
    final selected =
        InvoiceTemplate.normalizeLogoPosition(_template.logoPosition) == value;
    final primary = Color(TemplateService.hexToInt(_template.primaryColor));
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _template = _template.copyWith(logoPosition: value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.10)
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 3: Text ──────────────────────────────────────────────────────────

  Widget _textTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionLabel('HEADER'),
        _field(_taglineCtrl, 'Tagline under business name', Icons.title,
            hint: 'e.g. "Licensed Plumber - ABN 12 345 678 901"'),
        const SizedBox(height: 8),
        _sectionLabel('CUSTOM DETAILS'),
        const Text(
          'Add any extra lines you want shown on every invoice (ABN, licence number, etc.)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        _customFieldsList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addCustomField,
          icon: const Icon(Icons.add),
          label: const Text('Add Detail'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('TABLE COLUMN HEADERS'),
        Row(children: [
          Expanded(
              child: _field(_colDescCtrl, 'Description Col', Icons.list_alt)),
          const SizedBox(width: 10),
          Expanded(child: _field(_colQtyCtrl, 'Qty Col', Icons.numbers)),
        ]),
        Row(children: [
          Expanded(child: _field(_colRateCtrl, 'Rate Col', Icons.attach_money)),
          const SizedBox(width: 10),
          Expanded(
              child: _field(_colAmountCtrl, 'Amount Col', Icons.calculate)),
        ]),
        const SizedBox(height: 24),
        _sectionLabel('PAYMENT SETTINGS'),
        Text(
          'Payment terms and methods now live under Settings > Payments.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
          ),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Open Payment Settings'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        _sectionLabel('FOOTER'),
        _field(_footerCtrl, 'Footer note', Icons.notes,
            hint: 'e.g. "Payment due within 14 days"'),
        const SizedBox(height: 8),
        _field(_thankYouCtrl, 'Thank-you message', Icons.favorite_border),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _customFieldsList() {
    if (_template.customFields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No custom details yet.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
      );
    }
    return Column(
      children: _template.customFields.asMap().entries.map((entry) {
        final i = entry.key;
        final val = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  child: Text(val, style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editCustomField(i, val),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error, size: 20),
                onPressed: () {
                  final updated = List<String>.from(_template.customFields)
                    ..removeAt(i);
                  setState(() =>
                      _template = _template.copyWith(customFields: updated));
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _addCustomField() => _editCustomField(null, '');

  Future<void> _editCustomField(int? index, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Add Detail' : 'Edit Detail'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. ABN: 12 345 678 901',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final updated = List<String>.from(_template.customFields);
    if (index == null) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    setState(() => _template = _template.copyWith(customFields: updated));
  }

  // ─── Tab 4: Preview ───────────────────────────────────────────────────────

  Widget _previewTab() {
    _syncControllersToTemplate();
    final primaryInt = TemplateService.hexToInt(_template.primaryColor);
    final primary = Color(primaryInt);
    final profile = widget.profile;
    final previewHeaderStyle =
        InvoiceTemplate.normalizeHeaderStyle(_template.headerStyle);
    final selectedPaymentMethods =
        _template.preferredPaymentMethods.where((id) {
      if (id == InvoiceTemplate.paymentMethodStripe) return true;
      final detail = _template.paymentMethodDetails[id]?.trim() ?? '';
      return detail.isNotEmpty;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Live Preview',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewHeader(primary, profile),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business details block
                      if (previewHeaderStyle !=
                              InvoiceTemplate.headerStyleModern &&
                          (_template.showBusinessAddress ||
                              _template.showBusinessPhone ||
                              _template.showBusinessEmail ||
                              _template.showTaxId ||
                              _template.customFields.isNotEmpty))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_template.showBusinessAddress &&
                                  profile?.businessAddress != null)
                                _previewDetail(Icons.location_on_outlined,
                                    profile!.businessAddress!),
                              if (_template.showBusinessPhone &&
                                  profile?.businessPhone != null)
                                _previewDetail(Icons.phone_outlined,
                                    profile!.businessPhone!),
                              if (_template.showBusinessEmail &&
                                  profile?.businessEmail != null)
                                _previewDetail(Icons.email_outlined,
                                    profile!.businessEmail!),
                              if (_template.showTaxId && profile?.taxId != null)
                                _previewDetail(Icons.badge_outlined,
                                    'Tax ID: ${profile!.taxId}'),
                              ..._template.customFields.map(
                                  (f) => _previewDetail(Icons.info_outline, f)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Bill to
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BILL TO',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                const Text('Sample Client Name',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (_template.showDueDate)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('PAYMENT DUE:',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: primary)),
                                const SizedBox(height: 4),
                                Text(
                                  'March 11, 2026',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primary.withValues(alpha: 0.88)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mini table
                      Container(
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(_template.colDescription,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text(_template.colQty,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text(_template.colRate,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right)),
                            Expanded(
                                child: Text(_template.colAmount,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      _previewTableRow(
                          'Labour / Service', '3.0', '\$85', '\$255',
                          isAlt: false),
                      _previewTableRow('Pipe', '1', '\$50', '\$50',
                          isAlt: true),
                      _previewTableRow('Valves', '1', '\$50', '\$50',
                          isAlt: false),

                      const SizedBox(height: 12),
                      // Total
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _totalRow('Subtotal', '\$355', primary,
                                  bold: false),
                              _totalRow('Tax (10%)', '\$35.50', primary,
                                  bold: false),
                              Divider(color: primary, thickness: 1.5),
                              _totalRow('TOTAL DUE', '\$390.50', primary,
                                  bold: true),
                            ],
                          ),
                        ),
                      ),

                      // Payment terms + methods
                      if ((_template.showPaymentTerms &&
                              _template.paymentTerms.isNotEmpty) ||
                          selectedPaymentMethods.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_template.showPaymentTerms &&
                                  _template.paymentTerms.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.account_balance_outlined,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _template.paymentTerms,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ...selectedPaymentMethods.map(
                                (id) => _previewPaymentMethodItem(
                                  methodId: id,
                                  detail: _template.paymentMethodDetails[id],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Text(_template.thankYouMessage,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                    fontSize: 12)),
                            if (_template.footerNote.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(_template.footerNote,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(Color primary, BusinessProfile? profile) {
    final style = InvoiceTemplate.normalizeHeaderStyle(_template.headerStyle);
    switch (style) {
      case InvoiceTemplate.headerStyleClassic:
        return _buildPreviewHeaderClassic(primary, profile);
      case InvoiceTemplate.headerStyleStatement:
        return _buildPreviewHeaderStatement(primary, profile);
      case InvoiceTemplate.headerStyleModern:
      default:
        return _buildPreviewHeaderModern(primary, profile);
    }
  }

  Widget _buildPreviewHeaderModern(Color primary, BusinessProfile? profile) {
    final details = _previewBusinessHeaderLines(profile);
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(_template.logoPosition);
    final showLogoSlot = _template.showLogo;
    final logoSlot = showLogoSlot
        ? SizedBox(
            width: 74,
            child: _previewHeaderLogoBox(),
          )
        : null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2.5, color: primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logoSlot != null &&
                    logoPosition == InvoiceTemplate.logoPositionLeft) ...[
                  logoSlot,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.businessName ?? 'Your Business Name',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (_template.headerTagline.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _template.headerTagline,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10),
                          ),
                        ),
                      if (details.isNotEmpty) const SizedBox(height: 4),
                      ...details.asMap().entries.map((entry) => Padding(
                            padding:
                                EdgeInsets.only(top: entry.key == 0 ? 0 : 2),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 9),
                            ),
                          )),
                    ],
                  ),
                ),
                if (logoSlot != null &&
                    logoPosition == InvoiceTemplate.logoPositionCenter) ...[
                  const SizedBox(width: 12),
                  logoSlot,
                ],
                const SizedBox(width: 12),
                SizedBox(
                  width: 164,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('INVOICE',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Container(
                        width: 128,
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      if (_template.showInvoiceNumber)
                        Text(
                          'INVOICE #: INV-0001',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade600),
                        ),
                      Text(
                        'Date: 30 Jan 2026',
                        textAlign: TextAlign.right,
                        style:
                            TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (logoSlot != null &&
                    logoPosition == InvoiceTemplate.logoPositionRight) ...[
                  const SizedBox(width: 12),
                  logoSlot,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeaderClassic(Color primary, BusinessProfile? profile) {
    final logoCard = _previewHeaderLogoCard();
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(_template.logoPosition);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(height: 2, color: primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVOICE',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 58,
                            height: 2,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_template.showInvoiceNumber)
                            _previewMetaDark('INV #', 'INV-0001'),
                          _previewMetaDark('Date', '30 Jan 2026'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 10),
                if (logoCard != null &&
                    logoPosition == InvoiceTemplate.logoPositionCenter) ...[
                  Center(child: logoCard),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logoCard != null &&
                        logoPosition == InvoiceTemplate.logoPositionLeft) ...[
                      logoCard,
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.businessName ?? 'Your Business Name',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          if (_template.headerTagline.isNotEmpty)
                            Text(
                              _template.headerTagline,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    if (logoCard != null &&
                        logoPosition == InvoiceTemplate.logoPositionRight) ...[
                      const SizedBox(width: 10),
                      logoCard,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeaderStatement(Color primary, BusinessProfile? profile) {
    final logoCard = _previewHeaderLogoCard(height: 42);
    final logoPosition =
        InvoiceTemplate.normalizeLogoPosition(_template.logoPosition);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logoCard != null) ...[
                        Align(
                          alignment:
                              logoPosition == InvoiceTemplate.logoPositionRight
                                  ? Alignment.centerRight
                                  : logoPosition ==
                                          InvoiceTemplate.logoPositionCenter
                                      ? Alignment.center
                                      : Alignment.centerLeft,
                          child: logoCard,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        profile?.businessName ?? 'Your Business Name',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (_template.headerTagline.isNotEmpty)
                        Text(
                          _template.headerTagline,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('INVOICE',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(width: 70, height: 3, color: primary),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (_template.showInvoiceNumber)
                  Expanded(child: _previewInlineMetaBox('INV #', 'INV-0001')),
                if (_template.showInvoiceNumber) const SizedBox(width: 8),
                Expanded(
                  child: _previewInlineMetaBox('Date', '30 Jan 2026',
                      alignEnd: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewLogoImage({double height = 44}) {
    if (_pendingLogoFile != null) {
      return Image.file(_pendingLogoFile!, height: height, fit: BoxFit.contain);
    }
    if (_template.logoUrl != null && _template.logoUrl!.isNotEmpty) {
      return Image.network(
        _template.logoUrl!,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget? _previewHeaderLogoCard({double height = 36}) {
    final hasLogo =
        _pendingLogoFile != null || (_template.logoUrl?.isNotEmpty ?? false);
    if (!_template.showLogo || !hasLogo) return null;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _previewLogoImage(height: height),
    );
  }

  Widget _previewHeaderLogoBox() {
    final hasLogo =
        _pendingLogoFile != null || (_template.logoUrl?.isNotEmpty ?? false);
    return Container(
      width: 74,
      height: 74,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: hasLogo ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: hasLogo
          ? Center(child: _previewLogoImage(height: 42))
          : Center(
              child: Text(
                'LOGO',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  List<String> _previewBusinessHeaderLines(BusinessProfile? profile) {
    final lines = <String>[];

    void addIf(bool enabled, String? value) {
      final trimmed = value?.trim();
      if (enabled && trimmed != null && trimmed.isNotEmpty) {
        lines.add(trimmed);
      }
    }

    addIf(_template.showBusinessAddress, profile?.businessAddress);
    addIf(_template.showBusinessPhone, profile?.businessPhone);
    addIf(_template.showBusinessEmail, profile?.businessEmail);

    if (_template.showTaxId && (profile?.taxId?.trim().isNotEmpty ?? false)) {
      lines.add('Tax ID: ${profile!.taxId!.trim()}');
    }

    for (final field in _template.customFields) {
      final trimmed = field.trim();
      if (trimmed.isNotEmpty) lines.add(trimmed);
    }

    return lines;
  }

  Widget _previewInlineMetaBox(String label, String value,
      {bool alignEnd = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _previewMetaDark(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _previewDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _previewPaymentMethodItem({
    required String methodId,
    String? detail,
  }) {
    final label = InvoiceTemplate.paymentMethodLabels[methodId] ?? methodId;
    final safeDetail = (detail ?? '').trim();
    final isStripe = methodId == InvoiceTemplate.paymentMethodStripe;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                if (isStripe || safeDetail.isNotEmpty)
                  const SizedBox(height: 2),
                if (isStripe)
                  Text(
                    'Credit/debit card, Apple Pay, Google Pay, bank transfer',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  )
                else if (safeDetail.isNotEmpty)
                  Text(
                    safeDetail,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTableRow(String desc, String qty, String rate, String amount,
      {required bool isAlt}) {
    return Container(
      color: isAlt ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3, child: Text(desc, style: const TextStyle(fontSize: 11))),
          Expanded(
              child: Text(qty,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center)),
          Expanded(
              child: Text(rate,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text(amount,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color,
      {required bool bold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: bold ? color : Colors.grey.shade600,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  color: bold ? color : Colors.grey.shade700,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2)),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      contentPadding: EdgeInsets.zero,
      activeColor: Color(TemplateService.hexToInt(_template.primaryColor)),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}), // rebuild preview live
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
