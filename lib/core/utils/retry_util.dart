import 'dart:math';
import 'package:flutter/foundation.dart';
import '../errors/app_exception.dart';
import '../errors/error_handler.dart';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Aggressive retry for critical operations
  const RetryConfig.aggressive()
      : maxAttempts = 5,
        initialDelay = const Duration(milliseconds: 500),
        maxDelay = const Duration(seconds: 15),
        backoffMultiplier = 1.5;

  /// Conservative retry for non-critical operations
  const RetryConfig.conservative()
      : maxAttempts = 2,
        initialDelay = const Duration(seconds: 2),
        maxDelay = const Duration(seconds: 60),
        backoffMultiplier = 3.0;
}

/// Retry utility with exponential backoff
class RetryUtil {
  /// Retry an async operation with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (error, stackTrace) {
        // Check if we should retry
        final shouldRetryError = shouldRetry?.call(error) ?? _defaultShouldRetry(error);
        
        if (!shouldRetryError || attempt >= config.maxAttempts) {
          ErrorHandler.warning(
            'Operation failed after $attempt attempts',
            {'error': error.toString()},
          );
          rethrow;
        }

        // Log retry attempt
        ErrorHandler.debug(
          'Retry attempt $attempt/${config.maxAttempts}',
          {'error': error.toString(), 'delay': delay.inMilliseconds},
        );

        // Call retry callback
        onRetry?.call(attempt, error);

        // Wait before retrying
        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: min(
            (delay.inMilliseconds * config.backoffMultiplier).round(),
            config.maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// Default retry logic - retry on network and temporary errors
  static bool _defaultShouldRetry(dynamic error) {
    // Never retry auth errors (they won't heal by retrying).
    if (error is AppException) {
      final code = (error.code ?? '').toUpperCase();
      if (code == 'NOT_AUTHENTICATED' ||
          code == 'SESSION_EXPIRED' ||
          code == 'INVALID_JWT' ||
          code == 'PERMISSION_DENIED') {
        return false;
      }
    }

    final errorString = error.toString().toLowerCase();

    // Don't retry validation or business logic errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid jwt') ||
        errorString.contains('not authenticated') ||
        errorString.contains('session expired') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return false;
    }

    // Retry network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('failed')) {
      return true;
    }

    // Retry server errors (5xx)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }

    // Don't retry by default
    return false;
  }

  /// Retry with jitter to prevent thundering herd
  static Future<T> retryWithJitter<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    return retry(
      operation,
      config: config,
      shouldRetry: shouldRetry,
      onRetry: (attempt, error) {
        onRetry?.call(attempt, error);
        
        // Add jitter to prevent simultaneous retries
        final jitter = Random().nextInt(500);
        Future.delayed(Duration(milliseconds: jitter));
      },
    );
  }

  /// Retry with circuit breaker pattern
  static Future<T> retryWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    required String circuitKey,
    RetryConfig config = const RetryConfig(),
    Duration circuitResetTimeout = const Duration(minutes: 1),
  }) async {
    // Check if circuit is open
    if (_isCircuitOpen(circuitKey)) {
      throw Exception('Circuit breaker is open for $circuitKey');
    }

    try {
      final result = await retry(operation, config: config);
      _recordSuccess(circuitKey);
      return result;
    } catch (error) {
      _recordFailure(circuitKey);
      
      // Open circuit if too many failures
      if (_shouldOpenCircuit(circuitKey)) {
        _openCircuit(circuitKey, circuitResetTimeout);
      }
      
      rethrow;
    }
  }

  // Circuit breaker state
  static final Map<String, _CircuitBreakerState> _circuits = {};

  static bool _isCircuitOpen(String key) {
    final state = _circuits[key];
    if (state == null) return false;
    
    if (state.isOpen && DateTime.now().isAfter(state.resetTime)) {
      _circuits.remove(key);
      return false;
    }
    
    return state.isOpen;
  }

  static void _recordSuccess(String key) {
    _circuits.remove(key);
  }

  static void _recordFailure(String key) {
    final state = _circuits[key] ?? _CircuitBreakerState();
    state.failureCount++;
    _circuits[key] = state;
  }

  static bool _shouldOpenCircuit(String key) {
    final state = _circuits[key];
    return state != null && state.failureCount >= 5;
  }

  static void _openCircuit(String key, Duration resetTimeout) {
    final state = _circuits[key] ?? _CircuitBreakerState();
    state.isOpen = true;
    state.resetTime = DateTime.now().add(resetTimeout);
    _circuits[key] = state;
    
    ErrorHandler.warning('Circuit breaker opened for $key');
  }
}

class _CircuitBreakerState {
  bool isOpen = false;
  int failureCount = 0;
  DateTime resetTime = DateTime.now();
}
