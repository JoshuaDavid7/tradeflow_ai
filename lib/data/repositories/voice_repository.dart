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
  Future<Map<String, dynamic>> extractJobData(String transcript, {Map<String, dynamic>? currentState});
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
  Future<Map<String, dynamic>> extractJobData(String transcript, {Map<String, dynamic>? currentState}) async {
    try {
      final body = <String, dynamic>{'transcript': transcript};
      if (currentState != null) {
        body['currentState'] = currentState;
      }
      final response = await _supabase.invokeFunction(
        functionName: 'process_job',
        body: body,
      );

      // If response is wrapped in 'result' key
      if (response.containsKey('result') && response['result'] is Map) {
        return response['result'] as Map<String, dynamic>;
      }

      ErrorHandler.debug('Job data extracted', {
        'hasClient': response.containsKey('clientName'),
        'hasMaterials': response.containsKey('materials'),
      });

      return response;
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
