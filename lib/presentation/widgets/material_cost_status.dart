import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/database.dart';
import '../../data/repositories/material_cost_repository.dart';
import '../../data/services/receipt_ai_service.dart';
import '../../presentation/providers/analytics_provider.dart';
import '../../presentation/providers/expense_provider.dart';
import '../../core/theme/app_theme.dart';

/// Shows the material cost recognition status for a sent invoice.
/// Each material line displays: name, cost basis, status badge, and
/// a link/unlink action. Potential matches are surfaced as suggestions.
class MaterialCostStatusSection extends ConsumerStatefulWidget {
  final String jobId;
  final String userId;
  final String currencySymbol;

  const MaterialCostStatusSection({
    super.key,
    required this.jobId,
    required this.userId,
    required this.currencySymbol,
  });

  @override
  ConsumerState<MaterialCostStatusSection> createState() =>
      _MaterialCostStatusSectionState();
}

class _MaterialCostStatusSectionState
    extends ConsumerState<MaterialCostStatusSection> {
  List<RecognizedMaterialCost> _costs = [];
  Map<String, List<MaterialCostLink>> _links = {};
  bool _isLoading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final costs = await db.materialCostDao.getByJob(widget.jobId);
      final links = <String, List<MaterialCostLink>>{};
      for (final c in costs) {
        links[c.id] = await db.materialCostDao.getLinksForCost(c.id);
      }
      if (mounted) {
        setState(() {
          _costs = costs;
          _links = links;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Material cost status load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _costs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cs = widget.currencySymbol;

    final unlinkedCount = _costs.where((c) {
      final costLinks = _links[c.id] ?? [];
      return costLinks.isEmpty;
    }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            key: const ValueKey('material_cost_section_header'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.receipt_long,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Material Costs (${_costs.length})',
                      style: textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (unlinkedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$unlinkedCount estimated',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: _costs.map((cost) {
                  final costLinks = _links[cost.id] ?? [];
                  final isLinked = costLinks.isNotEmpty;
                  final statusColor = isLinked
                      ? AppColors.paid(context)
                      : Colors.amber.shade700;
                  final statusLabel =
                      isLinked ? 'Receipt linked' : 'No receipt';
                  final statusIcon =
                      isLinked ? Icons.check_circle_outline : Icons.schedule;

                  return Container(
                    key: ValueKey('material_cost_row_${cost.id}'),
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status icon
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 8),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cost.description,
                                style: textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '$cs${cost.canonicalCost.toStringAsFixed(2)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action button
                        if (isLinked)
                          TextButton(
                            key: ValueKey('material_cost_unlink_${cost.id}'),
                            onPressed: () => _confirmUnlinkCost(cost),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Unlink',
                                style: TextStyle(
                                    fontSize: 11, color: colorScheme.error)),
                          )
                        else
                          TextButton(
                            key: ValueKey('material_cost_link_${cost.id}'),
                            onPressed: () => _showLinkPicker(cost),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Link',
                                style: TextStyle(
                                    fontSize: 11, color: colorScheme.primary)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showLinkPicker(RecognizedMaterialCost cost) async {
    final repo = ref.read(materialCostRepositoryProvider);
    final db = ref.read(databaseProvider);

    // Fetch all material-category expenses for the user
    final allExpenses = await db.expenseDao.getAllExpenses(widget.userId);
    final materialExpenses =
        allExpenses.where((e) => e.category == 'materials').toList();

    // Build allocation map: expenseId -> total already allocated
    final allocationMap = <String, double>{};
    for (final e in materialExpenses) {
      final links = await db.materialCostDao.getLinksForExpense(e.id);
      if (links.isNotEmpty) {
        allocationMap[e.id] =
            links.fold<double>(0.0, (sum, l) => sum + l.allocatedAmount);
      }
    }

    if (!mounted) return;

    // Find potential matches
    final expenseMaps = materialExpenses
        .map((e) => {
              'id': e.id,
              'description': e.description,
              'amount': e.amount,
              'category': e.category,
              'expense_date': e.expenseDate.toIso8601String(),
              'job_id': e.jobId,
            })
        .toList();
    final suggestions = await repo.findPotentialMatches(cost, expenseMaps);

    if (!mounted) return;

    final cs = widget.currencySymbol;
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Link "${cost.description}" to a receipt',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Currently using invoice estimate: $cs${cost.provisionalCost.toStringAsFixed(2)}.\n'
                    'Link a logged expense to use the actual cost instead.',
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onSurfaceVariant,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Suggested matches',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Suggestions first
                      ...suggestions.map((s) {
                        final diff = s.expenseAmount - cost.provisionalCost;
                        final diffLabel = diff.abs() < 0.01
                            ? 'Exact match'
                            : '${diff >= 0 ? "+" : ""}$cs${diff.toStringAsFixed(2)} vs estimate';
                        final allocated =
                            allocationMap[s.expenseId] ?? 0.0;
                        final hasAllocation = allocated > 0;
                        return ListTile(
                            key: ValueKey(
                                'material_cost_pick_suggested_${cost.id}_${s.expenseId}'),
                            leading: Icon(Icons.auto_awesome,
                                color: Colors.amber.shade700, size: 20),
                            title: Text(s.expenseDescription,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text:
                                      '$cs${s.expenseAmount.toStringAsFixed(2)} · $diffLabel'),
                              if (hasAllocation)
                                TextSpan(
                                  text:
                                      '\n$cs${allocated.toStringAsFixed(2)} allocated · $cs${(s.expenseAmount - allocated).toStringAsFixed(2)} remaining',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.paid(ctx)),
                                ),
                            ])),
                            trailing: FilledButton.tonal(
                              key: ValueKey(
                                  'material_cost_pick_suggested_button_${cost.id}_${s.expenseId}'),
                              onPressed: () {
                                Navigator.pop(ctx, s.expenseId);
                              },
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Link',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          );
                      }),
                      if (suggestions.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Text(
                            'Other material expenses',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      // All material expenses
                      ...materialExpenses.map((e) {
                        final isSuggested =
                            suggestions.any((s) => s.expenseId == e.id);
                        if (isSuggested) return const SizedBox.shrink();
                        final allocated = allocationMap[e.id] ?? 0.0;
                        final hasAllocation = allocated > 0;
                        return ListTile(
                          key: ValueKey(
                              'material_cost_pick_all_${cost.id}_${e.id}'),
                          leading: Icon(Icons.receipt_outlined,
                              color: colorScheme.onSurfaceVariant, size: 20),
                          title: Text(e.description,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text.rich(TextSpan(children: [
                            TextSpan(
                                text:
                                    '$cs${e.amount.toStringAsFixed(2)} · ${DateFormat('MMM d').format(e.expenseDate)}'),
                            if (hasAllocation)
                              TextSpan(
                                text:
                                    '\n$cs${allocated.toStringAsFixed(2)} allocated · $cs${(e.amount - allocated).toStringAsFixed(2)} remaining',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.paid(ctx)),
                              ),
                          ])),
                          trailing: TextButton(
                            key: ValueKey(
                                'material_cost_pick_all_button_${cost.id}_${e.id}'),
                            onPressed: () => Navigator.pop(ctx, e.id),
                            child: const Text('Link',
                                style: TextStyle(fontSize: 12)),
                          ),
                        );
                      }),
                      if (materialExpenses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No material expenses found.\nLog a receipt or expense first.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((selectedExpenseId) async {
      if (selectedExpenseId == null || selectedExpenseId is! String) return;
      if (!mounted) return;

      // Find the selected expense
      final expense = materialExpenses.firstWhere(
        (e) => e.id == selectedExpenseId,
        orElse: () => materialExpenses.first,
      );

      // Try to find receipt with parsed line items for this expense
      List<ReceiptLineItem> receiptItems = [];
      try {
        final receipt =
            await db.receiptDao.getReceiptByExpenseId(selectedExpenseId);
        if (receipt != null && receipt.extractedItemsJson != null) {
          final aiResult =
              ReceiptAiResult.fromJsonString(receipt.extractedItemsJson!);
          receiptItems = aiResult.items;
        }
      } catch (e) {
        debugPrint('Failed to load receipt items: $e');
      }

      if (!mounted) return;

      double? allocatedAmount;

      if (receiptItems.isNotEmpty) {
        // Show receipt line items for the user to pick from
        allocatedAmount = await _showReceiptItemPicker(
          context: context,
          materialName: cost.description,
          receiptName: expense.description,
          receiptTotal: expense.amount,
          items: receiptItems,
          invoiceEstimate: cost.provisionalCost,
          currencySymbol: widget.currencySymbol,
        );
      } else {
        // Fallback: no parsed items available — show manual entry
        final existingLinks =
            await db.materialCostDao.getLinksForExpense(selectedExpenseId);
        final alreadyAllocated = existingLinks.fold<double>(
            0.0, (sum, link) => sum + link.allocatedAmount);
        final remaining = expense.amount - alreadyAllocated;

        if (!mounted) return;

        allocatedAmount = await _showAllocationDialog(
          context: context,
          materialName: cost.description,
          receiptName: expense.description,
          receiptTotal: expense.amount,
          alreadyAllocated: alreadyAllocated,
          remaining: remaining,
          invoiceEstimate: cost.provisionalCost,
          currencySymbol: widget.currencySymbol,
        );
      }

      if (allocatedAmount == null || allocatedAmount <= 0) return;

      await repo.linkExpenseToCost(cost.id, selectedExpenseId, allocatedAmount);
      ref.invalidate(costBreakdownProvider);
      ref.invalidate(costLedgerProvider);
      ref.read(analyticsProvider.notifier).refresh();
      await _load(); // Refresh
    });
  }

  Future<void> _confirmUnlinkCost(RecognizedMaterialCost cost) async {
    final shouldUnlink = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Unlink receipt?'),
            content: const Text(
              'The app will stop using the receipt amount and go back to the invoice cost for this material.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Unlink'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldUnlink) return;

    await _unlinkCost(cost);
  }

  Future<void> _unlinkCost(RecognizedMaterialCost cost) async {
    final db = ref.read(databaseProvider);
    await db.materialCostDao.deleteLinksForCost(cost.id);
    // Reset canonical cost to provisional
    await db.materialCostDao.updateCost(
      cost.id,
      RecognizedMaterialCostsCompanion(
        canonicalCost: Value(cost.provisionalCost),
        source: const Value('invoice'),
        updatedAt: Value(DateTime.now()),
        synced: const Value(false),
      ),
    );
    ref.invalidate(costBreakdownProvider);
    ref.invalidate(costLedgerProvider);
    ref.read(analyticsProvider.notifier).refresh();
    await _load(); // Refresh
  }

  /// Shows the digitized receipt line items so the user can tap-select
  /// which item(s) correspond to this material. Returns the total price
  /// of the selected items, or null if the user cancels.
  Future<double?> _showReceiptItemPicker({
    required BuildContext context,
    required String materialName,
    required String receiptName,
    required double receiptTotal,
    required List<ReceiptLineItem> items,
    required double invoiceEstimate,
    required String currencySymbol,
  }) async {
    final cs = currencySymbol;
    final selected = <int>{};

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            final selectedTotal = selected.fold<double>(
                0.0, (sum, i) => sum + items[i].totalPrice);

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select items for "$materialName"',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Receipt header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              receiptName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$cs${receiptTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tap the items from this receipt that make up "$materialName".',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // Item list
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          final isSelected = selected.contains(index);
                          return InkWell(
                            key: ValueKey('receipt_item_$index'),
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  selected.remove(index);
                                } else {
                                  selected.add(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.paid(ctx)
                                        .withValues(alpha: 0.08)
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.paid(ctx)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.paid(ctx)
                                            : colorScheme.outlineVariant,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 15, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.quantity > 1)
                                          Text(
                                            '${item.quantity} × $cs${item.unitPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Price
                                  Text(
                                    '$cs${item.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.paid(ctx)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Footer with selected total + confirm
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Selected summary
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selected.isEmpty
                                    ? 'No items selected'
                                    : '${selected.length} item${selected.length == 1 ? '' : 's'} selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '$cs${selectedTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: selected.isNotEmpty
                                      ? AppColors.paid(ctx)
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (selected.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoice estimate',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$cs${invoiceEstimate.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () => Navigator.pop(ctx, selectedTotal),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  selected.isEmpty
                                      ? 'Select items to link'
                                      : 'Link $cs${selectedTotal.toStringAsFixed(2)} to $materialName',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a dialog asking how much of a receipt to allocate to this material.
  /// Pre-fills with the invoice estimate. Shows receipt total and already-
  /// allocated info so the user understands the context.
  Future<double?> _showAllocationDialog({
    required BuildContext context,
    required String materialName,
    required String receiptName,
    required double receiptTotal,
    required double alreadyAllocated,
    required double remaining,
    required double invoiceEstimate,
    required String currencySymbol,
  }) async {
    final cs = currencySymbol;
    final controller =
        TextEditingController(text: invoiceEstimate.toStringAsFixed(2));
    String? errorText;

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Text(
                      'How much was "$materialName"?',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    // Receipt context
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_outlined,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(receiptName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text('$cs${receiptTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (alreadyAllocated > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Already allocated to other items',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            colorScheme.onSurfaceVariant)),
                                Text(
                                    '$cs${alreadyAllocated.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Remaining',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.paid(ctx))),
                                Text(
                                    '$cs${remaining.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.paid(ctx))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Amount input
                    Text('Amount for $materialName',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixText: '$cs ',
                        errorText: errorText,
                        hintText: '0.00',
                        helperText:
                            'Invoice estimate: $cs${invoiceEstimate.toStringAsFixed(2)}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      onChanged: (_) {
                        if (errorText != null) {
                          setSheetState(() => errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    // Helper text
                    Text(
                      'Enter the portion of this receipt that covers $materialName.',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final parsed =
                              double.tryParse(controller.text.trim());
                          if (parsed == null || parsed <= 0) {
                            setSheetState(() =>
                                errorText = 'Enter a valid amount');
                            return;
                          }
                          if (parsed > receiptTotal) {
                            setSheetState(() => errorText =
                                'Cannot exceed receipt total ($cs${receiptTotal.toStringAsFixed(2)})');
                            return;
                          }
                          Navigator.pop(ctx, parsed);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Confirm & Link',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
