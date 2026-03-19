import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app_exception.dart';

/// Global error handler for the application
/// Converts exceptions to user-friendly messages and logs errors
class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Handle error and return user-friendly message
  static String handle(dynamic error, [StackTrace? stackTrace]) {
    // Log the error
    _logError(error, stackTrace);

    // Convert to user-friendly message
    if (error is AppException) {
      return error.message;
    }

    // Handle common errors
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication')) {
      return 'Authentication error. Please sign in again.';
    }

    if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    }

    // Generic error message
    if (kDebugMode) {
      return 'Error: $error';
    } else {
      return 'Something went wrong. Our team has been notified.';
    }
  }

  /// Log error with appropriate level
  static void _logError(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) {
      // Log custom exceptions
      if (error is NetworkException) {
        _logger.w('Network Error: ${error.message}', error: error.originalError);
      } else if (error is AuthException) {
        _logger.w('Auth Error: ${error.message}', error: error.originalError);
      } else if (error is ValidationException) {
        _logger.i('Validation Error: ${error.message}');
      } else {
        _logger.e(
          'App Error: ${error.message}',
          error: error.originalError,
          stackTrace: error.stackTrace ?? stackTrace,
        );
      }
    } else {
      // Log unexpected errors
      _logger.e(
        'Unexpected Error',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!kDebugMode && _isCriticalError(error)) {
      _sendToMonitoring(error, stackTrace);
    }
  }

  /// Determine if error is critical and should be reported
  static bool _isCriticalError(dynamic error) {
    // Don't report validation errors or user-facing errors
    if (error is ValidationException || error is BusinessException) {
      return false;
    }

    // Report all other errors in production
    return true;
  }

  /// Send error to monitoring service
  static void _sendToMonitoring(dynamic error, StackTrace? stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Log info message
  static void info(String message, [Map<String, dynamic>? data]) {
    _logger.i(message, error: data);
  }

  /// Log debug message
  static void debug(String message, [Map<String, dynamic>? data]) {
    _logger.d(message, error: data);
  }

  /// Log warning message
  static void warning(String message, [Map<String, dynamic>? data]) {
    _logger.w(message, error: data);
  }
}

/// Extension to easily convert exceptions to AppException
extension ExceptionHandler on Exception {
  AppException toAppException() {
    if (this is AppException) {
      return this as AppException;
    }

    final message = toString();

    // Try to categorize the exception
    if (message.contains('SocketException') ||
        message.contains('Network') ||
        message.contains('Connection')) {
      return NetworkException.noConnection();
    }

    if (message.contains('TimeoutException')) {
      return NetworkException.timeout();
    }

    if (message.contains('AuthException') ||
        message.contains('Unauthorized')) {
      return AuthException.notAuthenticated();
    }

    // Default to generic app exception
    return DatabaseException(
      message: 'An unexpected error occurred',
      originalError: this,
    );
  }
}
