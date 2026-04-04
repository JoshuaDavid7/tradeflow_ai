import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/history_screen.dart';
import '../providers/ai_assistant_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/ai_action_coordinator.dart';
import '../widgets/ai_assistant_overlay.dart';
import 'analytics/analytics_dashboard.dart';
import 'customer_ledger/customer_ledger_screen.dart';
import 'dashboard_screen_new.dart';
import 'expenses/expense_list_screen.dart';
import 'expenses/add_expense_screen.dart';

/// Incremented to trigger the add-customer dialog from the shell FAB.
final addCustomerTriggerProvider = StateProvider<int>((ref) => 0);

/// The persistent shell that holds the bottom navigation bar and an
/// [IndexedStack] of top-level tab bodies.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  final List<Widget?> _tabs = List<Widget?>.filled(5, null);

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

  void _triggerAddCustomer() {
    ref.read(addCustomerTriggerProvider.notifier).state++;
  }

  Future<void> _openAssistant(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(aiAssistantProvider.notifier);
    final result = await showAiAssistantOverlay(
      context,
      notifier: notifier,
    );

    if (result != null && context.mounted) {
      await ref.read(aiActionCoordinatorProvider).execute(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: List.generate(5, (index) {
              if (index == selectedIndex && _tabs[index] == null) {
                _tabs[index] = _buildTab(index);
              }
              return _tabs[index] ?? const SizedBox.shrink();
            }),
          ),

          // ── Right-side FAB stack: action on top, mic below ──
          // Mic sits at the very bottom for easy thumb access.
          // Hidden on Home which has its own "Start with voice" card.
          if (selectedIndex != 0)
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Screen-specific action (add expense, add client)
                  if (selectedIndex == 2) // Expenses
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FloatingActionButton(
                        heroTag: 'shell_expense_fab',
                        elevation: 2,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          );
                        },
                        child: const Icon(Icons.add),
                      ),
                    ),
                  if (selectedIndex == 3) // Clients
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FloatingActionButton(
                        heroTag: 'shell_client_fab',
                        elevation: 2,
                        onPressed: () => _triggerAddCustomer(),
                        child: const Icon(Icons.person_add),
                      ),
                    ),
                  // AI mic — always at the bottom for thumb reach
                  _AiAssistantFab(
                    onTap: () => _openAssistant(context, ref),
                  ),
                ],
              ),
            ),
        ],
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

class _AiAssistantFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAssistantFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      key: const ValueKey('ai_assistant_fab'),
      heroTag: 'ai_assistant',
      elevation: 2,
      tooltip: 'Ask AI',
      backgroundColor: colorScheme.primary,
      shape: const CircleBorder(),
      onPressed: onTap,
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
    );
  }
}
