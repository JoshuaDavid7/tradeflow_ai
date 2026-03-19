/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noConnection() => NetworkException(
        message: 'No internet connection. Please check your network.',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  factory NetworkException.serverError() => NetworkException(
        message: 'Server error. Please try again later.',
        code: 'SERVER_ERROR',
      );
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.notAuthenticated() => AuthException(
        message: 'You must be signed in to perform this action.',
        code: 'NOT_AUTHENTICATED',
      );

  factory AuthException.sessionExpired() => AuthException(
        message: 'Your session has expired. Please sign in again.',
        code: 'SESSION_EXPIRED',
      );
}

/// Database-related exceptions
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DatabaseException.queryFailed() => DatabaseException(
        message: 'Failed to fetch data. Please try again.',
        code: 'QUERY_FAILED',
      );

  factory DatabaseException.writeFailed() => DatabaseException(
        message: 'Failed to save data. Please try again.',
        code: 'WRITE_FAILED',
      );
}

/// Voice capture exceptions
class VoiceCaptureException extends AppException {
  VoiceCaptureException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory VoiceCaptureException.permissionDenied() => VoiceCaptureException(
        message: 'Microphone permission is required to record audio.',
        code: 'PERMISSION_DENIED',
      );

  factory VoiceCaptureException.recordingFailed() => VoiceCaptureException(
        message: 'Failed to record audio. Please try again.',
        code: 'RECORDING_FAILED',
      );

  factory VoiceCaptureException.uploadFailed() => VoiceCaptureException(
        message: 'Failed to upload audio. Please check your connection.',
        code: 'UPLOAD_FAILED',
      );

  factory VoiceCaptureException.transcriptionFailed() => VoiceCaptureException(
        message: 'Could not understand the audio. Please speak clearly.',
        code: 'TRANSCRIPTION_FAILED',
      );

  factory VoiceCaptureException.extractionFailed() => VoiceCaptureException(
        message: 'Failed to extract job details. Please try again.',
        code: 'EXTRACTION_FAILED',
      );
}

/// Storage exceptions
class StorageException extends AppException {
  StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.uploadFailed() => StorageException(
        message: 'Failed to upload file. Please try again.',
        code: 'UPLOAD_FAILED',
      );

  factory StorageException.downloadFailed() => StorageException(
        message: 'Failed to download file. Please try again.',
        code: 'DOWNLOAD_FAILED',
      );
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.required(String field) => ValidationException(
        message: '$field is required',
        code: 'REQUIRED_FIELD',
        fieldErrors: {field: 'This field is required'},
      );

  factory ValidationException.invalid(String field, String reason) =>
      ValidationException(
        message: 'Invalid $field: $reason',
        code: 'INVALID_FIELD',
        fieldErrors: {field: reason},
      );
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory BusinessException.subscriptionRequired() => BusinessException(
        message: 'This feature requires a Pro subscription.',
        code: 'SUBSCRIPTION_REQUIRED',
      );

  factory BusinessException.limitReached() => BusinessException(
        message: 'You have reached your monthly limit. Please upgrade.',
        code: 'LIMIT_REACHED',
      );
}
