import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tradeflow_ai/domain/models/receipt.dart' as domain_receipt;
import 'package:tradeflow_ai/domain/models/expense.dart';
import 'package:uuid/uuid.dart';
import 'package:tradeflow_ai/data/services/receipt_ai_service.dart';
import 'package:tradeflow_ai/presentation/providers/expense_provider.dart';
import 'package:tradeflow_ai/presentation/providers/analytics_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../../../screens/draft_review_screen.dart';

/// Router screen shown after scanning a receipt.
///
/// Displays the parsed receipt data and lets the user choose where to
/// route it: Expense, Invoice/Quote, or Both.
class ScanResultRouterScreen extends ConsumerStatefulWidget {
  final domain_receipt.Receipt receipt;

  const ScanResultRouterScreen({super.key, required this.receipt});

  @override
  ConsumerState<ScanResultRouterScreen> createState() =>
      _ScanResultRouterScreenState();
}

class _ScanResultRouterScreenState
    extends ConsumerState<ScanResultRouterScreen> {
  late final ReceiptAiResult _aiResult;
  late final bool _hasItems;

  @override
  void initState() {
    super.initState();
    // Parse the AI-extracted data from the receipt
    final json = widget.receipt.extractedItemsJson;
    if (json != null && json.isNotEmpty) {
      _aiResult = ReceiptAiResult.fromJsonString(json);
      _hasItems = _aiResult.items.isNotEmpty;
    } else {
      _aiResult = const ReceiptAiResult();
      _hasItems = false;
    }
  }

  // ─── Build materials list for DraftReviewScreen ───────────────────────────
  List<Map<String, dynamic>> _buildMaterialsList() {
    if (_hasItems) {
      return _aiResult.items
          .map((item) => <String, dynamic>{
                'id': const Uuid().v4(),
                'item': item.name,
                'cost': item.totalPrice,
                'originalCost': item.totalPrice,
                'fromReceipt': true,
              })
          .toList();
    }
    // Fallback: single item from extractedAmount
    final amount = widget.receipt.extractedAmount ?? 0.0;
    final vendor = widget.receipt.extractedVendor ?? 'Scanned item';
    return [
      {
        'id': const Uuid().v4(),
        'item': vendor,
        'cost': amount,
        'originalCost': amount,
        'fromReceipt': true,
      }
    ];
  }

  // ─── Action handlers ─────────────────────────────────────────────────────

  Future<void> _addToExpense() async {
    unawaited(HapticFeedback.lightImpact());
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(prefilledReceipt: widget.receipt),
      ),
    );
    if (!mounted) return;
    ref.invalidate(expenseStatsProvider);
    await ref.read(analyticsProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addToInvoiceOrQuote() async {
    unawaited(HapticFeedback.lightImpact());
    final type = await _showTypePicker();
    if (type == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DraftReviewScreen(
          jobData: {
            'type': type,
            'materials': _buildMaterialsList(),
          },
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _useForBoth() async {
    unawaited(HapticFeedback.lightImpact());

    // Step 1: Route to Expense first
    final expenseResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(prefilledReceipt: widget.receipt),
      ),
    );
    if (!mounted) return;

    // Refresh expense stats regardless
    ref.invalidate(expenseStatsProvider);
    await ref.read(analyticsProvider.notifier).refresh();

    // Step 2: Only show follow-up if the expense was successfully saved
    // AddExpenseScreen pops with an Expense object on success, null/void on cancel
    if (expenseResult is! Expense) {
      // User cancelled or backed out — do NOT show follow-up
      return;
    }

    if (!mounted) return;

    // Step 3: Show follow-up prompt
    final followUpType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expense saved'),
        content: const Text(
          'Also add these items to an invoice or quote?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, 'quote'),
            child: const Text('Add to Quote'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'invoice'),
            child: const Text('Add to Invoice'),
          ),
        ],
      ),
    );

    if (followUpType == null || !mounted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Step 4: Navigate to Invoice/Quote with the same scanned items.
    // Thread the expense ID so recognition-on-send can auto-link
    // the material costs to this expense (prevents double-counting).
    final savedExpense = expenseResult as Expense;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DraftReviewScreen(
          jobData: {
            'type': followUpType,
            'materials': _buildMaterialsList(),
            '_pendingExpenseLink': {
              'expenseId': savedExpense.id,
              'amount': savedExpense.amount,
            },
          },
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  /// Show a small bottom sheet to choose Invoice vs Quote
  Future<String?> _showTypePicker() async {
    final colorScheme = Theme.of(context).colorScheme;

    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add to',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.receipt_long_rounded,
                      color: colorScheme.primary),
                ),
                title: const Text('Invoice',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Bill completed work'),
                onTap: () => Navigator.pop(ctx, 'invoice'),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.tertiary.withValues(alpha: 0.1),
                  child: Icon(Icons.request_quote_rounded,
                      color: colorScheme.tertiary),
                ),
                title: const Text('Quote',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send price estimate'),
                onTap: () => Navigator.pop(ctx, 'quote'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final vendor = _aiResult.storeName ?? widget.receipt.extractedVendor;
    final date = _aiResult.date ?? (widget.receipt.extractedDate != null
        ? DateFormat('MMM d, yyyy').format(widget.receipt.extractedDate!)
        : null);
    final total = _aiResult.total ?? widget.receipt.extractedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Receipt'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable parsed data summary ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // Vendor + date header
                  if (vendor != null || date != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.store_rounded,
                                color: colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (vendor != null)
                                  Text(
                                    vendor,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (date != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    date,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (total != null)
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Line items table
                  if (_hasItems) ...[
                    Text(
                      'Extracted Items',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('ITEM',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      )),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text('QTY',
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      )),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text('PRICE',
                                      textAlign: TextAlign.right,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 0.5,
                            color:
                                colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                          // Line items
                          ...List.generate(_aiResult.items.length, (i) {
                            final item = _aiResult.items[i];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item.name,
                                          style: textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodySmall,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '\$${item.totalPrice.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < _aiResult.items.length - 1)
                                  Divider(
                                    height: 0.5,
                                    indent: 14,
                                    endIndent: 14,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.2),
                                  ),
                              ],
                            );
                          }),
                          // Totals row
                          if (_aiResult.subtotal != null ||
                              _aiResult.tax != null ||
                              _aiResult.total != null) ...[
                            Divider(
                              height: 0.5,
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                children: [
                                  if (_aiResult.subtotal != null)
                                    _buildTotalRow(
                                      context,
                                      'Subtotal',
                                      '\$${_aiResult.subtotal!.toStringAsFixed(2)}',
                                    ),
                                  if (_aiResult.tax != null)
                                    _buildTotalRow(
                                      context,
                                      'Tax',
                                      '\$${_aiResult.tax!.toStringAsFixed(2)}',
                                    ),
                                  if (_aiResult.total != null)
                                    _buildTotalRow(
                                      context,
                                      'Total',
                                      '\$${_aiResult.total!.toStringAsFixed(2)}',
                                      isBold: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (total != null) ...[
                    // Fallback: no itemized data but we have a total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'No itemized data extracted',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: \$${total.toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Action buttons (pinned to bottom) ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary: Add to Expense
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _addToExpense,
                      icon: const Icon(Icons.add_card_rounded, size: 18),
                      label: const Text('Add to Expense'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Secondary: Add to Invoice or Quote
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: _addToInvoiceOrQuote,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Add to Invoice or Quote'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tertiary: Use for Both
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _useForBoth,
                      child: const Text('Use for Both'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
