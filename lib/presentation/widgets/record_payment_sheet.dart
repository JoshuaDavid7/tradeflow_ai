import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/job_repository.dart';
import '../providers/profile_provider.dart';

/// Payment method options for the dropdown.
const _paymentMethods = <(String key, String label, IconData icon)>[
  ('cash', 'Cash', Icons.money),
  ('card', 'Card', Icons.credit_card),
  ('check', 'Check', Icons.receipt_long),
  ('zelle', 'Zelle', Icons.send),
  ('venmo', 'Venmo', Icons.phone_iphone),
  ('cash_app', 'Cash App', Icons.attach_money),
  ('paypal', 'PayPal', Icons.payment),
  ('bank_transfer', 'Bank Transfer', Icons.account_balance),
  ('stripe', 'Stripe', Icons.credit_card),
  ('other', 'Other', Icons.more_horiz),
];

/// Show the Record Payment bottom sheet.
///
/// Returns `true` if a payment was successfully recorded, `null` or `false`
/// if the user cancelled.
Future<bool?> showRecordPaymentSheet(
  BuildContext context, {
  required String jobId,
  required double totalAmount,
  required double amountPaid,
  required String clientName,
  double? initialAmount,
  String? initialMethod,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: RecordPaymentSheet(
        jobId: jobId,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        clientName: clientName,
        initialAmount: initialAmount,
        initialMethod: initialMethod,
      ),
    ),
  );
}

/// A bottom-sheet form for recording a manual payment against an invoice.
///
/// Supports partial and full payments, payment method selection, date
/// backdating, and optional reference/notes fields.
class RecordPaymentSheet extends ConsumerStatefulWidget {
  final String jobId;
  final double totalAmount;
  final double amountPaid;
  final String clientName;
  final double? initialAmount;
  final String? initialMethod;

  const RecordPaymentSheet({
    super.key,
    required this.jobId,
    required this.totalAmount,
    required this.amountPaid,
    required this.clientName,
    this.initialAmount,
    this.initialMethod,
  });

  @override
  ConsumerState<RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  double get _remainingBalance => widget.totalAmount - widget.amountPaid;

  /// The amount currently typed into the field (or 0 if invalid).
  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  /// Whether the entered amount settles the full remaining balance.
  bool get _isFullPayment =>
      (_remainingBalance - _enteredAmount).abs() < 0.01;

  /// Remaining balance after the currently-entered amount.
  double get _remainingAfterPayment =>
      (_remainingBalance - _enteredAmount).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    final requestedAmount = widget.initialAmount ?? _remainingBalance;
    final safeAmount =
        requestedAmount.clamp(0.0, _remainingBalance).toDouble();
    _amountController = TextEditingController(
      text: safeAmount > 0
          ? safeAmount.toStringAsFixed(2)
          : _remainingBalance.toStringAsFixed(2),
    );
    final requestedMethod =
        (widget.initialMethod ?? '').trim().toLowerCase();
    final supportedMethods = _paymentMethods.map((entry) => entry.$1).toSet();
    if (supportedMethods.contains(requestedMethod)) {
      _selectedMethod = requestedMethod;
    }
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > _remainingBalance + 0.01) {
      return 'Cannot exceed remaining balance '
          '(\$${_remainingBalance.toStringAsFixed(2)})';
    }
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(jobRepositoryProvider);
      final amount = double.parse(_amountController.text.trim());

      await repository.recordPayment(
        widget.jobId,
        amount,
        _selectedMethod,
        receivedAt: _selectedDate,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_userFriendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencySymbol = ref.watch(currencySymbolProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title & client ──
            Text('Record Payment',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.clientName,
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),

            // ── Balance summary strip ──
            _buildBalanceSummary(colorScheme, textTheme, currencySymbol),
            const SizedBox(height: 20),

            // ── Form ──
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Amount received
                  TextFormField(
                    key: const ValueKey('payment_amount_field'),
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount received',
                      prefixText: '$currencySymbol ',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: _validateAmount,
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),

                  // Remaining after payment (live preview)
                  _buildRemainingPreview(colorScheme, textTheme, currencySymbol),
                  const SizedBox(height: 16),

                  // Payment method
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                    items: _paymentMethods
                        .map((m) => DropdownMenuItem(
                              value: m.$1,
                              child: Row(
                                children: [
                                  Icon(m.$3, size: 20,
                                      color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 10),
                                  Text(m.$2),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedMethod = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Payment Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                      ),
                      child: Text(
                        DateFormat('EEEE, MMM d, y').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reference (optional)
                  TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      labelText: 'Reference / Transaction ID',
                      hintText: 'e.g., Check #1234, Venmo txn',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes (optional)
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit button ──
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitPayment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isFullPayment
                    ? 'Record Full Payment'
                    : 'Record Partial Payment',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.paid(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Three-column read-only strip: Invoice Total | Already Paid | Remaining.
  Widget _buildBalanceSummary(
      ColorScheme colorScheme, TextTheme textTheme, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _balanceCell(
            label: 'Invoice Total',
            value: '$currencySymbol${widget.totalAmount.toStringAsFixed(2)}',
            color: colorScheme.onSurface,
            textTheme: textTheme,
          ),
          _divider(colorScheme),
          _balanceCell(
            label: 'Already Paid',
            value: '$currencySymbol${widget.amountPaid.toStringAsFixed(2)}',
            color: AppColors.paid(context),
            textTheme: textTheme,
          ),
          _divider(colorScheme),
          _balanceCell(
            label: 'Remaining',
            value: '$currencySymbol${_remainingBalance.toStringAsFixed(2)}',
            color: _remainingBalance > 0
                ? AppColors.overdue(context)
                : AppColors.paid(context),
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _balanceCell({
    required String label,
    required String value,
    required Color color,
    required TextTheme textTheme,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: textTheme.labelSmall
                  ?.copyWith(color: color.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 32,
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  /// Convert an exception to a user-friendly error message.
  String _userFriendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') || msg.contains('no internet') || msg.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('invalid_status') || msg.contains('cancelled')) {
      return 'This invoice has been cancelled and cannot accept payments.';
    }
    if (msg.contains('zero_total') || msg.contains('\$0')) {
      return 'This invoice has a \$0 balance and cannot accept payments.';
    }
    return 'Payment could not be recorded. Please try again.';
  }

  /// Live-updating remaining balance preview below the amount field.
  Widget _buildRemainingPreview(
      ColorScheme colorScheme, TextTheme textTheme, String currencySymbol) {
    final entered = _enteredAmount;
    final isValid = entered > 0 && entered <= _remainingBalance + 0.01;

    if (!isValid && entered > 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Exceeds remaining balance',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          _isFullPayment
              ? 'This will settle the invoice in full'
              : 'Remaining after payment: '
                  '$currencySymbol${_remainingAfterPayment.toStringAsFixed(2)}',
          style: textTheme.bodySmall?.copyWith(
            color: _isFullPayment
                ? AppColors.paid(context)
                : colorScheme.onSurfaceVariant,
            fontWeight:
                _isFullPayment ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
