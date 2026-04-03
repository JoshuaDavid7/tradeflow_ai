import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/history_screen.dart';
import '../../screens/draft_review_screen.dart';
import 'dashboard_screen_new.dart';
import 'expenses/expense_list_screen.dart';
import 'expenses/add_expense_screen.dart';
import 'analytics/analytics_dashboard.dart';
import 'customer_ledger/customer_ledger_screen.dart';
import '../providers/ai_assistant_provider.dart';
import '../../data/services/ai_command_service.dart';
import '../providers/job_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/profile_provider.dart';

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
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
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
      body: IndexedStack(
        index: selectedIndex,
        children: List.generate(5, (i) {
          if (i == selectedIndex && _tabs[i] == null) {
            _tabs[i] = _buildTab(i);
          }
          return _tabs[i] ?? const SizedBox.shrink();
        }),
      ),

      // ── Global AI Assistant FAB ──
      floatingActionButton: _AiAssistantFab(
        onResult: (result) => _handleAiAction(context, result),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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

  /// Execute the AI's returned action.
  void _handleAiAction(BuildContext context, AiCommandResult result) {
    switch (result.action) {
      case 'navigate':
        _handleNavigate(result.params);
        break;
      case 'create_invoice':
        _handleCreateInvoice(context, result.params);
        break;
      case 'create_expense':
        _handleCreateExpense(context, result.params);
        break;
      case 'record_payment':
        _handleRecordPayment(context, result.params);
        break;
      case 'update_settings':
        _handleUpdateSettings(result.params);
        break;
      case 'answer':
        // Response is already shown in the overlay — nothing to execute.
        break;
    }
  }

  void _handleNavigate(Map<String, dynamic> params) {
    final screen = params['screen']?.toString() ?? '';
    final tabMap = {
      'home': 0,
      'jobs': 1,
      'expenses': 2,
      'clients': 3,
      'analytics': 4,
    };

    if (tabMap.containsKey(screen)) {
      ref.read(bottomNavIndexProvider.notifier).state = tabMap[screen]!;
    } else if (screen == 'drafts') {
      ref.read(historyInitialTabProvider.notifier).state = 1;
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    } else if (screen == 'sent') {
      ref.read(historyInitialTabProvider.notifier).state = 2;
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    } else if (screen == 'paid') {
      ref.read(historyInitialTabProvider.notifier).state = 3;
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    } else if (screen == 'settings') {
      Navigator.pushNamed(context, '/settings');
    }
  }

  void _handleCreateInvoice(
      BuildContext context, Map<String, dynamic> params) {
    // Build job data map matching what DraftReviewScreen expects.
    final jobData = <String, dynamic>{
      'clientName': params['clientName'] ?? '',
      'type': params['type'] ?? 'invoice',
      'description': params['description'] ?? '',
      'laborHours': params['laborHours'] ?? 1.0,
      'laborType': params['laborType'] ?? 'profile',
      'materials': params['materials'] ?? [],
    };
    if (params['laborRate'] != null) {
      jobData['laborRate'] = params['laborRate'];
    }
    if (params['laborAmount'] != null) {
      jobData['laborAmount'] = params['laborAmount'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DraftReviewScreen(jobData: jobData),
      ),
    );
  }

  void _handleCreateExpense(
      BuildContext context, Map<String, dynamic> params) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialData: {
            'amount': params['amount'],
            'description': params['description'],
            'vendor': params['vendor'],
            'category': params['category'],
            'taxDeductible': params['taxDeductible'] ?? false,
          },
        ),
      ),
    );
  }

  void _handleRecordPayment(
      BuildContext context, Map<String, dynamic> params) {
    // Navigate to Jobs tab (Sent) so user can confirm which invoice to apply to.
    // Show a helpful snackbar with the payment details.
    ref.read(historyInitialTabProvider.notifier).state = 2; // Sent tab
    ref.read(historyOutstandingFilterProvider.notifier).state = true;
    ref.read(bottomNavIndexProvider.notifier).state = 1;

    final client = params['clientName'] ?? '';
    final amount = params['amount'] ?? 0;
    final method = params['method'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tap "$client" invoice to record \$${amount} $method payment',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleUpdateSettings(Map<String, dynamic> params) async {
    try {
      final profileState = ref.read(profileProvider);
      final current = profileState.profile;
      if (current == null) return;

      // Build updated profile with changed fields
      final updated = current.copyWith(
        defaultHourlyRate: params['hourlyRate'] != null
            ? (params['hourlyRate'] as num).toDouble()
            : null,
        defaultTaxRate: params['taxRate'] != null
            ? (params['taxRate'] as num).toDouble()
            : null,
        defaultMarkupPercent: params['markupPercent'] != null
            ? (params['markupPercent'] as num).toDouble()
            : null,
      );

      final notifier = ref.read(profileProvider.notifier);
      await notifier.updateProfile(updated);
    } catch (_) {
      // Error handled by the profile provider.
    }
  }
}

