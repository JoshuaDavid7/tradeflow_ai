import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/voice_capture_service.dart';
import '../../data/repositories/voice_repository.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/errors/error_handler.dart';

/// Provider for voice capture service
final voiceCaptureServiceProvider = Provider<VoiceCaptureService>((ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  final connectivity = ConnectivityService.instance;
  
  return VoiceCaptureService(repository, connectivity);
});

/// Voice capture state notifier
class VoiceCaptureNotifier extends StateNotifier<VoiceCaptureProgress> {
  final VoiceCaptureService _service;

  VoiceCaptureNotifier(this._service)
      : super(const VoiceCaptureProgress(state: VoiceCaptureState.idle)) {
    // Listen to progress updates
    _service.onProgress = (progress) {
      state = progress;
    };
  }

  /// Start recording
  Future<void> startRecording() async {
    try {
      await _service.startRecording();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      // State is updated by service via onProgress callback
    }
  }

  /// Stop and process recording
  Future<VoiceCaptureResult?> stopAndProcess() async {
    try {
      final result = await _service.stopAndProcess();
      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      // State is updated by service via onProgress callback
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancel() async {
    await _service.cancel();
  }

  /// Process queued recordings
  Future<List<VoiceCaptureResult>> processQueue() async {
    try {
      return await _service.processQueuedRecordings();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      return [];
    }
  }

  /// Reset to idle state
  void reset() {
    state = const VoiceCaptureProgress(state: VoiceCaptureState.idle);
  }

  @override
  void dispose() {
    _service.onProgress = null;
    _service.dispose();
    super.dispose();
  }
}

/// Provider for voice capture state
final voiceCaptureProvider =
    StateNotifierProvider<VoiceCaptureNotifier, VoiceCaptureProgress>((ref) {
  final service = ref.watch(voiceCaptureServiceProvider);
  return VoiceCaptureNotifier(service);
});

/// Provider for recording status
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(voiceCaptureProvider).state == VoiceCaptureState.recording;
});

/// Provider for processing status
final isProcessingProvider = Provider<bool>((ref) {
  final state = ref.watch(voiceCaptureProvider).state;
  return state == VoiceCaptureState.processing ||
      state == VoiceCaptureState.uploading ||
      state == VoiceCaptureState.transcribing ||
      state == VoiceCaptureState.extracting;
});
