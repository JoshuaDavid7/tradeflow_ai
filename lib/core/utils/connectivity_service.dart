import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/error_handler.dart';

/// Connectivity status
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.instance.statusStream;
});

/// Connectivity service to monitor network status.
///
/// Uses a simple HTTP reachability check instead of `connectivity_plus` to
/// avoid the `objective_c.framework` crash on iOS 26 beta simulators (and
/// similar FFI issues). Periodically pings a reliable host and publishes
/// [ConnectivityStatus] updates.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _pollTimer;

  ConnectivityService._internal() {
    _initialize();
  }

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Returns `true` when online **or** when connectivity is unknown.
  bool get isOnline =>
      _currentStatus == ConnectivityStatus.online ||
      _currentStatus == ConnectivityStatus.unknown;

  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  // ---------------------------------------------------------------------------
  // Initialisation – pure Dart, no native plugins
  // ---------------------------------------------------------------------------

  void _initialize() {
    // Do an immediate check
    _checkReachability();

    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReachability();
    });
  }

  /// Try to reach a well-known host. On success → online; on failure → offline.
  Future<void> _checkReachability() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateConnectivityStatus(ConnectivityStatus.online);
      } else {
        _updateConnectivityStatus(ConnectivityStatus.offline);
      }
    } on SocketException catch (_) {
      _updateConnectivityStatus(ConnectivityStatus.offline);
    } on TimeoutException catch (_) {
      _updateConnectivityStatus(ConnectivityStatus.offline);
    } catch (_) {
      // Any other error – assume online to avoid blocking app functionality.
      _updateConnectivityStatus(ConnectivityStatus.online);
    }
  }

  // ---------------------------------------------------------------------------
  // Status management
  // ---------------------------------------------------------------------------

  void _updateConnectivityStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      ErrorHandler.info(
        'Connectivity status changed',
        {'status': status.name},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Public helpers
  // ---------------------------------------------------------------------------

  /// Execute operation only when online
  Future<T> executeWhenOnline<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOffline) {
      throw ConnectivityException(
          'No internet connection. Please check your network.');
    }
    return operation();
  }

  /// Wait for online status
  Future<void> waitForOnline({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription<ConnectivityStatus> subscription;

    final timer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Waiting for connection timed out'),
        );
      }
    });

    subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// Force an immediate connectivity re-check.
  Future<void> refresh() => _checkReachability();

  /// Dispose resources
  void dispose() {
    _pollTimer?.cancel();
    _statusController.close();
  }
}

/// Exception for connectivity issues
class ConnectivityException implements Exception {
  final String message;
  ConnectivityException(this.message);

  @override
  String toString() => message;
}