// ─────────────────────────────────────────────────────────────
// AI Assistant Floating Action Button
// ─────────────────────────────────────────────────────────────

class _AiAssistantFab extends ConsumerWidget {
  final void Function(AiCommandResult result) onResult;

  const _AiAssistantFab({required this.onResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      key: const ValueKey('ai_assistant_fab'),
      heroTag: 'ai_assistant',
      elevation: 2,
      backgroundColor: colorScheme.primary,
      shape: const CircleBorder(),
      onPressed: () => _openAssistant(context, ref),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
    );
  }

  void _openAssistant(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(aiAssistantProvider.notifier);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _AiAssistantOverlay(
          notifier: notifier,
          onResult: onResult,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AI Assistant Full-Screen Overlay
// ─────────────────────────────────────────────────────────────

class _AiAssistantOverlay extends StatefulWidget {
  final AiAssistantNotifier notifier;
  final void Function(AiCommandResult result) onResult;

  const _AiAssistantOverlay({
    required this.notifier,
    required this.onResult,
  });

  @override
  State<_AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<_AiAssistantOverlay> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isDone = false;
  String _statusText = 'Starting...';
  String? _responseText;
  String? _actionLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRecording();
    });
  }

  Future<void> _startRecording() async {
    try {
      await widget.notifier.startRecording();
      if (mounted) {
        setState(() {
          _isRecording = true;
          _statusText = 'Listening... what would you like to do?';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _statusText = 'Could not start recording. Tap mic to retry.');
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isDone) {
      // If done, close the overlay
      widget.notifier.reset();
      if (mounted) Navigator.pop(context);
      return;
    }

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = 'Processing...';
      });
      try {
        final result = await widget.notifier
            .stopAndProcess()
            .timeout(const Duration(seconds: 50));

        if (result == null) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusText = 'Could not process audio. Tap mic to try again.';
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isDone = true;
            _responseText = result.response;
            _statusText = result.response;
            _actionLabel = _actionToLabel(result.action);
          });

          // Execute the action after a brief pause so user sees the response.
          Future.delayed(const Duration(milliseconds: 800), () {
            if (result.action != 'answer') {
              widget.onResult(result);
              // Auto-close for navigation and non-answer actions
              if (mounted && result.action == 'navigate') {
                widget.notifier.reset();
                Navigator.pop(context);
              }
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusText = 'Timed out. Tap mic to try again.';
          });
        }
      }
    } else {
      // Start a new recording (retry)
      setState(() {
        _isDone = false;
        _responseText = null;
        _actionLabel = null;
      });
      await _startRecording();
    }
  }

  String _actionToLabel(String action) {
    switch (action) {
      case 'create_invoice':
        return 'Creating invoice...';
      case 'create_expense':
        return 'Logging expense...';
      case 'record_payment':
        return 'Recording payment...';
      case 'navigate':
        return 'Navigating...';
      case 'update_settings':
        return 'Updating settings...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () {
            widget.notifier.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text(
          _isProcessing
              ? 'Processing...'
              : _isDone
                  ? 'Done'
                  : _isRecording
                      ? 'Listening...'
                      : 'AI Assistant',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Animated mic button ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 140 : (_isDone ? 100 : 100),
              height: _isRecording ? 140 : (_isDone ? 100 : 100),
              decoration: BoxDecoration(
                color: _isDone
                    ? Colors.green.withValues(alpha: 0.08)
                    : (_isRecording
                            ? colorScheme.error
                            : colorScheme.primary)
                        .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _isProcessing ? null : _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _isDone
                          ? Colors.green
                          : _isRecording
                              ? colorScheme.error
                              : colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isDone
                                  ? Colors.green
                                  : _isRecording
                                      ? colorScheme.error
                                      : colorScheme.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : Icon(
                            _isDone
                                ? Icons.check_rounded
                                : _isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Status / Response text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDone
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontSize: _isDone ? 16 : 15,
                  fontWeight: _isDone ? FontWeight.w600 : FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),

            if (_actionLabel != null && _actionLabel!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _actionLabel!,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Tap hint ──
            Text(
              _isDone
                  ? 'Tap to dismiss'
                  : _isRecording
                      ? 'Tap to stop'
                      : _isProcessing
                          ? ''
                          : 'Tap mic to start',
              style: TextStyle(
                color: _isRecording
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const Spacer(flex: 3),

            // ── Suggestion chips (shown when idle/recording) ──
            if (!_isDone && !_isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _SuggestionChip('"Invoice David for 3 hours"'),
                    _SuggestionChip('"How much am I owed?"'),
                    _SuggestionChip('"Spent \$50 at Bunnings"'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
