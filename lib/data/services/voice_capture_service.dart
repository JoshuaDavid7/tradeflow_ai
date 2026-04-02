import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/retry_util.dart';
import '../../core/utils/connectivity_service.dart';
import '../repositories/voice_repository.dart';

/// Voice capture state
enum VoiceCaptureState {
  idle,
  recording,
  processing,
  uploading,
  transcribing,
  extracting,
  completed,
  error,
}

/// Voice capture result
class VoiceCaptureResult {
  final String transcript;
  final String storagePath;
  final Map<String, dynamic> extractedData;

  const VoiceCaptureResult({
    required this.transcript,
    required this.storagePath,
    required this.extractedData,
  });
}

/// Voice capture progress
class VoiceCaptureProgress {
  final VoiceCaptureState state;
  final double progress; // 0.0 to 1.0
  final String? message;
  final String? error;

  const VoiceCaptureProgress({
    required this.state,
    this.progress = 0.0,
    this.message,
    this.error,
  });

  VoiceCaptureProgress copyWith({
    VoiceCaptureState? state,
    double? progress,
    String? message,
    String? error,
  }) {
    return VoiceCaptureProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error,
    );
  }

  bool get isActive =>
      state == VoiceCaptureState.recording ||
      state == VoiceCaptureState.processing ||
      state == VoiceCaptureState.uploading ||
      state == VoiceCaptureState.transcribing ||
      state == VoiceCaptureState.extracting;

  bool get isComplete => state == VoiceCaptureState.completed;
  bool get hasError => state == VoiceCaptureState.error;
}

/// Enhanced voice capture service with retry, offline queue, and progress tracking
class VoiceCaptureService {
  static const int _minimumRecordingBytes = 1000;
  static const Duration _recordingFinalizeTimeout = Duration(seconds: 3);
  static const Duration _recordingFinalizePollInterval =
      Duration(milliseconds: 150);
  static const Duration _minimumRecordingDuration = Duration(seconds: 1);

  final AudioRecorder _recorder = AudioRecorder();
  final IVoiceRepository _repository;
  final ConnectivityService _connectivity;

  String? _currentPath;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  // Progress callback
  void Function(VoiceCaptureProgress)? onProgress;

  VoiceCaptureService(this._repository, this._connectivity);

