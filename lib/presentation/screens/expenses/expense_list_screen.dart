import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tradeflow_ai/domain/models/expense.dart';
import 'package:tradeflow_ai/data/services/receipt_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_widgets.dart';
import 'add_expense_screen.dart';
import '../../../data/local/database.dart' show databaseProvider;
import '../../../data/repositories/expense_repository.dart'
    show expenseRepositoryProvider;
import '../../../data/services/supabase_service.dart' show userIdProvider;

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

/// Filter modes for the cost ledger.
enum _CostFilter { all, toReview, logged, fromInvoices }

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _searchQuery = '';
  _CostFilter _costFilter = _CostFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final costLedgerAsync = ref.watch(costLedgerProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          _buildMonthPill(context),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SizedBox(
              height: 42,
              child: TextField(
                key: const ValueKey('expense_search'),
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search expenses…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),

          // Summary card (includes review count — replaces old Needs Action)
          if (expenseState.expenses.isNotEmpty ||
              (costLedgerAsync.valueOrNull?.isNotEmpty ?? false))
            _buildSummaryCard(context, ref, currencySymbol),

          // Main filter tabs
          _buildFilterTabs(context),

          // Cost ledger list
          Expanded(
            child: _buildCostLedgerBody(
                context, ref, expenseState, costLedgerAsync, currencySymbol),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_list_fab',
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Month Pill (matches Analytics exactly) ──────────────────────────────────

  Widget _buildMonthPill(BuildContext context) {
    final selectedMonth = ref.watch(selectedExpenseMonthProvider);
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showMonthPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 16, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM yyyy').format(selectedMonth),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    final months = <DateTime>[
      for (int i = 0; i < 12; i++) DateTime(now.year, now.month - i),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final selected = ref.read(selectedExpenseMonthProvider);
        final cs = Theme.of(ctx).colorScheme;
        final ts = Theme.of(ctx).textTheme;
        final maxH = MediaQuery.of(ctx).size.height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('Select month',
                    style:
                        ts.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: months.length,
                    itemBuilder: (_, i) {
                      final m = months[i];
                      final isSel =
                          m.year == selected.year && m.month == selected.month;
                      final isCur = m.year == now.year && m.month == now.month;
                      return ListTile(
                        leading: Icon(
                          isSel ? Icons.check_circle : Icons.circle_outlined,
                          color: isSel ? cs.primary : cs.outlineVariant,
                          size: 20,
                        ),
                        title: Text(
                          isCur
                              ? '${DateFormat('MMMM yyyy').format(m)} (Current)'
                              : DateFormat('MMMM yyyy').format(m),
                          style: TextStyle(
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          ref
                              .read(selectedExpenseMonthProvider.notifier)
                              .state = m;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Summary Card (operational — no All Time) ────────────────────────────────

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    String currencySymbol,
  ) {
    final costBreakdown = ref.watch(costBreakdownProvider);
    final needsAction = ref.watch(needsActionProvider);
    final selectedMonth = ref.watch(selectedExpenseMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final monthLabel = isCurrentMonth
        ? 'This Month'
        : DateFormat('MMM yyyy').format(selectedMonth);

    final colorScheme = Theme.of(context).colorScheme;

    return costBreakdown.when(
      data: (breakdown) {
        // Review count from needsAction provider
        final reviewCount = needsAction.whenOrNull(
              data: (b) => b.estimated.length + b.unassigned.length,
            ) ??
            0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary metric: This Month total
              Text(
                monthLabel,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$currencySymbol${breakdown.monthlyCosts.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // Breakdown row: Logged · From invoices · To review
              Row(
                children: [
                  _summaryMetric(context,
                      label: 'Logged',
                      value:
                          '$currencySymbol${breakdown.standaloneMonthly.toStringAsFixed(0)}'),
                  _summaryDot(context),
                  _summaryMetric(context,
                      label: 'From invoices',
                      value:
                          '$currencySymbol${breakdown.materialCostMonthly.toStringAsFixed(0)}'),
                  if (reviewCount > 0) ...[
                    _summaryDot(context),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _costFilter = _CostFilter.toReview),
                      child: _summaryMetric(context,
                          label: 'To review',
                          value: '$reviewCount',
                          highlight: true),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoadingCard(height: 70),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _summaryMetric(BuildContext context,
      {required String label, required String value, bool highlight = false}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: highlight ? Colors.amber.shade700 : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: highlight ? Colors.amber.shade700 : cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _summaryDot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outlineVariant)),
    );
  }

  // ── Filter Tabs ────────────────────────────────────────────────────────────

  Widget _buildFilterTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(
        children: [
          _filterTab('All', _CostFilter.all, colorScheme),
          const SizedBox(width: 6),
          _filterTab('To Review', _CostFilter.toReview, colorScheme),
          const SizedBox(width: 6),
          _filterTab('Logged', _CostFilter.logged, colorScheme),
          const SizedBox(width: 6),
          _filterTab('From Invoices', _CostFilter.fromInvoices, colorScheme),
        ],
      ),
    );
  }

  Widget _filterTab(String label, _CostFilter filter, ColorScheme cs) {
    final selected = _costFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _costFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  // ── Cost Ledger Body ────────────────────────────────────────────────────────

  Widget _buildCostLedgerBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseListState expenseState,
    AsyncValue<List<CostLedgerEntry>> costLedgerAsync,
    String currencySymbol,
  ) {
    if (expenseState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerLoadingListItem(),
        ),
      );
    }

    if (expenseState.error != null) {
      return ErrorDisplay(
        message: expenseState.error!,
        onRetry: () => ref.read(expenseListProvider.notifier).refresh(),
      );
    }

    return costLedgerAsync.when(
      data: (allEntries) {
        if (allEntries.isEmpty) {
          return EmptyState(
            message: 'No expenses yet',
            subtitle:
                'Track your business spending to understand profitability',
            icon: Icons.receipt_long,
            onAction: () => _navigateToAddExpense(context),
            actionLabel: 'Add First Expense',
          );
        }

        final selectedMonth = ref.watch(selectedExpenseMonthProvider);
        final filtered = _applyFilters(allEntries, selectedMonth);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No matching expenses',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                if (_costFilter != _CostFilter.all ||
                    _searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _costFilter = _CostFilter.all;
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                    child: Text(_searchQuery.isNotEmpty
                        ? 'Clear search'
                        : 'Clear filters'),
                  ),
                ],
              ],
            ),
          );
        }

        // Group invoice materials by jobId, then group by month
        final displayRows = _groupForDisplay(filtered);
        final grouped = <String, List<_DisplayRow>>{};
        for (final row in displayRows) {
          final key = DateFormat('MMMM yyyy').format(row.displayDate);
          (grouped[key] ??= []).add(row);
        }
        final groupKeys = grouped.keys.toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(costLedgerProvider);
            ref.invalidate(costBreakdownProvider);
            ref.invalidate(needsActionProvider);
            await ref.read(expenseListProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: grouped.values
                .fold<int>(0, (sum, list) => sum + list.length + 1),
            itemBuilder: (context, index) {
              var remaining = index;
              for (final key in groupKeys) {
                final items = grouped[key]!;
                if (remaining == 0) return _buildMonthHeader(context, key);
                remaining--;
                if (remaining < items.length) {
                  final row = items[remaining];
                  if (row.isGroup) {
                    return _buildGroupedRow(context, row, currencySymbol);
                  } else {
                    return _buildLedgerRow(context, row.entry!, currencySymbol);
                  }
                }
                remaining -= items.length;
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerLoadingListItem(),
        ),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load cost ledger',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                ref.invalidate(costLedgerProvider);
                ref.invalidate(costBreakdownProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtering ───────────────────────────────────────────────────────────────

  List<CostLedgerEntry> _applyFilters(
      List<CostLedgerEntry> all, DateTime selectedMonth) {
    return all.where((entry) {
      // Month filter — show only entries from the selected month
      // (unless search is active, then show all months for discoverability)
      if (_searchQuery.isEmpty) {
        final d = entry.date.toLocal();
        if (d.year != selectedMonth.year || d.month != selectedMonth.month) {
          return false;
        }
      }

      // Hide invoice materials that already have a receipt linked —
      // the receipt itself shows in Logged as "Invoiced · INV-XXXX",
      // so showing the material too would be redundant.
      if (entry.type == CostEntryType.invoiceMaterial && !entry.isEstimated) {
        return false;
      }

      // Type filter
      switch (_costFilter) {
        case _CostFilter.all:
          break;
        case _CostFilter.toReview:
          // Estimated materials or logged expenses without a job
          if (entry.type == CostEntryType.invoiceMaterial &&
              entry.isEstimated) {
            break;
          }
          if (entry.type == CostEntryType.loggedExpense &&
              entry.jobId == null) {
            break;
          }
          return false;
        case _CostFilter.logged:
          if (entry.type != CostEntryType.loggedExpense &&
              entry.type != CostEntryType.linkedExpense) return false;
          break;
        case _CostFilter.fromInvoices:
          if (entry.type != CostEntryType.invoiceMaterial) return false;
          // Only show materials that still need a receipt linked
          if (!entry.isEstimated) return false;
          break;
      }

      // Search filter — broad: title, vendor, client, invoice number, category
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final fields = [
          entry.description,
          entry.clientName ?? '',
          entry.vendor ?? '',
          entry.invoiceNumber ?? '',
          entry.category ?? '',
          entry.jobId ?? '',
        ];
        if (!fields.any((f) => f.toLowerCase().contains(q))) {
          // Also search receipt line items if available
          if (entry.expense?.ocrText != null) {
            if (!entry.expense!.ocrText!.toLowerCase().contains(q)) {
              return false;
            }
          } else {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  // ── Invoice Grouping ────────────────────────────────────────────────────────

  /// Groups invoice material entries by jobId so that multi-item invoices
  /// appear as a single parent row in the main list. Linked expenses for
  /// grouped invoices are folded into the group as metadata.
  List<_DisplayRow> _groupForDisplay(List<CostLedgerEntry> entries) {
    // Partition: materials by jobId, linked by jobId, everything else standalone
    final materialsByJob = <String, List<CostLedgerEntry>>{};
    final linkedByJob = <String, List<CostLedgerEntry>>{};
    final standaloneRows = <_DisplayRow>[];

    for (final e in entries) {
      if (e.type == CostEntryType.invoiceMaterial && e.jobId != null) {
        (materialsByJob[e.jobId!] ??= []).add(e);
      } else if (e.type == CostEntryType.linkedExpense && e.jobId != null) {
        (linkedByJob[e.jobId!] ??= []).add(e);
      } else {
        standaloneRows.add(_DisplayRow.single(e));
      }
    }

    final rows = <_DisplayRow>[];
    final foldedLinkedJobIds = <String>{};

    for (final mapEntry in materialsByJob.entries) {
      final jobId = mapEntry.key;
      final materials = mapEntry.value;
      final linked = linkedByJob[jobId];

      if (materials.length > 1) {
        // Multi-item invoice → group into one parent row
        rows.add(_DisplayRow.group(materials, linkedEntries: linked));
        if (linked != null) foldedLinkedJobIds.add(jobId);
      } else {
        // Single material → individual row
        rows.add(_DisplayRow.single(materials.first));
      }
    }

    // Add linked expenses NOT folded into a group
    for (final mapEntry in linkedByJob.entries) {
      if (!foldedLinkedJobIds.contains(mapEntry.key)) {
        for (final linked in mapEntry.value) {
          standaloneRows.add(_DisplayRow.single(linked));
        }
      }
    }

    rows.addAll(standaloneRows);
    rows.sort((a, b) => b.displayDate.compareTo(a.displayDate));
    return rows;
  }

  // ── Month Header ────────────────────────────────────────────────────────────

  Widget _buildMonthHeader(BuildContext context, String monthLabel) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedMonth = ref.watch(selectedExpenseMonthProvider);
    final isSelected =
        monthLabel == DateFormat('MMMM yyyy').format(selectedMonth);
    final now = DateTime.now();
    final isCurrentMonth = monthLabel == DateFormat('MMMM yyyy').format(now);
    final displayLabel = isCurrentMonth ? 'This Month' : monthLabel;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          if (isSelected && isCurrentMonth) ...[
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

  // ── Ledger Row ──────────────────────────────────────────────────────────────

  Widget _buildLedgerRow(
      BuildContext context, CostLedgerEntry entry, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');

    final bool isMaterial = entry.type == CostEntryType.invoiceMaterial;
    final bool isLinkedExp = entry.type == CostEntryType.linkedExpense;

    // Receipt item count for grouped display
    int? receiptItemCount;
    ReceiptAiResult? aiResult;
    if (entry.expense?.ocrText != null && entry.expense!.ocrText!.isNotEmpty) {
      try {
        aiResult = ReceiptAiResult.fromJsonString(entry.expense!.ocrText!);
        if (aiResult.items.length > 1) {
          receiptItemCount = aiResult.items.length;
        } else {
          aiResult = null; // Single-item receipt, no grouping needed
        }
      } catch (_) {
        aiResult = null;
      }
    }

    // Icon + color
    final IconData icon;
    final Color iconColor;
    if (isMaterial) {
      icon = Icons.inventory_2_outlined;
      iconColor = Colors.orange;
    } else if (receiptItemCount != null) {
      icon = Icons.receipt_long;
      iconColor = Theme.of(context).colorScheme.primary;
    } else {
      final cat = entry.expense?.category ?? ExpenseCategory.other;
      icon = _getCategoryIcon(cat);
      iconColor = _getCategoryColor(cat);
    }

    // Badge — single status badge per row
    _BadgeInfo? badge;
    if (isMaterial && entry.isEstimated) {
      badge = _BadgeInfo('No receipt', Colors.amber.shade700);
    } else if (isLinkedExp) {
      final invLabel = entry.invoiceNumber != null
          ? 'Invoiced · ${entry.invoiceNumber}'
          : 'Invoiced';
      badge = _BadgeInfo(invLabel, AppColors.paid(context));
    } else if (!isMaterial && !isLinkedExp && entry.jobId == null) {
      badge = _BadgeInfo('Not invoiced', Colors.amber.shade700);
    }

    // ── Strict two-template row metadata ──
    // Template A — Logged / Linked expense:
    //   Title
    //   Category · Vendor
    //   Date · badge
    // Template B — From-invoice material:
    //   Title
    //   INV-#### · Client
    //   Date · badge

    String title = entry.description;
    if (title.isEmpty) {
      if (entry.vendor != null && entry.vendor!.isNotEmpty) {
        title = entry.vendor!;
      } else if (entry.jobName != null && entry.jobName!.isNotEmpty) {
        title = '${entry.jobName!} materials';
      } else if (aiResult != null && aiResult.items.isNotEmpty) {
        title = _suggestCostEventTitle(aiResult);
      } else {
        title = 'Expense from ${dateFormat.format(entry.date)}';
      }
    }

    // Line 2 — stable secondary info
    final subtitleParts = <String>[];
    if (isMaterial) {
      // Template B: INV-#### · Client
      if (entry.invoiceNumber != null && entry.invoiceNumber!.isNotEmpty) {
        subtitleParts.add(entry.invoiceNumber!);
      }
      if (entry.clientName != null && entry.clientName!.isNotEmpty) {
        subtitleParts.add(entry.clientName!);
      }
      if (subtitleParts.isEmpty) subtitleParts.add('Invoice material');
    } else {
      // Template A: Category · Vendor
      if (entry.category != null && entry.category!.isNotEmpty) {
        subtitleParts.add(entry.category!);
      }
      if (entry.vendor != null && entry.vendor!.isNotEmpty) {
        subtitleParts.add(entry.vendor!);
      }
      if (subtitleParts.isEmpty && isLinkedExp) {
        subtitleParts.add('Linked expense');
      }
    }

    // Line 3 — always date + badge (no variance)
    final dateLine = dateFormat.format(entry.date);

    // Amount styling
    final amountColor =
        isLinkedExp ? colorScheme.onSurfaceVariant : AppColors.overdue(context);
    final amountDecoration =
        isLinkedExp ? TextDecoration.lineThrough : TextDecoration.none;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isLinkedExp ? 0 : 1,
      color: isLinkedExp
          ? colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _onRowTap(context, entry, cs, aiResult),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isLinkedExp ? colorScheme.onSurfaceVariant : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Subtitle (provenance)
                    Text(
                      subtitleParts.join(' · '),
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Context + badges row
                    // Line 3: Date · badge (always predictable)
                    Row(
                      children: [
                        Text(
                          dateLine,
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: badge.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: badge.color,
                              ),
                            ),
                          ),
                        ],
                        if (entry.expense?.hasReceipt == true) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.attach_file,
                              size: 12, color: colorScheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                '$cs${entry.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  decoration: amountDecoration,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grouped Invoice Row ─────────────────────────────────────────────────────

  Widget _buildGroupedRow(BuildContext context, _DisplayRow row, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');

    // Title fallback hierarchy for grouped invoice:
    //   1. Job name + "materials" (e.g. "Bathroom Repair materials")
    //   2. AI-suggested from child item descriptions (e.g. "Plumbing supplies")
    //   3. Invoice number (e.g. "INV-0019")
    //   4. Neutral date fallback
    final title = _groupedRowTitle(row, dateFormat);

    // Line 2: INV-#### · Client · N items
    final subtitleParts = <String>[];
    if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
      subtitleParts.add(row.invoiceNumber!);
    }
    if (row.clientName != null && row.clientName!.isNotEmpty) {
      subtitleParts.add(row.clientName!);
    }
    subtitleParts.add('${row.itemCount} items');

    // Line 3: Date · badge
    final dateLine = dateFormat.format(row.displayDate);

    // Single summary badge
    final _BadgeInfo badge;
    // All remaining invoice materials are unlinked (receipt-linked ones
    // are filtered out globally), so badge is always "No receipt".
    badge = _BadgeInfo('No receipt', Colors.amber.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showInvoiceGroupDetail(context, row, cs),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon — briefcase/invoice icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Subtitle
                    Text(
                      subtitleParts.join(' · '),
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Line 3: Date · badge
                    Row(
                      children: [
                        Text(
                          dateLine,
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: badge.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badge.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Total amount
              Text(
                '$cs${row.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
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

  // ── Detail: Invoice Group ──────────────────────────────────────────────────

  void _showInvoiceGroupDetail(
      BuildContext context, _DisplayRow row, String cs) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = row.children!;
    final linked = row.linkedEntries ?? [];

    // Title hierarchy — same as parent row
    final title = _groupedRowTitle(row, DateFormat('MMM d, y'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
                  color: colorScheme.outlineVariant,
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (row.invoiceNumber != null &&
                              row.invoiceNumber!.isNotEmpty)
                            row.invoiceNumber!,
                          '${row.itemCount} items',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total amount
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
                    '$cs${row.totalAmount.toStringAsFixed(2)}',
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

            // Context info
            if (row.jobName != null && row.jobName!.isNotEmpty)
              _detailRow(Icons.work_outline, 'Job', row.jobName!),
            if (row.clientName != null && row.clientName!.isNotEmpty)
              _detailRow(Icons.person_outline, 'Client', row.clientName!),
            if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty)
              _detailRow(Icons.receipt_outlined, 'Invoice', row.invoiceNumber!),
            const SizedBox(height: 16),

            // Summary badges
            Row(
              children: [
                if (row.estimatedCount > 0) ...[
                  Icon(Icons.schedule, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text('${row.estimatedCount} estimated',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700)),
                  const SizedBox(width: 12),
                ],
                if (row.actualCount > 0) ...[
                  Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.paid(context)),
                  const SizedBox(width: 4),
                  Text('${row.actualCount} linked',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.paid(context))),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Itemized table header
            Text('MATERIALS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),

            // Itemized material rows
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('ITEM',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurfaceVariant))),
                        SizedBox(
                            width: 60,
                            child: Text('STATUS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurfaceVariant))),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 70,
                            child: Text('COST',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurfaceVariant))),
                      ],
                    ),
                  ),
                  // Material rows
                  ...children.asMap().entries.map((mapEntry) {
                    final child = mapEntry.value;
                    final isLast = mapEntry.key == children.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                    color: colorScheme.surfaceContainerLow)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(child.description,
                                style: const TextStyle(fontSize: 14)),
                          ),
                          SizedBox(
                            width: 60,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: (child.isEstimated
                                        ? Colors.amber.shade700
                                        : AppColors.paid(context))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                child.isEstimated ? 'No rcpt' : 'Receipt',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: child.isEstimated
                                      ? Colors.amber.shade700
                                      : AppColors.paid(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '$cs${child.amount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Total row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                      border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                            flex: 3,
                            child: Text('TOTAL',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800))),
                        const SizedBox(width: 68),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '$cs${row.totalAmount.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Linked expenses section
            if (linked.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('LINKED RECEIPTS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...linked.map((le) => Card(
                    elevation: 0,
                    color:
                        colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(Icons.link,
                              size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(le.description,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                if (le.vendor != null)
                                  Text(le.vendor!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text(
                            '$cs${le.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 20),
            // Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These materials need a receipt linked. '
                      'Link a receipt to track the actual cost.',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Row Tap Handler ─────────────────────────────────────────────────────────

  void _onRowTap(BuildContext context, CostLedgerEntry entry, String cs,
      ReceiptAiResult? aiResult) {
    final isMaterial = entry.type == CostEntryType.invoiceMaterial;
    final isLinkedExp = entry.type == CostEntryType.linkedExpense;

    if (isMaterial) {
      _showMaterialCostDetail(context, entry, cs);
    } else if (aiResult != null && aiResult.items.length > 1) {
      _showReceiptGroupDetail(context, entry, cs, aiResult);
    } else if (entry.expense != null) {
      _showExpenseDetails(context, entry.expense!, cs,
          isLinked: isLinkedExp, linkedToMaterialId: entry.linkedToMaterialId);
    }
  }

  // ── Detail: Invoice Material Cost ───────────────────────────────────────────

  void _showMaterialCostDetail(
      BuildContext context, CostLedgerEntry entry, String cs) async {
    final colorScheme = Theme.of(context).colorScheme;
    final cost = entry.materialCost;
    if (cost == null) return;

    // Resolve linked receipt info directly from DB (bypass provider cache)
    String? receiptName = entry.linkedReceiptName;
    double? receiptAmount = entry.linkedReceiptAmount;
    if (receiptName == null && cost.source == 'both') {
      try {
        final db = ref.read(databaseProvider);
        final links = await db.materialCostDao.getLinksForCost(cost.id);
        if (links.isNotEmpty) {
          final expId = links.first.expenseId;
          final repository = ref.read(expenseRepositoryProvider);
          final userId = ref.read(userIdProvider);
          if (userId != null) {
            final allExp = await repository.getAllExpenses(userId);
            final match = allExp.where((e) => e.id == expId);
            if (match.isNotEmpty) {
              receiptName = match.first.description;
              receiptAmount = match.first.amount;
            } else {
              final rawExp = await db.expenseDao.getExpenseById(expId);
              if (rawExp != null) {
                receiptName = rawExp.description;
                receiptAmount = rawExp.amount;
              } else {
                receiptName = 'Receipt (ID: ${expId.substring(0, 8)}...)';
                receiptAmount = links.first.allocatedAmount;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to resolve linked receipt: $e');
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.description,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Invoice Material',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('$cs${cost.canonicalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // Status badge
              Row(
                children: [
                  Icon(
                    entry.isEstimated
                        ? Icons.schedule
                        : Icons.check_circle_outline,
                    size: 18,
                    color: entry.isEstimated
                        ? Colors.amber.shade700
                        : AppColors.paid(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.isEstimated
                          ? 'No receipt linked — using invoice estimate'
                          : 'Receipt linked — actual cost verified',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: entry.isEstimated
                            ? Colors.amber.shade700
                            : AppColors.paid(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Details
              _detailRow(Icons.calendar_today, 'Recognized',
                  DateFormat('MMM d, y').format(cost.recognitionDate)),
              if (entry.clientName != null)
                _detailRow(Icons.person_outline, 'Client', entry.clientName!),
              if (entry.invoiceNumber != null)
                _detailRow(
                    Icons.receipt_outlined, 'Invoice', entry.invoiceNumber!),
              if (cost.provisionalCost != cost.canonicalCost)
                _detailRow(Icons.compare_arrows, 'Invoice estimate',
                    '$cs${cost.provisionalCost.toStringAsFixed(2)}'),
              _detailRow(Icons.label_outline, 'Source',
                  cost.source == 'both' ? 'Invoice + receipt' : 'Invoice'),
              // Linked receipt section
              if (receiptName != null) ...[
                const SizedBox(height: 14),
                Text('LINKED RECEIPT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paid(context).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.paid(context).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link,
                          size: 16, color: AppColors.paid(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(receiptName!,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      if (receiptAmount != null)
                        Text('$cs${receiptAmount!.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.paid(context))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Explanation
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.isEstimated
                            ? 'Based on invoice estimate. Link a receipt for actual cost.'
                            : 'Backed by a linked receipt. Invoice estimate replaced.',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail: Receipt Group ───────────────────────────────────────────────────

  void _showReceiptGroupDetail(BuildContext context, CostLedgerEntry entry,
      String cs, ReceiptAiResult aiResult) {
    final colorScheme = Theme.of(context).colorScheme;
    final expense = entry.expense!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.receipt_long,
                            color: colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _receiptTitle(expense, aiResult, entry),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Receipt · ${aiResult.items.length} items',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.overdue(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$cs${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdue(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Store name header
                  if (aiResult.storeName != null &&
                      aiResult.storeName!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store,
                              color: colorScheme.onPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            aiResult.storeName!,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
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
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
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
                                          color:
                                              colorScheme.onSurfaceVariant))),
                              SizedBox(
                                  width: 40,
                                  child: Text('QTY',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              colorScheme.onSurfaceVariant))),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 70,
                                  child: Text('PRICE',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              colorScheme.onSurfaceVariant))),
                            ],
                          ),
                        ),
                        // Item rows
                        ...aiResult.items.asMap().entries.map((mapEntry) {
                          final item = mapEntry.value;
                          final isLast =
                              mapEntry.key == aiResult.items.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                          color:
                                              colorScheme.surfaceContainerLow)),
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
                                          color: colorScheme.onSurfaceVariant)),
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
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(11)),
                              border: Border(
                                  top: BorderSide(
                                      color: colorScheme.outlineVariant)),
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

                  // Details rows
                  _detailRow(Icons.calendar_today, 'Date',
                      DateFormat('EEEE, MMM d, y').format(expense.expenseDate)),
                  if (expense.vendor != null)
                    _detailRow(Icons.store, 'Vendor', expense.vendor!),
                  _detailRow(
                      Icons.category, 'Category', expense.category.displayName),
                  if (expense.paymentMethod != null)
                    _detailRow(Icons.payment, 'Payment',
                        expense.paymentMethod!.displayName),
                  if (expense.hasReceipt)
                    _detailRow(Icons.attach_file, 'Receipt', 'Attached'),
                  if (expense.hasReceipt) const SizedBox(height: 8),
                  if (expense.hasReceipt)
                    _buildReceiptPreview(context, expense),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Sticky footer: Edit / Delete
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
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
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(ctx, expense),
                        icon: Icon(Icons.delete,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        label: Text('Delete',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Title fallback hierarchy for receipt group detail sheet header.
  ///   1. Vendor name
  ///   2. Job context (if known)
  ///   3. AI-suggested cost-event title from items
  ///   4. Neutral fallback
  String _receiptTitle(
      Expense expense, ReceiptAiResult aiResult, CostLedgerEntry entry) {
    if (expense.vendor != null && expense.vendor!.trim().isNotEmpty) {
      return expense.vendor!;
    }
    if (entry.jobName != null && entry.jobName!.isNotEmpty) {
      return '${entry.jobName!} materials';
    }
    if (aiResult.storeName != null && aiResult.storeName!.isNotEmpty) {
      return aiResult.storeName!;
    }
    if (aiResult.items.isNotEmpty) {
      return _suggestCostEventTitle(aiResult);
    }
    if (expense.description.isNotEmpty) {
      return expense.description;
    }
    return 'Receipt from ${DateFormat('MMM d').format(expense.expenseDate)}';
  }

  /// Title fallback for grouped invoice parent rows.
  /// Client name is NEVER the title — it goes in the subtitle metadata.
  ///   1. Job name + "materials" (e.g. "Bathroom Repair materials")
  ///   2. AI-suggested from child descriptions (e.g. "Plumbing supplies")
  ///   3. Invoice number (e.g. "INV-0019")
  ///   4. Neutral date fallback (e.g. "Invoice from Mar 21")
  String _groupedRowTitle(_DisplayRow row, DateFormat dateFormat) {
    if (row.jobName != null && row.jobName!.isNotEmpty) {
      return '${row.jobName!} materials';
    }
    // Try AI-suggested title from child item descriptions
    final suggested = _suggestGroupTitleFromChildren(row.children!);
    if (suggested != null) return suggested;
    if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
      return row.invoiceNumber!;
    }
    return 'Invoice from ${dateFormat.format(row.displayDate)}';
  }

  /// Infer a trade-category title from grouped material descriptions.
  /// Returns null if no category pattern is detected.
  String? _suggestGroupTitleFromChildren(List<CostLedgerEntry> children) {
    final itemNames = children.map((c) => c.description.toLowerCase()).toList();
    const categories = {
      'plumbing': ['pipe', 'valve', 'pvc', 'fitting', 'faucet', 'drain'],
      'electrical': ['wire', 'switch', 'outlet', 'breaker', 'conduit'],
      'hardware': ['screw', 'bolt', 'nail', 'anchor', 'bracket', 'hinge'],
      'paint': ['paint', 'primer', 'brush', 'roller', 'tape', 'stain'],
      'lumber': ['wood', 'lumber', 'plywood', 'board', '2x4', 'timber'],
      'flooring': ['tile', 'grout', 'laminate', 'vinyl', 'carpet'],
    };
    for (final cat in categories.entries) {
      for (final keyword in cat.value) {
        if (itemNames.any((n) => n.contains(keyword))) {
          return '${cat.key[0].toUpperCase()}${cat.key.substring(1)} supplies';
        }
      }
    }
    // Fallback: first item + count
    if (children.length > 1) {
      return '${children.first.description} + ${children.length - 1} more';
    }
    return null;
  }

  /// Generate an AI-style cost-event title from receipt line items.
  /// Examples: "Plumbing supplies", "Deck install hardware"
  String _suggestCostEventTitle(ReceiptAiResult aiResult) {
    if (aiResult.items.isEmpty) return 'Purchased items';
    final itemNames = aiResult.items.map((i) => i.name.toLowerCase()).toList();

    // Look for common trade categories in the item names
    const categories = {
      'plumbing': ['pipe', 'valve', 'pvc', 'fitting', 'faucet', 'drain'],
      'electrical': ['wire', 'switch', 'outlet', 'breaker', 'conduit'],
      'hardware': ['screw', 'bolt', 'nail', 'anchor', 'bracket', 'hinge'],
      'paint': ['paint', 'primer', 'brush', 'roller', 'tape', 'stain'],
      'lumber': ['wood', 'lumber', 'plywood', 'board', '2x4', 'timber'],
      'flooring': ['tile', 'grout', 'laminate', 'vinyl', 'carpet'],
    };

    for (final cat in categories.entries) {
      for (final keyword in cat.value) {
        if (itemNames.any((n) => n.contains(keyword))) {
          return '${cat.key[0].toUpperCase()}${cat.key.substring(1)} supplies';
        }
      }
    }

    // Generic fallback from first item
    if (aiResult.items.length == 1) return aiResult.items.first.name;
    return '${aiResult.items.first.name} + ${aiResult.items.length - 1} more';
  }

  // ── Detail: Logged Expense ──────────────────────────────────────────────────

  void _showExpenseDetails(BuildContext context, Expense expense, String cs,
      {bool isLinked = false, String? linkedToMaterialId}) {
    final dateFormat = DateFormat('EEEE, MMM d, y');

    // Parse AI-extracted items from OCR text if available
    ReceiptAiResult? aiResult;
    if (expense.ocrText != null && expense.ocrText!.isNotEmpty) {
      try {
        aiResult = ReceiptAiResult.fromJsonString(expense.ocrText!);
        if (aiResult.items.isEmpty) aiResult = null;
      } catch (e) {
        debugPrint('Expense AI result parse failed: $e');
      }
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
        builder: (_, controller) => Column(
          children: [
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(expense.category)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: _getCategoryColor(expense.category),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expense.category.displayName,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.overdue(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$cs${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.overdue(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Linked expense banner
                  if (isLinked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.paid(context).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.paid(context).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link,
                              size: 15, color: AppColors.paid(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Linked to an invoice material. Replaces the invoice estimate in totals.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.paid(context),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Unassigned banner for expenses with no job
                  if (!isLinked && expense.jobId == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.shade700.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline,
                              size: 15, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Not assigned to a job yet. Assign it, or keep it as a general business cost.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // AI-Extracted Receipt Items Table
                  if (aiResult != null) ...[
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
                            Icon(Icons.store,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 18),
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
                        border: Border.all(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant))),
                                SizedBox(
                                    width: 40,
                                    child: Text('QTY',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant))),
                                const SizedBox(width: 8),
                                SizedBox(
                                    width: 70,
                                    child: Text('PRICE',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant))),
                              ],
                            ),
                          ),
                          ...aiResult.items.asMap().entries.map((mapEntry) {
                            final item = mapEntry.value;
                            final isLast =
                                mapEntry.key == aiResult!.items.length - 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerLow)),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
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
                          if (aiResult.subtotal != null ||
                              aiResult.tax != null ||
                              aiResult.total != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(11)),
                                border: Border(
                                    top: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant)),
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
                    _detailRow(Icons.payment, 'Payment',
                        expense.paymentMethod!.displayName),
                  _detailRow(
                    expense.taxDeductible ? Icons.check_circle : Icons.cancel,
                    'Tax Deductible',
                    expense.taxDeductible ? 'Yes' : 'No',
                    color: expense.taxDeductible
                        ? AppColors.paid(context)
                        : Theme.of(context).colorScheme.error,
                  ),
                  if (expense.hasReceipt)
                    _detailRow(Icons.attach_file, 'Receipt', 'Attached'),
                  if (expense.hasReceipt) const SizedBox(height: 8),
                  if (expense.hasReceipt)
                    _buildReceiptPreview(context, expense),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Sticky footer: Edit / Delete
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
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
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(ctx, expense, isLinked: isLinked),
                        icon: Icon(Icons.delete,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        label: Text('Delete',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color)),
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
              color: hasUrl
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasUrl ? 'Backed up to cloud storage' : 'Stored on this device',
              style: TextStyle(
                fontSize: 12,
                color: hasUrl
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
      child: Icon(Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  // ── Delete with Safety ──────────────────────────────────────────────────────

  void _confirmDelete(BuildContext sheetCtx, Expense expense,
      {bool isLinked = false}) {
    final warningText = isLinked
        ? 'This expense is backing the actual cost for an invoice material. '
            'Deleting it will revert that material back to its estimated invoice cost.\n\n'
            'Delete "${expense.description}"?'
        : 'This will permanently remove "${expense.description}"';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(warningText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(sheetCtx);
              try {
                await ref
                    .read(expenseListProvider.notifier)
                    .deleteExpense(expense.id);
                if (mounted) {
                  ref.invalidate(costBreakdownProvider);
                  ref.invalidate(costLedgerProvider);
                  ref.invalidate(needsActionProvider);
                  try {
                    ref.read(analyticsProvider.notifier).refresh();
                  } catch (_) {}
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('Delete failed. Please try again.'),
                        backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
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

  // ── Category Helpers ────────────────────────────────────────────────────────

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

/// Simple badge info holder.
class _BadgeInfo {
  final String label;
  final Color color;
  const _BadgeInfo(this.label, this.color);
}

/// A row in the expenses display list — either a single entry or a grouped
/// invoice with multiple material cost children.
class _DisplayRow {
  /// For single (ungrouped) entries.
  final CostLedgerEntry? entry;

  /// For grouped invoice material entries — the child material costs.
  final List<CostLedgerEntry>? children;

  /// Linked expenses folded into this group (informational only).
  final List<CostLedgerEntry>? linkedEntries;

  _DisplayRow.single(CostLedgerEntry this.entry)
      : children = null,
        linkedEntries = null;

  _DisplayRow.group(List<CostLedgerEntry> this.children, {this.linkedEntries})
      : entry = null;

  bool get isGroup => children != null && children!.length > 1;

  DateTime get displayDate {
    if (isGroup) {
      return children!
          .map((c) => c.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    return entry!.date;
  }

  double get totalAmount {
    if (isGroup) {
      return children!.fold(0.0, (sum, c) => sum + c.amount);
    }
    return entry!.amount;
  }

  String? get invoiceNumber =>
      isGroup ? children!.first.invoiceNumber : entry!.invoiceNumber;
  String? get clientName =>
      isGroup ? children!.first.clientName : entry!.clientName;
  String? get jobName => isGroup ? children!.first.jobName : entry!.jobName;
  String? get jobId => isGroup ? children!.first.jobId : entry!.jobId;

  int get estimatedCount => isGroup
      ? children!.where((c) => c.isEstimated).length
      : (entry!.isEstimated ? 1 : 0);

  int get actualCount => isGroup
      ? children!.where((c) => !c.isEstimated).length
      : (entry!.isEstimated ? 0 : 1);

  int get linkedCount => linkedEntries?.length ?? 0;

  int get itemCount => isGroup ? children!.length : 1;
}
