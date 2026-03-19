import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/database.dart';
import '../../data/repositories/material_cost_repository.dart';
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
    } catch (_) {
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
                        '$unlinkedCount using invoice cost',
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
                      isLinked ? 'Receipt linked' : 'Using invoice cost';
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
                    'Link "${cost.description}" to an expense',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Possible matching receipts',
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Suggestions first
                      ...suggestions.map((s) => ListTile(
                            key: ValueKey(
                                'material_cost_pick_suggested_${cost.id}_${s.expenseId}'),
                            leading: Icon(Icons.auto_awesome,
                                color: Colors.amber.shade700, size: 20),
                            title: Text(s.expenseDescription,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                                '$cs${s.expenseAmount.toStringAsFixed(2)} \u00b7 ${(s.score).toStringAsFixed(0)}% match'),
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
                          )),
                      if (suggestions.isNotEmpty) const Divider(height: 1),
                      // All material expenses
                      ...materialExpenses.map((e) {
                        final isSuggested =
                            suggestions.any((s) => s.expenseId == e.id);
                        if (isSuggested) return const SizedBox.shrink();
                        return ListTile(
                          key: ValueKey(
                              'material_cost_pick_all_${cost.id}_${e.id}'),
                          leading: Icon(Icons.receipt_outlined,
                              color: colorScheme.onSurfaceVariant, size: 20),
                          title: Text(e.description,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                              '$cs${e.amount.toStringAsFixed(2)} \u00b7 ${DateFormat('MMM d').format(e.expenseDate)}'),
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

      // Find the expense amount
      final expense = materialExpenses.firstWhere(
        (e) => e.id == selectedExpenseId,
        orElse: () => materialExpenses.first,
      );

      await repo.linkExpenseToCost(cost.id, selectedExpenseId, expense.amount);
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
    await _load(); // Refresh
  }
}
