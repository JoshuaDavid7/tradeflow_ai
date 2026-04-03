import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_command_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/voice_capture_service.dart';
import '../../data/repositories/voice_repository.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/errors/error_handler.dart';
import '../screens/main_shell_screen.dart' show bottomNavIndexProvider;
import 'profile_provider.dart';
import 'job_provider.dart';
import 'expense_provider.dart';
import 'customer_ledger_provider.dart';

/// State for the global AI assistant.
enum AiAssistantStatus { idle, recording, processing, done, error }

class AiAssistantState {
  final AiAssistantStatus status;
  final String? statusMessage;
  final AiCommandResult? lastResult;

  const AiAssistantState({
    this.status = AiAssistantStatus.idle,
    this.statusMessage,
    this.lastResult,
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    String? statusMessage,
    AiCommandResult? lastResult,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Provider for AI command service.
final aiCommandServiceProvider = Provider<AiCommandService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AiCommandService(supabase);
});

/// Provider for a dedicated voice capture service for the global assistant.
/// Separate from the invoice-creation one so they don't interfere.
final aiVoiceCaptureServiceProvider = Provider<VoiceCaptureService>((ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  final connectivity = ConnectivityService.instance;
  return VoiceCaptureService(repository, connectivity);
});

/// The main AI assistant state notifier.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final VoiceCaptureService _voiceService;
  final AiCommandService _commandService;
  final Ref _ref;

  AiAssistantNotifier(this._voiceService, this._commandService, this._ref)
      : super(const AiAssistantState()) {
    _voiceService.onProgress = (progress) {
      if (progress.state == VoiceCaptureState.recording) {
        state = state.copyWith(
          status: AiAssistantStatus.recording,
          statusMessage: progress.message,
        );
      } else if (progress.isActive) {
        state = state.copyWith(
          status: AiAssistantStatus.processing,
          statusMessage: progress.message,
        );
      }
    };
  }

  /// Start voice recording.
  Future<void> startRecording() async {
    try {
      state = const AiAssistantState(
        status: AiAssistantStatus.recording,
        statusMessage: 'Listening...',
      );
      await _voiceService.startRecording();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      state = AiAssistantState(
        status: AiAssistantStatus.error,
        statusMessage: 'Could not start recording',
      );
    }
  }

  /// Stop recording, transcribe, and process with global AI.
  Future<AiCommandResult?> stopAndProcess() async {
    try {
      state = state.copyWith(
        status: AiAssistantStatus.processing,
        statusMessage: 'Processing...',
      );

      // Use the voice service to record, upload, and transcribe
      // But we DON'T want extraction — we want the raw transcript
      // then send it to our global command processor.
      // However, the pipeline is monolithic. We'll use stopAndProcess
      // which does extraction too, but we only need the transcript.
      // Let's just run the pipeline and ignore the extraction result.
      final voiceResult = await _voiceService.stopAndProcess();
      if (voiceResult == null) {
        state = AiAssistantState(
          status: AiAssistantStatus.error,
          statusMessage: 'Could not process audio',
        );
        return null;
      }

      state = state.copyWith(
        statusMessage: 'Thinking...',
      );

      // Build business context for the AI
      final context = await _buildBusinessContext();

      // Send transcript to global AI command processor
      final result = await _commandService.processCommand(
        voiceResult.transcript,
        context: context,
      );

      state = AiAssistantState(
        status: AiAssistantStatus.done,
        lastResult: result,
        statusMessage: result.response,
      );

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      state = AiAssistantState(
        status: AiAssistantStatus.error,
        statusMessage: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  /// Cancel current recording.
  Future<void> cancel() async {
    await _voiceService.cancel();
    state = const AiAssistantState();
  }

  /// Reset to idle.
  void reset() {
    state = const AiAssistantState();
  }

  /// Build the business context snapshot to send to the AI.
  Future<Map<String, dynamic>> _buildBusinessContext() async {
    try {
      // Get profile
      final profileState = _ref.read(profileProvider);
      final profileData = profileState.profile;

      // Get job stats
      final jobStats = _ref.read(jobStatsProvider);
      final stats = jobStats.whenOrNull(data: (s) => s);

      // Get customer names
      final customers = _ref.read(customerLedgerListProvider);
      final customerNames = customers.whenOrNull(
        data: (list) =>
            list.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList(),
      );

      // Get expense stats
      final expenseStats = _ref.read(expenseStatsProvider);
      final expenses = expenseStats.whenOrNull(data: (e) => e);

      return {
        'currentScreen': _getCurrentScreenName(),
        'stats': {
          'totalOutstanding': stats?['totalOutstanding'] ?? 0,
          'outstandingCount': stats?['outstandingInvoices'] ?? 0,
          'sentCount': stats?['sentJobs'] ?? stats?['activeJobs'] ?? 0,
          'draftCount': stats?['draftJobs'] ?? 0,
          'monthlyCollected': stats?['monthlyCollected'] ?? 0,
          'monthlyRevenue': stats?['monthlyRevenue'] ?? 0,
          'monthlyExpenses': expenses?['monthlyTotal'] ?? 0,
          'monthlyProfit':
              ((stats?['monthlyRevenue'] ?? 0) as num) -
              ((expenses?['monthlyTotal'] ?? 0) as num),
        },
        'profile': {
          'businessName': profileData?.businessName ?? '',
          'hourlyRate': profileData?.defaultHourlyRate ?? 85,
          'taxRate': profileData?.defaultTaxRate ?? 0,
          'currency': profileData?.currencySymbol ?? '\$',
        },
        'recentCustomers': customerNames ?? [],
      };
    } catch (e) {
      ErrorHandler.warning('Failed to build AI context', {'error': e});
      return {
        'currentScreen': 'unknown',
        'stats': {},
        'profile': {},
        'recentCustomers': [],
      };
    }
  }

  String _getCurrentScreenName() {
    try {
      final index = _ref.read(bottomNavIndexProvider);
      const screens = ['home', 'jobs', 'expenses', 'clients', 'analytics'];
      return screens[index];
    } catch (_) {
      return 'home';
    }
  }

  @override
  void dispose() {
    _voiceService.onProgress = null;
    _voiceService.dispose();
    super.dispose();
  }
}

/// The global AI assistant provider.
final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final voiceService = ref.watch(aiVoiceCaptureServiceProvider);
  final commandService = ref.watch(aiCommandServiceProvider);
  return AiAssistantNotifier(voiceService, commandService, ref);
});
