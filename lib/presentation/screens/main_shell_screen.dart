import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/history_screen.dart';
import 'dashboard_screen_new.dart';
import 'expenses/expense_list_screen.dart';
import 'analytics/analytics_dashboard.dart';
import 'customer_ledger/customer_ledger_screen.dart';

/// Tracks the currently selected bottom-nav tab index app-wide.
/// Exposed as a StateProvider so any screen can read or update it
/// (e.g. a "See all jobs" button on Home can switch to the Jobs tab).
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// When set to a non-zero value, HistoryScreen will animate to that
/// inner tab index (0=All, 1=Draft, 2=Sent, 3=Paid) then reset to 0.
final historyInitialTabProvider = StateProvider<int>((ref) => 0);

/// When true, the Sent tab in HistoryScreen only shows invoices with
/// remaining balance > 0 (outstanding). Reset to false after use.
final historyOutstandingFilterProvider = StateProvider<bool>((ref) => false);

/// The persistent shell that holds the bottom navigation bar and an
/// [IndexedStack] of top-level tab bodies.
///
/// Detail screens pushed from within a tab use the root [Navigator], which
/// covers the shell entirely — this is the standard behaviour users expect
/// on iOS/Android.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  // We lazily initialise tab bodies so that heavy screens like Analytics
  // don't load until the user visits them.  Once created they stay alive
  // in the IndexedStack so scroll position / form state is preserved.
  final List<Widget?> _tabs = List.filled(5, null);

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const DashboardScreenNew();
      case 1:
        return const HistoryScreen();
      case 2:
        return const ExpenseListScreen();
      case 3:
        return const CustomerLedgerScreen();
      case 4:
        return const AnalyticsDashboard();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // The body is an IndexedStack: only the selected tab is visible,
      // but all previously-visited tabs stay mounted (preserving state).
      body: IndexedStack(
        index: selectedIndex,
        children: List.generate(5, (i) {
          // Only materialise tabs the user has visited (or the initial tab).
          if (i == selectedIndex && _tabs[i] == null) {
            _tabs[i] = _buildTab(i);
          }
          return _tabs[i] ?? const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        elevation: 0,
        height: 64,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          // Clear the outstanding-only filter when navigating away from
          // the Jobs tab so it doesn't persist on next visit.
          if (index != 1 && ref.read(historyOutstandingFilterProvider)) {
            ref.read(historyOutstandingFilterProvider.notifier).state = false;
          }
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
