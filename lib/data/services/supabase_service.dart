import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/config/env_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Provider for Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange;
});

/// Provider for current user ID
final userIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.currentUser?.id;
});

/// Supabase service wrapper with error handling
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Expose underlying client for lower-level operations (e.g., sync service).
  SupabaseClient get client => _client;

  /// Get current user ID or throw exception
  String get userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AuthException.notAuthenticated();
    }
    return id;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  Map<String, dynamic> _normalizeFunctionResponse(FunctionResponse response) {
    // Handle both string and map responses
    if (response.data is String) {
      return {'result': response.data};
    }
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'result': response.data};
  }

  bool _looksLikeJwt(String token) => token.split('.').length == 3;

  Map<String, dynamic>? _tryDecodeJwtSegment(String segment) {
    try {
      final normalized = base64Url.normalize(segment);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final dynamic json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _jwtDiagnostics(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return {};
    }

    final header = _tryDecodeJwtSegment(parts[0]);
    final payload = _tryDecodeJwtSegment(parts[1]);

    dynamic aud = payload?['aud'];
    if (aud is List) {
      aud = aud.join(',');
    }

    return {
      'jwtAlg': header?['alg'],
      'jwtKid': header?['kid'],
      'jwtIss': payload?['iss'],
      'jwtAud': aud,
      'jwtSub': payload?['sub'],
      'jwtRole': payload?['role'],
      'jwtExp': payload?['exp'],
      'jwtIat': payload?['iat'],
      'jwtIsAnonymous': payload?['is_anonymous'] ?? payload?['isAnonymous'],
    };
  }

  Map<String, dynamic> _sessionDiagnostics() {
    final session = _client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'hasUser': _client.auth.currentUser != null,
      'userId': _client.auth.currentUser?.id,
      'hasSession': session != null,
      'isExpired': session?.isExpired,
      'tokenPresent': token != null && token.isNotEmpty,
      'tokenSegments': token?.split('.').length,
      'tokenLength': token?.length,
      if (token != null && token.isNotEmpty) ..._jwtDiagnostics(token),
    };
  }

  /// Best-effort session validation/refresh.
  ///
  /// Edge Functions require a valid user JWT.
  Future<void> ensureValidSession() async {
    final auth = _client.auth;

    ErrorHandler.debug(
        'Supabase: ensureValidSession (before)', _sessionDiagnostics());

    final session = auth.currentSession;
    if (session == null) {
      throw AuthException.notAuthenticated();
    }

    var token = session.accessToken;
    if (token.isEmpty || !_looksLikeJwt(token)) {
      throw AuthException(
        message:
            'Supabase session exists, but no valid access token is available.\n'
            'Please sign in again.\n'
            'Diagnostics: ${_sessionDiagnostics()}',
        code: 'INVALID_JWT',
      );
    }

    // If we switched Supabase projects but the app cached an old session, the JWT
    // can fail verification in the new project. Detect this via `iss`.
    final expectedIssuer = '${EnvConfig.supabaseUrl}/auth/v1';
    final currentIssuer = _jwtDiagnostics(token)['jwtIss'];
    if (currentIssuer is String &&
        currentIssuer.isNotEmpty &&
        !currentIssuer.startsWith(expectedIssuer)) {
      ErrorHandler.warning('Supabase: JWT issuer mismatch (cached session?)', {
        'expectedIssuer': expectedIssuer,
        'currentIssuer': currentIssuer,
        ..._sessionDiagnostics(),
      });
      await auth.signOut();
      throw AuthException(
        message:
            'Your session is from a different project environment. Please sign in again.',
        code: 'SESSION_EXPIRED',
      );
    }

    if (!session.isExpired) {
      if (token.isNotEmpty) {
        _client.functions.setAuth(token);
      }
      ErrorHandler.debug(
          'Supabase: ensureValidSession (ok)', _sessionDiagnostics());
      return;
    }

    // Attempt refresh. If it fails, require user to re-authenticate.
    try {
      await auth.refreshSession();
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      await auth.signOut();
      throw AuthException(
        message: 'Your session expired. Please sign in again.',
        code: 'SESSION_EXPIRED',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    final refreshedSession = auth.currentSession;
    final refreshedToken = refreshedSession?.accessToken;
    if (refreshedSession == null ||
        refreshedToken == null ||
        refreshedToken.isEmpty ||
        !_looksLikeJwt(refreshedToken)) {
      await auth.signOut();
      throw AuthException(
        message: 'Your session expired. Please sign in again.',
        code: 'SESSION_EXPIRED',
      );
    }

    if (refreshedToken.isNotEmpty) {
      _client.functions.setAuth(refreshedToken);
    }
    ErrorHandler.debug(
        'Supabase: ensureValidSession (after refresh)', _sessionDiagnostics());
  }

  /// Query with error handling
  Future<List<Map<String, dynamic>>> query({
    required String table,
    required String userId,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    try {
      PostgrestTransformBuilder<List<Map<String, dynamic>>> queryBuilder =
          _client.from(table).select().eq('user_id', userId);

      if (orderBy != null) {
        queryBuilder = queryBuilder.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        queryBuilder = queryBuilder.limit(limit);
      }

      final data = await queryBuilder;
      ErrorHandler.debug('Query successful', {
        'table': table,
        'count': data.length,
      });

      return data;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to fetch data from $table',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Insert with error handling
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final result = await _client.from(table).insert(data).select().single();

      ErrorHandler.debug('Insert successful', {
        'table': table,
        'id': result['id'],
      });

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to save data to $table',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update with error handling
  Future<Map<String, dynamic>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final result =
          await _client.from(table).update(data).eq('id', id).select().single();

      ErrorHandler.debug('Update successful', {
        'table': table,
        'id': id,
      });

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to update data in $table',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete with error handling
  Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);

      ErrorHandler.debug('Delete successful', {
        'table': table,
        'id': id,
      });
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw DatabaseException(
        message: 'Failed to delete data from $table',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Upload file to storage with error handling
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      ErrorHandler.debug('File upload successful', {
        'bucket': bucket,
        'path': path,
      });

      return path;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw StorageException(
        message: 'Failed to upload file',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Download file from storage
  Future<dynamic> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final data = await _client.storage.from(bucket).download(path);

      ErrorHandler.debug('File download successful', {
        'bucket': bucket,
        'path': path,
      });

      return data;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw StorageException(
        message: 'Failed to download file',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required List<String> paths,
  }) async {
    try {
      await _client.storage.from(bucket).remove(paths);

      ErrorHandler.debug('File deletion successful', {
        'bucket': bucket,
        'paths': paths,
      });
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw StorageException(
        message: 'Failed to delete file',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Invoke edge function with error handling
  Future<Map<String, dynamic>> invokeFunction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    try {
      await ensureValidSession();

      final token = _client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty || !_looksLikeJwt(token)) {
        throw AuthException(
          message:
              'Cannot call Edge Function `$functionName` without a valid session token.\n'
              'Diagnostics: ${_sessionDiagnostics()}',
          code: 'INVALID_JWT',
        );
      }

      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.status != 200) {
        throw Exception(
            'Function returned status ${response.status}: ${response.data}');
      }

      ErrorHandler.debug('Function invocation successful', {
        'function': functionName,
      });

      // Handle both string and map responses
      return _normalizeFunctionResponse(response);
    } on FunctionException catch (error, stackTrace) {
      // Most common cause: Calling a JWT-verified function while signed out (or with a
      // stale token). Try a one-time refresh and retry once.
      if (error.status == 401) {
        ErrorHandler.warning('Edge Function rejected JWT (401)', {
          'function': functionName,
          'details': error.details,
          ..._sessionDiagnostics(),
        });

        try {
          await _client.auth.refreshSession();
          final token = _client.auth.currentSession?.accessToken;
          if (token != null && token.isNotEmpty && _looksLikeJwt(token)) {
            final retryResponse = await _client.functions.invoke(
              functionName,
              body: body,
              headers: {'Authorization': 'Bearer $token'},
            );
            if (retryResponse.status == 200) {
              return _normalizeFunctionResponse(retryResponse);
            }
          }
        } catch (refreshError, refreshStackTrace) {
          ErrorHandler.handle(refreshError, refreshStackTrace);
        }

        await _client.auth.signOut();
        throw AuthException(
          message: 'Authentication expired. Please sign in again.',
          code: 'SESSION_EXPIRED',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      ErrorHandler.handle(error, stackTrace);
      throw NetworkException(
        message: 'Failed to invoke function: $functionName',
        originalError: error,
        stackTrace: stackTrace,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      throw NetworkException(
        message: 'Failed to invoke function: $functionName',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Provider for Supabase service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SupabaseService(client);
});
