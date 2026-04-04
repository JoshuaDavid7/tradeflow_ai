import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Voice repository interface
abstract class IVoiceRepository {
  Future<String> uploadAudio(File file);
  Future<String> transcribeAudio(String storagePath);
  Future<Map<String, dynamic>> extractJobData(String transcript,
      {Map<String, dynamic>? currentState, List<String>? knownCustomers});
}

/// Voice repository implementation
class VoiceRepository implements IVoiceRepository {
  final SupabaseService _supabase;
  final Uuid _uuid = const Uuid();

  VoiceRepository(this._supabase);

  @override
  Future<String> uploadAudio(File file) async {
    try {
      // Generate unique filename
      final fileName = '${_uuid.v4()}.m4a';
      final platform = Platform.isIOS ? 'ios' : 'android';
      final storagePath = '$platform/$fileName';

      // Read file as bytes to ensure complete binary upload
      final bytes = await file.readAsBytes();

      ErrorHandler.debug('Audio file read', {
        'path': file.path,
        'bytesLength': bytes.length,
      });

      // Upload raw bytes to storage
      await _supabase.uploadFile(
        bucket: 'job-audio',
        path: storagePath,
        file: bytes,
        contentType: 'audio/mp4',
      );

      ErrorHandler.debug('Audio uploaded successfully', {
        'path': storagePath,
        'size': bytes.length,
      });

      return storagePath;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);

      if (error is AuthException || error is NetworkException) {
        final appError = error as AppException;
        throw VoiceCaptureException(
          message: appError.message,
          code: appError.code,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      // Pass through the actual error message for debugging
      throw VoiceCaptureException(
        message: 'Upload failed: $error',
        code: 'UPLOAD_FAILED',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _normalizeVoiceMaterialName(String name, String transcript) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final transcriptLower = transcript.toLowerCase();

    const fittingsAliases = {
      'filling',
      'fillings',
      'fizzing',
      'fizzings',
      'quidding',
      'quiddings',
    };
    if (fittingsAliases.contains(normalized)) {
      return 'Fittings';
    }

    const heaterAliases = {
      'keter',
      'keater',
      'heeter',
      'heater',
      'heaters',
    };
    if (heaterAliases.contains(normalized)) {
      return normalized.endsWith('s') ? 'Heaters' : 'Heater';
    }

    if (normalized == 'people' &&
        (transcriptLower.contains('hot water system') ||
            transcriptLower.contains('water heater'))) {
      return 'Heater';
    }

    const hoseAliases = {
      'owe',
      'owes',
      'ows',
      'os',
      'owes fittings',
      'o rings',
      'orings',
      'o rings fittings',
    };
    if (hoseAliases.contains(normalized) &&
        (transcriptLower.contains('mixer tap') ||
            transcriptLower.contains('tap'))) {
      return 'Hose';
    }

    if ((normalized == 'piece' || normalized == 'pieces') &&
        transcriptLower.contains('tile')) {
      return 'Adhesive';
    }

    return name.trim();
  }

  bool _isUnknownClientName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'unknown';
  }

  bool _isSuspiciousClientName(String name) {
    const suspicious = <String>{
      'just',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
    };
    return suspicious.contains(name.trim().toLowerCase());
  }

  String? _cleanClientNameCandidate(String candidate) {
    const stopTokens = <String>{
      'to',
      'for',
      'replace',
      'replacing',
      'flat',
      'just',
      'my',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'hour',
      'hours',
      'labor',
      'plus',
      'and',
      'emergency',
      'call',
      'callout',
      'only',
      'no',
      'materials',
      'material',
      'faucet',
      'heater',
      'mixer',
      'tap',
      'tile',
      'tiles',
      'adhesive',
      'at',
      'of',
      'from',
    };

    final parts = candidate
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    final kept = <String>[];

    for (final part in parts) {
      final normalizedPart = part.toLowerCase();
      if (kept.isNotEmpty && stopTokens.contains(normalizedPart)) {
        break;
      }
      kept.add(part);
      if (kept.length >= 5) {
        break;
      }
    }

    if (kept.isEmpty) {
      return null;
    }

    return kept
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String? _inferClientNameFromTranscript(String transcript) {
    final patterns = <RegExp>[
      RegExp(
        r"\b(?:invoice|quote|estimate|bill)\s+for\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)",
        caseSensitive: false,
      ),
      RegExp(
        r"\b([a-z0-9][a-z0-9\s&'-]+?)\s+(?:invoice|quote|estimate|bill)\b(?=\s+(?:for|to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)",
        caseSensitive: false,
      ),
      RegExp(
        r"\b(?:invoice|quote|estimate|bill)\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:for|to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)",
        caseSensitive: false,
      ),
      RegExp(
        r"\bfor\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)",
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(transcript);
      final candidate = match?.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return _cleanClientNameCandidate(candidate);
      }
    }

    return null;
  }

  Map<String, dynamic> _normalizeExtractedResponse(
    Map<String, dynamic> response,
    String transcript,
  ) {
    final normalized = Map<String, dynamic>.from(response);
    final currentClientName =
        (normalized['clientName'] ?? '').toString().trim();
    final inferredClient = _inferClientNameFromTranscript(transcript);
    if (inferredClient != null &&
        inferredClient.isNotEmpty &&
        (_isUnknownClientName(currentClientName) ||
            _isSuspiciousClientName(currentClientName))) {
      normalized['clientName'] = inferredClient;
    }
    final rawMaterials = normalized['materials'];
    if (rawMaterials is List) {
      normalized['materials'] = rawMaterials.map((item) {
        if (item is! Map) {
          return item;
        }
        final material = Map<String, dynamic>.from(item);
        material['item'] = _normalizeVoiceMaterialName(
          material['item']?.toString() ?? '',
          transcript,
        );
        return material;
      }).toList();
    }
    return normalized;
  }

  @override
  Future<String> transcribeAudio(String storagePath) async {
    try {
      final response = await _supabase.invokeFunction(
        functionName: 'transcribe_audio',
        body: {'filePath': storagePath},
      );

      final transcript = response['transcript'] as String?;

      if (transcript == null || transcript.trim().isEmpty) {
        throw VoiceCaptureException(
          message:
              'Could not understand the audio. Please speak clearly and try again.',
          code: 'EMPTY_TRANSCRIPT',
        );
      }

      ErrorHandler.debug('Transcription successful', {
        'length': transcript.length,
      });

      return transcript;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);

      if (error is VoiceCaptureException) {
        rethrow;
      }

      final rawError = error.toString().toLowerCase();
      if (rawError.contains('no speech detected')) {
        throw VoiceCaptureException(
          message:
              'I could not catch that clearly. Try a slightly longer phrase or speak a little closer to the mic.',
          code: 'EMPTY_TRANSCRIPT',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      if (rawError.contains('audio file too small')) {
        throw VoiceCaptureException(
          message:
              'That recording was too short to process. Hold the mic a moment longer and try again.',
          code: 'EMPTY_RECORDING',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      if (error is AuthException || error is NetworkException) {
        final appError = error as AppException;
        throw VoiceCaptureException(
          message: appError.message,
          code: appError.code,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      throw VoiceCaptureException.transcriptionFailed();
    }
  }

  @override
  Future<Map<String, dynamic>> extractJobData(String transcript,
      {Map<String, dynamic>? currentState,
      List<String>? knownCustomers}) async {
    try {
      final body = <String, dynamic>{'transcript': transcript};
      if (currentState != null) {
        body['currentState'] = currentState;
      }
      if (knownCustomers != null && knownCustomers.isNotEmpty) {
        body['knownCustomers'] = knownCustomers;
      }
      final response = await _supabase.invokeFunction(
        functionName: 'process_job',
        body: body,
      );

      // If response is wrapped in 'result' key
      if (response.containsKey('result') && response['result'] is Map) {
        return _normalizeExtractedResponse(
          Map<String, dynamic>.from(response['result'] as Map),
          transcript,
        );
      }

      ErrorHandler.debug('Job data extracted', {
        'hasClient': response.containsKey('clientName'),
        'hasMaterials': response.containsKey('materials'),
      });

      return _normalizeExtractedResponse(
        Map<String, dynamic>.from(response),
        transcript,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);

      if (error is VoiceCaptureException) {
        rethrow;
      }

      if (error is AuthException || error is NetworkException) {
        final appError = error as AppException;
        throw VoiceCaptureException(
          message: appError.message,
          code: appError.code,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      throw VoiceCaptureException.extractionFailed();
    }
  }
}

/// Provider for Voice repository
final voiceRepositoryProvider = Provider<IVoiceRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return VoiceRepository(supabase);
});