  /// Start recording with progress tracking
  Future<void> startRecording() async {
    try {
      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.recording,
          progress: 0.0,
          message: 'Requesting microphone permission...',
        ),
      );

      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw VoiceCaptureException.permissionDenied();
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _currentPath =
          '${tempDir.path}/job_capture_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        iosConfig: IosRecordConfig(
          categoryOptions: [
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
            IosAudioCategoryOption.overrideMutedMicrophoneInterruption,
          ],
        ),
      );

      // Check recorder permission at native level
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw VoiceCaptureException.permissionDenied();
      }

      // Start recording
      await _recorder.start(config, path: _currentPath!);

      // Verify recording state
      var isRecording = await _recorder.isRecording();
      if (!isRecording) {
        await Future.delayed(const Duration(milliseconds: 200));
        isRecording = await _recorder.isRecording();
      }
      if (!isRecording) {
        throw VoiceCaptureException.recordingFailed();
      }

      _recordingStartTime = DateTime.now();

      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.recording,
          progress: 0.1,
          message: 'Recording... Speak clearly about the job',
        ),
      );

      // Start recording timer for progress updates
      _startRecordingTimer();

      ErrorHandler.info('Recording started', {'path': _currentPath});
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      _updateProgress(
        VoiceCaptureProgress(
          state: VoiceCaptureState.error,
          error: error is VoiceCaptureException
              ? error.message
              : 'Failed to start recording',
        ),
      );
      rethrow;
    }
  }

  /// Start timer for recording duration updates
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        final seconds = duration.inSeconds;

        _updateProgress(
          VoiceCaptureProgress(
            state: VoiceCaptureState.recording,
            progress:
                0.1 + (seconds / 300.0) * 0.1, // Max 30 seconds contribution
            message: 'Recording... ${seconds}s',
          ),
        );
      }
    });
  }

  /// Stop recording and process with full pipeline
  Future<VoiceCaptureResult> stopAndProcess() async {
    File? recordedFile;

    try {
      // Stop recording timer
      _recordingTimer?.cancel();

      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.processing,
          progress: 0.2,
          message: 'Stopping recording...',
        ),
      );

      final path = await _recorder.stop() ?? _currentPath;
      if (path == null) {
        throw VoiceCaptureException.recordingFailed();
      }

      recordedFile = File(path);
      if (!await recordedFile.exists()) {
        throw VoiceCaptureException.recordingFailed();
      }

      final recordingDuration = _recordingStartTime == null
          ? Duration.zero
          : DateTime.now().difference(_recordingStartTime!);
      final fileSize = await _awaitFinalizedRecordingSize(recordedFile);
      ErrorHandler.info('Recording stopped', {
        'path': path,
        'size': fileSize,
        'durationMs': recordingDuration.inMilliseconds,
      });

      // Validate recording has actual audio data
      if (fileSize < _minimumRecordingBytes) {
        final durationSeconds =
            (recordingDuration.inMilliseconds / 1000).toStringAsFixed(1);
        final message = recordingDuration < _minimumRecordingDuration
            ? 'Recording was stopped too quickly (${durationSeconds}s). '
                'Please speak for at least 2 seconds before tapping stop.'
            : 'Recording did not capture usable audio ($fileSize bytes after waiting). '
                'Please make sure the microphone is available and try again.';
        throw VoiceCaptureException(
          message: message,
          code: 'EMPTY_RECORDING',
        );
      }

      // Check connectivity
      if (_connectivity.isOffline) {
        // Queue for later processing
        await _queueForLater(recordedFile);
        throw NetworkException(
          message:
              'No internet connection. Recording saved for later processing.',
          code: 'OFFLINE_QUEUED',
        );
      }

      // Upload with progress
      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.uploading,
          progress: 0.3,
          message: 'Uploading audio...',
        ),
      );

      final storagePath = await _uploadWithRetry(recordedFile);

      // Transcribe with progress
      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.transcribing,
          progress: 0.5,
          message: 'Transcribing speech...',
        ),
      );

      final transcript = await _transcribeWithRetry(storagePath);

      // Extract job data with progress
      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.extracting,
          progress: 0.8,
          message: 'Extracting job details...',
        ),
      );

      Map<String, dynamic> extractedData;
      try {
        extractedData = await _extractWithRetry(transcript);
      } catch (error) {
        ErrorHandler.warning(
          'Voice extraction failed, using transcript fallback',
          {
            'error': error.toString(),
            'transcriptLength': transcript.length,
          },
        );
        extractedData = _buildFallbackDraftFromTranscript(transcript);
      }

      // Cleanup
      await recordedFile.delete();
      recordedFile = null;

      _updateProgress(
        VoiceCaptureProgress(
          state: VoiceCaptureState.completed,
          progress: 1.0,
          message: extractedData['materials'] is List &&
                  (extractedData['materials'] as List).isEmpty
              ? 'Transcript ready. Review the draft details.'
              : 'Job details extracted successfully!',
        ),
      );

      ErrorHandler.info('Voice capture completed successfully');

      return VoiceCaptureResult(
        transcript: transcript,
        storagePath: storagePath,
        extractedData: extractedData,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);

      final errorMessage =
          error is AppException ? error.message : 'Failed to process recording';

      _updateProgress(
        VoiceCaptureProgress(
          state: VoiceCaptureState.error,
          error: errorMessage,
        ),
      );

      rethrow;
    } finally {
      _recordingStartTime = null;
      _currentPath = null;

      if (recordedFile != null) {
        try {
          if (await recordedFile.exists()) {
            await recordedFile.delete();
          }
        } catch (_) {
          // Best-effort cleanup only.
        }
      }
    }
  }

  Future<int> _awaitFinalizedRecordingSize(File file) async {
    if (Platform.isIOS) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    final stopwatch = Stopwatch()..start();
    var lastSize = -1;
    var stableReadCount = 0;

    while (stopwatch.elapsed < _recordingFinalizeTimeout) {
      if (!await file.exists()) {
        await Future.delayed(_recordingFinalizePollInterval);
        continue;
      }

      final currentSize = await file.length();
      if (currentSize == lastSize) {
        stableReadCount++;
      } else {
        stableReadCount = 0;
        lastSize = currentSize;
      }

      final isStable = stableReadCount >= 2;
      if (currentSize >= _minimumRecordingBytes && isStable) {
        return currentSize;
      }

      if (currentSize > _minimumRecordingBytes * 4) {
        return currentSize;
      }

      await Future.delayed(_recordingFinalizePollInterval);
    }

    return (await file.exists()) ? await file.length() : 0;
  }

  Map<String, dynamic> _buildFallbackDraftFromTranscript(String transcript) {
    final cleanedTranscript = transcript.trim();

    return {
      'clientName': '',
      'type': _inferDocumentType(cleanedTranscript),
      'description': cleanedTranscript,
      'laborHours': _inferLaborHours(cleanedTranscript),
      'laborType': 'profile',
      'materials': <Map<String, dynamic>>[],
      'voiceTranscript': cleanedTranscript,
    };
  }

  String _inferDocumentType(String transcript) {
    final normalized = transcript.toLowerCase();
    if (normalized.contains('quote') || normalized.contains('estimate')) {
      return 'quote';
    }
    return 'invoice';
  }

  double _inferLaborHours(String transcript) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:hour|hours|hr|hrs)\b',
      caseSensitive: false,
    ).firstMatch(transcript);

    if (match == null) {
      return 1.0;
    }

    return double.tryParse(match.group(1) ?? '') ?? 1.0;
  }

  /// Upload file with retry logic
  Future<String> _uploadWithRetry(File file) async {
    return RetryUtil.retry(
      () => _repository.uploadAudio(file),
      config: const RetryConfig.aggressive(),
      onRetry: (attempt, error) {
        _updateProgress(
          VoiceCaptureProgress(
            state: VoiceCaptureState.uploading,
            progress: 0.3 + (attempt * 0.05),
            message: 'Upload attempt $attempt...',
          ),
        );
      },
    );
  }

  /// Transcribe with retry logic
  Future<String> _transcribeWithRetry(String storagePath) async {
    return RetryUtil.retry(
      () => _repository.transcribeAudio(storagePath),
      config: const RetryConfig(maxAttempts: 2, initialDelay: Duration(seconds: 1)),
      onRetry: (attempt, error) {
        _updateProgress(
          VoiceCaptureProgress(
            state: VoiceCaptureState.transcribing,
            progress: 0.5 + (attempt * 0.05),
            message: 'Transcription attempt $attempt...',
          ),
        );
      },
    );
  }

  /// Extract job data with retry logic
  Future<Map<String, dynamic>> _extractWithRetry(String transcript) async {
    return RetryUtil.retry(
      () => _repository.extractJobData(transcript),
      config: const RetryConfig(maxAttempts: 2, initialDelay: Duration(seconds: 1)),
      onRetry: (attempt, error) {
        _updateProgress(
          VoiceCaptureProgress(
            state: VoiceCaptureState.extracting,
            progress: 0.8 + (attempt * 0.05),
            message: 'Extraction attempt $attempt...',
          ),
        );
      },
    );
  }

  /// Queue recording for later processing when offline
  Future<void> _queueForLater(File file) async {
    try {
      // Move to persistent storage
      final appDir = await getApplicationDocumentsDirectory();
      final queueDir = Directory('${appDir.path}/voice_queue');
      if (!await queueDir.exists()) {
        await queueDir.create(recursive: true);
      }

      final queuedPath =
          '${queueDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await file.copy(queuedPath);

      ErrorHandler.info('Recording queued for later', {'path': queuedPath});
    } catch (error) {
      ErrorHandler.warning('Failed to queue recording', {'error': error});
    }
  }

  /// Process queued recordings when back online
  Future<List<VoiceCaptureResult>> processQueuedRecordings() async {
    final results = <VoiceCaptureResult>[];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final queueDir = Directory('${appDir.path}/voice_queue');

      if (!await queueDir.exists()) {
        return results;
      }

      final files =
          await queueDir.list().where((e) => e.path.endsWith('.m4a')).toList();

      for (final file in files) {
        try {
          final storagePath = await _uploadWithRetry(File(file.path));
          final transcript = await _transcribeWithRetry(storagePath);
          final extractedData = await _extractWithRetry(transcript);

          results.add(VoiceCaptureResult(
            transcript: transcript,
            storagePath: storagePath,
            extractedData: extractedData,
          ));

          // Delete processed file
          await file.delete();
        } catch (error) {
          ErrorHandler.warning('Failed to process queued recording', {
            'file': file.path,
            'error': error,
          });
        }
      }
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
    }

    return results;
  }

  /// Update progress callback
  void _updateProgress(VoiceCaptureProgress progress) {
    onProgress?.call(progress);
  }

  /// Cancel current recording
  Future<void> cancel() async {
    try {
      _recordingTimer?.cancel();
      await _recorder.stop();

      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _recordingStartTime = null;
      _currentPath = null;

      _updateProgress(
        const VoiceCaptureProgress(
          state: VoiceCaptureState.idle,
          message: 'Recording cancelled',
        ),
      );
    } catch (error) {
      ErrorHandler.warning('Failed to cancel recording', {'error': error});
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    await _recorder.dispose();
  }
}
