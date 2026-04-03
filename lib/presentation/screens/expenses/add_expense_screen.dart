import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tradeflow_ai/domain/models/expense.dart';
import 'package:tradeflow_ai/domain/models/receipt.dart' as domain_receipt;
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../../domain/models/job.dart';
import '../../providers/job_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/receipt_provider.dart';
import '../receipts/receipt_scanner_screen.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/receipt_ai_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final Expense? existingExpense; // For editing
  final domain_receipt.Receipt? prefilledReceipt;
  final Map<String, dynamic>? initialData; // Pre-fill from AI voice command

  const AddExpenseScreen({
    super.key,
    this.jobId,
    this.existingExpense,
    this.prefilledReceipt,
    this.initialData,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.materials;
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;
  bool _taxDeductible = true;
  bool _isSubmitting = false;
  String? _receiptPath;
  String? _linkedReceiptId;
  String? _receiptOcrText;
  final Set<int> _deselectedReceiptItems = {};
  String? _selectedJobId;
  String? _selectedJobTitle;
  String? _selectedJobClientName;
  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existingExpense!;
      _descriptionController.text = e.description;
      _amountController.text = e.amount.toStringAsFixed(2);
      _vendorController.text = e.vendor ?? '';
      _selectedCategory = e.category;
      _selectedDate = e.expenseDate;
      _selectedPaymentMethod = e.paymentMethod ?? PaymentMethod.card;
      _taxDeductible = e.taxDeductible;
      _receiptPath = e.receiptPath;
      _receiptOcrText = e.ocrText;
      _selectedJobId = e.jobId ?? widget.jobId;
    } else if (widget.prefilledReceipt != null) {
      _applyScannedReceipt(widget.prefilledReceipt!, shouldNotify: false);
    } else if (widget.initialData != null) {
      final d = widget.initialData!;
      _descriptionController.text = d['description']?.toString() ?? '';
      final amt = d['amount'];
      if (amt != null) {
        _amountController.text = (amt is num) ? amt.toStringAsFixed(2) : amt.toString();
      }
      _vendorController.text = d['vendor']?.toString() ?? '';
      final cat = d['category']?.toString() ?? '';
      _selectedCategory = ExpenseCategory.values.firstWhere(
        (e) => e.name == cat,
        orElse: () => ExpenseCategory.materials,
      );
      if (d['taxDeductible'] == true) _taxDeductible = true;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedData {
    return _descriptionController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty ||
        _vendorController.text.trim().isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;
    if (!_hasUnsavedData || _isEditing) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Expense?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            TextFormField(
              key: const ValueKey('expense_description'),
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g., Lumber for deck project',
                prefixIcon: const Icon(Icons.description),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              key: const ValueKey('expense_amount'),
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: '$currencySymbol ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                if (double.tryParse(v.trim()) == null)
                  return 'Enter a valid amount';
                if (double.parse(v.trim()) <= 0)
                  return 'Amount must be positive';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(_getCategoryIcon(_selectedCategory)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(c),
                                size: 20, color: _getCategoryColor(c)),
                            const SizedBox(width: 10),
                            Text(c.displayName),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedCategory = v;
                  _taxDeductible = v.taxDeductible;
                });
              },
            ),
            const SizedBox(height: 16),

            // Vendor
            TextFormField(
              controller: _vendorController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Vendor / Store',
                hintText: 'e.g., Home Depot, Bunnings',
                prefixIcon: const Icon(Icons.store),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Text(
                  DateFormat('EEEE, MMM d, y').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: const Icon(Icons.payment),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPaymentMethod = v);
              },
            ),
            const SizedBox(height: 16),

            // Tax deductible toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _taxDeductible
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _taxDeductible
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tax Deductible',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _taxDeductible
                      ? 'This expense can be claimed on tax'
                      : 'Not a tax-deductible expense',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                value: _taxDeductible,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _taxDeductible = v),
              ),
            ),
            const SizedBox(height: 20),

            // Assign to Job (optional)
            _buildJobPicker(),
            const SizedBox(height: 20),

            // Receipt attach
            _buildReceiptSection(),
            const SizedBox(height: 16),

            // Extracted receipt line items (from AI scan)
            _buildExtractedItemsSection(),
            const SizedBox(height: 32),

            const SizedBox(height: 80), // space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: FilledButton(
          key: const ValueKey('expense_save'),
          onPressed: _isSubmitting ? null : _submitExpense,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2.5),
                )
              : Text(
                  _isEditing ? 'UPDATE EXPENSE' : 'ADD EXPENSE',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5),
                ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _scanReceiptWithAi,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Scan Receipt with AI'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_receiptPath != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4)),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_receiptPath!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(Icons.image,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              title: const Text('Receipt attached',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Tap to change', style: TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: Icon(Icons.close,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () => setState(() {
                  _receiptPath = null;
                  _linkedReceiptId = null;
                  _receiptOcrText = null;
                }),
              ),
              onTap: _pickReceipt,
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceipt(source: ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceipt(source: ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExtractedItemsSection() {
    if (_receiptOcrText == null || _receiptOcrText!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final result = ReceiptAiResult.fromJsonString(_receiptOcrText!);
    if (result.items.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Extracted Items',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${result.items.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tap items to include or exclude them',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('ITEM', style: _tableHeaderStyle),
                ),
                SizedBox(
                  width: 40,
                  child: Text('QTY',
                      style: _tableHeaderStyle, textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('PRICE',
                      style: _tableHeaderStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),

          // Item rows — user can deselect items
          ...result.items.asMap().entries.map((mapEntry) {
            final idx = mapEntry.key;
            final item = mapEntry.value;
            final isSelected = !_deselectedReceiptItems.contains(idx);
            return InkWell(
              onTap: () => setState(() {
                if (isSelected) {
                  _deselectedReceiptItems.add(idx);
                } else {
                  _deselectedReceiptItems.remove(idx);
                }
                // Recalculate amount based on selected items
                _recalculateReceiptAmount(result);
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? null : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Text(
                        item.name,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: isSelected ? null : TextDecoration.lineThrough,
                          color: isSelected ? null : colorScheme.outlineVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${item.quantity}',
                        style: textTheme.bodySmall?.copyWith(
                          color: isSelected ? colorScheme.onSurfaceVariant : colorScheme.outlineVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isSelected ? null : TextDecoration.lineThrough,
                          color: isSelected ? null : colorScheme.outlineVariant,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Totals footer — dynamically computed from selected items
          Builder(builder: (_) {
            // Compute reviewed subtotal from selected items only
            double reviewedSubtotal = 0;
            int selectedCount = 0;
            for (var i = 0; i < result.items.length; i++) {
              if (_deselectedReceiptItems.contains(i)) continue;
              selectedCount++;
              final item = result.items[i];
              reviewedSubtotal += item.totalPrice > 0
                  ? item.totalPrice
                  : item.unitPrice * item.quantity;
            }
            // Proportional tax: if the original receipt had tax, scale it
            // by the fraction of items kept
            final bool hasTax = result.tax != null && result.tax! > 0;
            final double reviewedTax;
            if (hasTax && result.subtotal != null && result.subtotal! > 0) {
              reviewedTax = result.tax! * (reviewedSubtotal / result.subtotal!);
            } else if (hasTax && result.total != null && result.total! > 0) {
              reviewedTax = result.tax! *
                  (reviewedSubtotal /
                      (result.total! - result.tax!).clamp(0.01, double.infinity));
            } else {
              reviewedTax = 0;
            }
            final double reviewedTotal = reviewedSubtotal + reviewedTax;
            final bool anyExcluded = _deselectedReceiptItems.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  if (anyExcluded)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '$selectedCount of ${result.items.length} items included',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  _itemTotalRow(
                      'Subtotal',
                      '$currencySymbol${reviewedSubtotal.toStringAsFixed(2)}',
                      colorScheme),
                  if (hasTax)
                    _itemTotalRow(
                        'Tax${anyExcluded ? ' (est.)' : ''}',
                        '$currencySymbol${reviewedTax.toStringAsFixed(2)}',
                        colorScheme),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          anyExcluded ? 'Reviewed Total' : 'Total',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$currencySymbol${reviewedTotal.toStringAsFixed(2)}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _itemTotalRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _tableHeaderStyle => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: 0.7),
      );

  Widget _buildJobPicker() {
    // Resolve job title/client from provider if we have a jobId but no title yet
    if (_selectedJobId != null && _selectedJobTitle == null) {
      final jobs = ref.read(jobListProvider).jobs;
      final match = jobs.where((j) => j.id == _selectedJobId).firstOrNull;
      if (match != null) {
        _selectedJobTitle = match.title;
        _selectedJobClientName = match.clientName;
      }
    }

    final hasSelection = _selectedJobId != null;
    final displayText = hasSelection
        ? '${_selectedJobTitle ?? 'Job'}${_selectedJobClientName != null ? ' · ${_selectedJobClientName!}' : ''}'
        : 'Tap to assign a job';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign to Job (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showJobSelector,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasSelection
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              color: hasSelection
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Row(
              children: [
                Icon(
                  hasSelection ? Icons.work : Icons.work_outline,
                  color: hasSelection
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasSelection
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSelection)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedJobId = null;
                      _selectedJobTitle = null;
                      _selectedJobClientName = null;
                    }),
                    child: Icon(Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                else
                  Icon(Icons.chevron_right,
                      color: Theme.of(context).colorScheme.outlineVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showJobSelector() {
    final jobs = ref.read(jobListProvider).jobs;

    if (jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No jobs found. Create a job first.')),
      );
      return;
    }

    // Sort: active jobs first, then by creation date descending
    final sorted = List<Job>.from(jobs)
      ..sort((a, b) {
        if (a.status.isActive && !b.status.isActive) return -1;
        if (!a.status.isActive && b.status.isActive) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Job',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: sorted.map((job) {
                      final isSelected = job.id == _selectedJobId;
                      // Build a meaningful subtitle that does NOT
                      // repeat the title.  Priority order:
                      //   1. client name (if different from title)
                      //   2. trade
                      //   3. status + type
                      //   4. nothing (single-line row)
                      String? subtitle;
                      if (job.clientName.isNotEmpty &&
                          job.clientName.toLowerCase().trim() !=
                              job.title.toLowerCase().trim()) {
                        subtitle = job.clientName;
                      } else if (job.trade != null &&
                          job.trade!.isNotEmpty) {
                        subtitle = job.trade!;
                      } else if (job.status.isActive) {
                        subtitle =
                            '${job.type.displayName} · ${job.status.displayName}';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.work,
                            size: 18,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(job.title,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600)),
                        subtitle: subtitle != null
                            ? Text(subtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant))
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedJobId = job.id;
                            _selectedJobTitle = job.title;
                            _selectedJobClientName = job.clientName;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickReceipt({ImageSource? source}) async {
    final src = source ?? ImageSource.gallery;
    final image = await ImagePicker().pickImage(
      source: src,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _receiptPath = image.path;
        _linkedReceiptId = null;
        _receiptOcrText = null;
      });
    }
  }

  Future<void> _scanReceiptWithAi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
    );
    if (!mounted || result is! domain_receipt.Receipt) return;

    _applyScannedReceipt(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt scanned and fields auto-filled'),
        backgroundColor: AppColors.paid(context),
      ),
    );
  }

  void _applyScannedReceipt(
    domain_receipt.Receipt receipt, {
    bool shouldNotify = true,
  }) {
    final suggestedCategory = _suggestCategoryFromReceipt(receipt);
    final suggestedAmount = _resolveReceiptAmount(receipt);
    final suggestedDescription =
        (receipt.extractedVendor?.trim().isNotEmpty ?? false)
            ? '${receipt.extractedVendor!.trim()} purchase'
            : 'Receipt expense';

    final apply = () {
      _receiptPath = receipt.imagePath;
      _linkedReceiptId = receipt.id;
      // Save AI-extracted items JSON so expense detail can show the itemized table
      _receiptOcrText = receipt.extractedItemsJson ?? receipt.ocrText;

      if (suggestedAmount != null && suggestedAmount > 0) {
        _amountController.text = suggestedAmount.toStringAsFixed(2);
      }
      if (_vendorController.text.trim().isEmpty &&
          (receipt.extractedVendor?.trim().isNotEmpty ?? false)) {
        _vendorController.text = receipt.extractedVendor!.trim();
      }
      if (_descriptionController.text.trim().isEmpty) {
        _descriptionController.text = suggestedDescription;
      }
      if (receipt.extractedDate != null) {
        _selectedDate = receipt.extractedDate!;
      }
      _selectedCategory = suggestedCategory;
      _taxDeductible = suggestedCategory.taxDeductible;
    };

    if (shouldNotify) {
      setState(apply);
    } else {
      apply();
    }
  }

  double? _resolveReceiptAmount(domain_receipt.Receipt receipt) {
    final rawItemsJson = receipt.extractedItemsJson;
    if (rawItemsJson != null && rawItemsJson.trim().isNotEmpty) {
      final aiResult = ReceiptAiResult.fromJsonString(rawItemsJson);
      final total = aiResult.total ?? aiResult.subtotal;
      if (total != null && total > 0) return total;

      final itemsTotal = aiResult.items.fold<double>(0.0, (sum, item) {
        final lineTotal = item.totalPrice > 0
            ? item.totalPrice
            : item.unitPrice * item.quantity;
        return sum + lineTotal;
      });
      if (itemsTotal > 0) return itemsTotal;
    }

    if (receipt.extractedAmount != null && receipt.extractedAmount! > 0) {
      return receipt.extractedAmount;
    }
    return null;
  }

  /// Recalculate the amount field based on which receipt items are selected.
  /// Includes proportional tax if the original receipt had tax.
  void _recalculateReceiptAmount(ReceiptAiResult result) {
    double subtotal = 0;
    for (var i = 0; i < result.items.length; i++) {
      if (_deselectedReceiptItems.contains(i)) continue;
      final item = result.items[i];
      subtotal += item.totalPrice > 0
          ? item.totalPrice
          : item.unitPrice * item.quantity;
    }
    // Proportional tax
    double tax = 0;
    if (result.tax != null && result.tax! > 0) {
      if (result.subtotal != null && result.subtotal! > 0) {
        tax = result.tax! * (subtotal / result.subtotal!);
      } else if (result.total != null && result.total! > 0) {
        final origSubtotal =
            (result.total! - result.tax!).clamp(0.01, double.infinity);
        tax = result.tax! * (subtotal / origSubtotal);
      }
    }
    _amountController.text = (subtotal + tax).toStringAsFixed(2);
  }

  ExpenseCategory _suggestCategoryFromReceipt(domain_receipt.Receipt receipt) {
    final haystack = [
      receipt.extractedVendor ?? '',
      receipt.ocrText ?? '',
    ].join(' ').toLowerCase();

    if (RegExp(r'\b(fuel|gas|diesel|petrol|shell|bp|chevron|mobil)\b')
        .hasMatch(haystack)) {
      return ExpenseCategory.fuel;
    }
    if (RegExp(r'\b(tool|drill|saw|hardware|equipment)\b').hasMatch(haystack)) {
      return ExpenseCategory.tools;
    }
    if (RegExp(r'\b(permit|license|licence|fee|inspection)\b')
        .hasMatch(haystack)) {
      return ExpenseCategory.fees;
    }
    if (RegExp(r'\b(cafe|restaurant|coffee|meal|lunch|dinner)\b')
        .hasMatch(haystack)) {
      return ExpenseCategory.meals;
    }
    if (RegExp(r'\b(office|paper|printer|stationery|staples)\b')
        .hasMatch(haystack)) {
      return ExpenseCategory.supplies;
    }
    if (RegExp(
            r'\b(home depot|lowe|bunnings|lumber|timber|pipe|valve|material)\b')
        .hasMatch(haystack)) {
      return ExpenseCategory.materials;
    }
    return ExpenseCategory.other;
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(userIdProvider);
      if (userId == null) throw Exception('Not authenticated');

      final expenseId =
          _isEditing ? widget.existingExpense!.id : const Uuid().v4();
      String? resolvedReceiptPath = _receiptPath;
      String? resolvedReceiptUrl =
          _isEditing ? widget.existingExpense?.receiptUrl : null;
      // If user deselected receipt items, persist only the included ones
      String? resolvedReceiptOcr = _receiptOcrText;
      if (_deselectedReceiptItems.isNotEmpty && resolvedReceiptOcr != null) {
        try {
          final parsed = ReceiptAiResult.fromJsonString(resolvedReceiptOcr);
          if (parsed.items.isNotEmpty) {
            final kept = <ReceiptLineItem>[];
            for (var i = 0; i < parsed.items.length; i++) {
              if (!_deselectedReceiptItems.contains(i)) {
                kept.add(parsed.items[i]);
              }
            }
            // Recalculate subtotal/total for kept items
            double keptSubtotal = 0;
            for (final item in kept) {
              keptSubtotal += item.totalPrice > 0
                  ? item.totalPrice
                  : item.unitPrice * item.quantity;
            }
            double keptTax = 0;
            if (parsed.tax != null && parsed.tax! > 0 &&
                parsed.subtotal != null && parsed.subtotal! > 0) {
              keptTax = parsed.tax! * (keptSubtotal / parsed.subtotal!);
            }
            final filtered = ReceiptAiResult(
              storeName: parsed.storeName,
              items: kept,
              subtotal: keptSubtotal,
              tax: keptTax > 0 ? keptTax : null,
              total: keptSubtotal + keptTax,
              date: parsed.date,
            );
            resolvedReceiptOcr = filtered.toJsonString();
          }
        } catch (_) {
          // If parsing fails, keep original
        }
      }

      if (_linkedReceiptId != null && _linkedReceiptId!.isNotEmpty) {
        final linked = await ref
            .read(receiptProvider.notifier)
            .getReceiptById(_linkedReceiptId!);
        if (linked != null) {
          resolvedReceiptPath = linked.imagePath;
          resolvedReceiptUrl = linked.imageUrl ?? resolvedReceiptUrl;
          resolvedReceiptOcr =
              linked.extractedItemsJson ?? linked.ocrText ?? resolvedReceiptOcr;
        }
      } else if (resolvedReceiptPath == null ||
          resolvedReceiptPath.trim().isEmpty) {
        resolvedReceiptUrl = null;
        resolvedReceiptOcr = null;
      } else {
        final shouldUploadManualReceipt = !_isEditing ||
            widget.existingExpense?.receiptPath != resolvedReceiptPath ||
            (widget.existingExpense?.receiptUrl?.isEmpty ?? true);

        if (shouldUploadManualReceipt) {
          final uploaded = await _backupManualReceiptToCloud(
            userId: userId,
            expenseId: expenseId,
            imagePath: resolvedReceiptPath,
          );
          if (uploaded != null) {
            resolvedReceiptUrl = uploaded;
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receipt image could not be uploaded. Expense saved without cloud backup.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Derive customerId from selected job if available
      String? resolvedJobId = _selectedJobId ?? widget.jobId ?? widget.existingExpense?.jobId;
      String? resolvedCustomerId;
      if (resolvedJobId != null) {
        final jobs = ref.read(jobListProvider).jobs;
        final match = jobs.where((j) => j.id == resolvedJobId).firstOrNull;
        resolvedCustomerId = match?.customerId;
      }

      final expense = Expense(
        id: expenseId,
        userId: userId,
        jobId: resolvedJobId,
        customerId: resolvedCustomerId,
        description: _descriptionController.text.trim(),
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text.trim()),
        expenseDate: _selectedDate,
        receiptPath: resolvedReceiptPath,
        receiptUrl: resolvedReceiptUrl,
        ocrText: resolvedReceiptOcr,
        taxDeductible: _taxDeductible,
        paymentMethod: _selectedPaymentMethod,
        createdAt:
            _isEditing ? widget.existingExpense!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        final success = await ref
            .read(expenseListProvider.notifier)
            .updateExpense(expense.id, expense);
        if (success && mounted) {
          ref.invalidate(costBreakdownProvider);
          ref.invalidate(costLedgerProvider);
          try {
            ProviderScope.containerOf(context)
                .read(analyticsProvider.notifier)
                .refresh();
          } catch (e) {
            debugPrint('Analytics refresh after expense update failed: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Expense updated'),
                backgroundColor: AppColors.paid(context)),
          );
          Navigator.of(context).pop(expense);
        }
      } else {
        final created =
            await ref.read(expenseListProvider.notifier).createExpense(expense);
        if (created != null && mounted) {
          if (_linkedReceiptId != null && _linkedReceiptId!.isNotEmpty) {
            await ref
                .read(receiptProvider.notifier)
                .linkToExpense(_linkedReceiptId!, created.id);
          }
          ref.invalidate(costBreakdownProvider);
          ref.invalidate(costLedgerProvider);
          try {
            ProviderScope.containerOf(context)
                .read(analyticsProvider.notifier)
                .refresh();
          } catch (e) {
            debugPrint('Analytics refresh after expense create failed: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Expense added'),
                backgroundColor: AppColors.paid(context)),
          );
          Navigator.of(context).pop(created);
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final isOffline = msg.contains('socketexception') || msg.contains('network');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline
                ? 'No internet connection. Please check your network and try again.'
                : 'Failed to save expense. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String?> _backupManualReceiptToCloud({
    required String userId,
    required String expenseId,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final supabase = ref.read(supabaseServiceProvider);
    try {
      await supabase.ensureValidSession();
      final ext = _normalizedFileExtension(imagePath);
      final storagePath = [
        userId,
        'expenses',
        expenseId,
        'receipt.$ext',
      ].join('/');

      await supabase.uploadFile(
        bucket: 'receipts',
        path: storagePath,
        file: file,
        contentType: _imageContentType(ext),
      );

      return await supabase.client.storage
          .from('receipts')
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
    } catch (e) {
      debugPrint('Receipt upload/signed URL generation failed: $e');
      return null;
    }
  }

  String _normalizedFileExtension(String path) {
    final segments = path.split('.');
    if (segments.length < 2) return 'jpg';
    final ext = segments.last.trim().toLowerCase();
    if (ext.isEmpty) return 'jpg';
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  String _imageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  IconData _getCategoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.materials:
        return Icons.construction;
      case ExpenseCategory.labor:
        return Icons.people;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.tools:
        return Icons.build;
      case ExpenseCategory.supplies:
        return Icons.inventory;
      case ExpenseCategory.insurance:
        return Icons.shield;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.fees:
        return Icons.account_balance;
      case ExpenseCategory.meals:
        return Icons.restaurant;
      case ExpenseCategory.other:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.materials:
        return Colors.orange;
      case ExpenseCategory.labor:
        return Colors.blue;
      case ExpenseCategory.fuel:
        return Colors.green;
      case ExpenseCategory.tools:
        return Colors.purple;
      case ExpenseCategory.supplies:
        return Colors.teal;
      case ExpenseCategory.insurance:
        return Colors.indigo;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.fees:
        return Colors.brown;
      case ExpenseCategory.meals:
        return Colors.red;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}
