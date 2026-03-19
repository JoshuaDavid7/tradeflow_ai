import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tradeflow_ai/domain/models/expense.dart';
import 'package:tradeflow_ai/data/services/receipt_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_widgets.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _searchQuery = '';
  ExpenseCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    // Filter expenses
    final filtered = expenseState.expenses.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.description.toLowerCase().contains(q) &&
            !(e.vendor?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (_filterCategory != null && e.category != _filterCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Active filter chip
          if (_filterCategory != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filterCategory!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _filterCategory = null),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),

          // Summary card
          if (expenseState.expenses.isNotEmpty)
            _buildSummaryCard(context, ref, currencySymbol),

          // Expense list
          Expanded(
            child: _buildBody(
                context, ref, expenseState, filtered, currencySymbol),
          ),
        ],
      ),
      // Only show FAB when expenses exist — empty state has its own CTA
      floatingActionButton: expenseState.expenses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddExpense(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseListState state,
    List<Expense> filtered,
    String currencySymbol,
  ) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerLoadingListItem(),
        ),
      );
    }

    if (state.error != null) {
      return ErrorDisplay(
        message: state.error!,
        onRetry: () => ref.read(expenseListProvider.notifier).refresh(),
      );
    }

    if (state.expenses.isEmpty) {
      return EmptyState(
        message: 'No expenses yet',
        subtitle: 'Track your business spending to understand profitability',
        icon: Icons.receipt_long,
        onAction: () => _navigateToAddExpense(context),
        actionLabel: 'Add First Expense',
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'No expenses match your search',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Group expenses by month for clear chronology
    final grouped = <String, List<Expense>>{};
    for (final e in filtered) {
      final key = DateFormat('MMMM yyyy').format(e.expenseDate);
      (grouped[key] ??= []).add(e);
    }
    final groupKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(expenseListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: grouped.values.fold<int>(
            0, (sum, list) => sum + list.length + 1), // +1 per header
        itemBuilder: (context, index) {
          // Walk through groups to find which group/item this index maps to
          var remaining = index;
          for (final key in groupKeys) {
            final items = grouped[key]!;
            if (remaining == 0) {
              // This is a month header
              return _buildMonthHeader(context, key);
            }
            remaining--; // skip the header
            if (remaining < items.length) {
              return _buildExpenseCard(
                  context, items[remaining], currencySymbol);
            }
            remaining -= items.length;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, String monthLabel) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth =
        monthLabel == DateFormat('MMMM yyyy').format(now);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            isCurrentMonth ? 'This Month' : monthLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          if (isCurrentMonth) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    String currencySymbol,
  ) {
    final expenseStats = ref.watch(expenseStatsProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return expenseStats.when(
      data: (stats) {
        final monthlyExpenses = stats['monthlyExpenses'] as double? ?? 0.0;
        final totalExpenses = stats['totalExpenses'] as double? ?? 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currencySymbol${monthlyExpenses.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currencySymbol${totalExpenses.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoadingCard(height: 80),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildExpenseCard(
      BuildContext context, Expense expense, String currencySymbol) {
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showExpenseDetails(context, expense, currencySymbol),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          flex: 0,
                          child: Text(
                            expense.category.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        if (expense.vendor != null) ...[
                          Text(' · ',
                              style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                          Flexible(
                            child: Text(
                              expense.vendor!,
                              style: TextStyle(
                                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(expense.expenseDate),
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        if (expense.hasReceipt) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.attach_file,
                              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                        if (expense.taxDeductible) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade700),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '$currencySymbol${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.overdue(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense, String cs) {
    final dateFormat = DateFormat('EEEE, MMM d, y');

    // Parse AI-extracted items from OCR text if available
    ReceiptAiResult? aiResult;
    if (expense.ocrText != null && expense.ocrText!.isNotEmpty) {
      try {
        aiResult = ReceiptAiResult.fromJsonString(expense.ocrText!);
        if (aiResult.items.isEmpty) aiResult = null;
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: aiResult != null ? 0.75 : 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: _getCategoryColor(expense.category),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.category.displayName,
                        style: TextStyle(
                            fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.overdue(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$cs${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.overdue(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI-Extracted Receipt Items Table
            if (aiResult != null) ...[
              // Store name header
              if (aiResult.storeName != null &&
                  aiResult.storeName!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Theme.of(context).colorScheme.onPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        aiResult.storeName!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Itemized table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('ITEM',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          SizedBox(
                              width: 40,
                              child: Text('QTY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 70,
                              child: Text('PRICE',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        ],
                      ),
                    ),
                    // Item rows
                    ...aiResult.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      final isLast = entry.key == aiResult!.items.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                      color: Theme.of(context).colorScheme.surfaceContainerLow)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item.name,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text('${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '$cs${item.totalPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Totals
                    if (aiResult.subtotal != null ||
                        aiResult.tax != null ||
                        aiResult.total != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(11)),
                          border: Border(
                              top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                        ),
                        child: Column(
                          children: [
                            if (aiResult.subtotal != null)
                              _receiptTotalRow('Subtotal',
                                  '$cs${aiResult.subtotal!.toStringAsFixed(2)}'),
                            if (aiResult.tax != null)
                              _receiptTotalRow('Tax',
                                  '$cs${aiResult.tax!.toStringAsFixed(2)}'),
                            if (aiResult.total != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _receiptTotalRow(
                                  'TOTAL',
                                  '$cs${aiResult.total!.toStringAsFixed(2)}',
                                  bold: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Details rows
            _detailRow(Icons.calendar_today, 'Date',
                dateFormat.format(expense.expenseDate)),
            if (expense.vendor != null)
              _detailRow(Icons.store, 'Vendor', expense.vendor!),
            if (expense.paymentMethod != null)
              _detailRow(
                  Icons.payment, 'Payment', expense.paymentMethod!.displayName),
            _detailRow(
              expense.taxDeductible ? Icons.check_circle : Icons.cancel,
              'Tax Deductible',
              expense.taxDeductible ? 'Yes' : 'No',
              color: expense.taxDeductible ? AppColors.paid(context) : Theme.of(context).colorScheme.error,
            ),
            if (expense.hasReceipt)
              _detailRow(Icons.attach_file, 'Receipt', 'Attached'),
            if (expense.hasReceipt) const SizedBox(height: 10),
            if (expense.hasReceipt) _buildReceiptPreview(context, expense),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddExpenseScreen(existingExpense: expense),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
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
                    onPressed: () => _confirmDelete(ctx, expense),
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    label: Text('Delete',
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview(BuildContext context, Expense expense) {
    final receiptUrl = expense.receiptUrl?.trim();
    final receiptPath = expense.receiptPath?.trim();
    final hasUrl = receiptUrl != null && receiptUrl.isNotEmpty;
    final hasLocalFile = receiptPath != null &&
        receiptPath.isNotEmpty &&
        File(receiptPath).existsSync();
    if (!hasUrl && !hasLocalFile) {
      return const SizedBox.shrink();
    }

    final image = hasUrl
        ? Image.network(
            receiptUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _receiptFallback(),
          )
        : Image.file(
            File(receiptPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _receiptFallback(),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt Image',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openReceiptViewer(context, receiptUrl, receiptPath),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 170,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: image,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              hasUrl ? Icons.cloud_done : Icons.phone_iphone,
              size: 14,
              color: hasUrl ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasUrl ? 'Backed up to cloud storage' : 'Stored on this device',
              style: TextStyle(
                fontSize: 12,
                color: hasUrl ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptFallback() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  void _openReceiptViewer(
    BuildContext context,
    String? receiptUrl,
    String? receiptPath,
  ) {
    final hasUrl = receiptUrl != null && receiptUrl.trim().isNotEmpty;
    final hasLocal = receiptPath != null &&
        receiptPath.trim().isNotEmpty &&
        File(receiptPath).existsSync();
    if (!hasUrl && !hasLocal) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: hasUrl
                    ? Image.network(
                        receiptUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _receiptFallback(),
                      )
                    : Image.file(
                        File(receiptPath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _receiptFallback(),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext sheetCtx, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('This will permanently remove "${expense.description}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(sheetCtx);
              await ref
                  .read(expenseListProvider.notifier)
                  .deleteExpense(expense.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text('Expense deleted'),
                      backgroundColor: Theme.of(context).colorScheme.error),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // All
                FilterChip(
                  label: const Text('All'),
                  selected: _filterCategory == null,
                  onSelected: (_) {
                    setState(() => _filterCategory = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...ExpenseCategory.values.map((cat) => FilterChip(
                      label: Text(cat.displayName),
                      selected: _filterCategory == cat,
                      avatar: Icon(_getCategoryIcon(cat),
                          size: 18, color: _getCategoryColor(cat)),
                      onSelected: (_) {
                        setState(() => _filterCategory = cat);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
