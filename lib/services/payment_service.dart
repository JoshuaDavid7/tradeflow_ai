import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exception.dart' as app_exceptions;
import '../data/services/supabase_service.dart';

class SecureCheckoutSession {
  final String provider;
  final String checkoutUrl;
  final String checkoutSessionId;
  final String currency;
  final int amountMinor;
  final String? expiresAtIso;
  final List<String> acceptedMethods;

  const SecureCheckoutSession({
    required this.provider,
    required this.checkoutUrl,
    required this.checkoutSessionId,
    required this.currency,
    required this.amountMinor,
    required this.acceptedMethods,
    this.expiresAtIso,
  });

  factory SecureCheckoutSession.fromMap(Map<String, dynamic> json) {
    final methodsRaw = json['acceptedMethods'] ?? json['accepted_methods'];
    final acceptedMethods = methodsRaw is List
        ? methodsRaw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];

    return SecureCheckoutSession(
      provider: (json['provider'] ?? 'stripe').toString(),
      checkoutUrl:
          (json['checkoutUrl'] ?? json['checkout_url'] ?? '').toString(),
      checkoutSessionId:
          (json['checkoutSessionId'] ?? json['checkout_session_id'] ?? '')
              .toString(),
      currency: (json['currency'] ?? 'usd').toString().toLowerCase(),
      amountMinor:
          ((json['amountMinor'] ?? json['amount_minor'] ?? 0) as num).round(),
      expiresAtIso: (json['expiresAt'] ?? json['expires_at'])?.toString(),
      acceptedMethods: acceptedMethods,
    );
  }
}

/// Server-backed secure payment link creation (Stripe hosted checkout).
class PaymentService {
  PaymentService._();

  static final _supabase = Supabase.instance.client;

  static const _zeroDecimalCurrencies = {
    'bif',
    'clp',
    'djf',
    'gnf',
    'jpy',
    'kmf',
    'krw',
    'mga',
    'pyg',
    'rwf',
    'ugx',
    'vnd',
    'vuv',
    'xaf',
    'xof',
    'xpf',
  };

  static Future<SecureCheckoutSession> createStripeCheckout({
    required double amount,
    required String currency,
    required String clientName,
    String? clientEmail,
    String? jobId,
    required String documentType,
    String? description,
  }) async {
    final normalizedCurrency = _normalizeCurrency(currency);
    final amountMinor = toMinorUnits(amount, normalizedCurrency);
    if (amountMinor <= 0) {
      throw Exception(
          'Amount must be greater than zero to create a payment link.');
    }

    final payload = {
      'jobId': jobId,
      'amountMinor': amountMinor,
      'currency': normalizedCurrency,
      'clientName': clientName.trim(),
      'clientEmail': (clientEmail ?? '').trim(),
      'documentType': documentType.trim().toLowerCase(),
      'description': (description ?? '').trim(),
    };

    final Map<String, dynamic> data;
    try {
      data = await SupabaseService(_supabase).invokeFunction(
        functionName: 'create_stripe_checkout',
        body: payload,
      );
    } on app_exceptions.AuthException catch (error) {
      if (error.code == 'INVALID_JWT' ||
          error.code == 'NOT_AUTHENTICATED' ||
          error.code == 'SESSION_EXPIRED') {
        throw Exception(
          'Authentication expired while creating the secure payment link. '
          'Please force close the app and reopen it, then try again.',
        );
      }
      rethrow;
    }

    final parsed = SecureCheckoutSession.fromMap(data);
    if (parsed.checkoutUrl.isEmpty || parsed.checkoutSessionId.isEmpty) {
      throw Exception(
          'Payment link service returned incomplete checkout data.');
    }
    return parsed;
  }

  static String currencyCodeFromSymbol(String symbol) {
    switch (symbol.trim()) {
      case '\$':
        return 'usd';
      case '£':
        return 'gbp';
      case '€':
        return 'eur';
      case '¥':
        return 'jpy';
      case 'A\$':
      case 'AU\$':
        return 'aud';
      case 'C\$':
      case 'CA\$':
        return 'cad';
      case 'NZ\$':
        return 'nzd';
      default:
        return 'usd';
    }
  }

  static int toMinorUnits(double amount, String currency) {
    final normalized = _normalizeCurrency(currency);
    if (_zeroDecimalCurrencies.contains(normalized)) {
      return amount.round();
    }
    return (amount * 100).round();
  }

  /// Probes the Stripe Edge Function to check if Stripe is configured.
  /// Returns `null` if Stripe is available, or an error code string if not:
  /// - `'not_configured'` — Stripe env vars missing on server
  /// - `'auth_error'` — JWT / authentication issue
  /// - `'network_error'` — could not reach the server
  /// - `'unknown_error'` — unexpected failure
  static Future<String?> checkStripeAvailability() async {
    final supabaseService = SupabaseService(_supabase);
    try {
      await supabaseService.ensureValidSession();
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) {
        return 'auth_error';
      }

      // Send amountMinor=0 which will trigger a 400 validation error
      // if env vars are present (proving Stripe IS configured), or
      // a 500 if env vars are missing.
      final response = await _supabase.functions.invoke(
        'create_stripe_checkout',
        body: {
          'amountMinor': 0,
          'currency': 'usd',
          'clientName': '_probe',
        },
        headers: {'Authorization': 'Bearer $token'},
      );
      final status = response.status;
      final payload = response.data.toString().toLowerCase();

      if (status == 200) return null;

      if (status == 401 ||
          status == 403 ||
          payload.contains('invalid jwt') ||
          payload.contains('missing bearer token')) {
        return 'auth_error';
      }

      // A 400 means the function loaded & validated — env vars exist
      if (status == 400 &&
          (payload.contains('amountminor must be') ||
              payload.contains('amount must be'))) {
        return null; // Stripe is configured
      }

      if (payload.contains('missing required environment') ||
          payload.contains('stripe_secret_key')) {
        return 'not_configured';
      }

      if (status == 404) return 'network_error';
      return 'unknown_error';
    } on app_exceptions.AuthException {
      return 'auth_error';
    } on app_exceptions.NetworkException {
      return 'network_error';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('missing required environment') ||
          msg.contains('stripe_secret_key')) {
        return 'not_configured';
      }
      if (msg.contains('invalid jwt') ||
          msg.contains('missing bearer token') ||
          msg.contains('not_authenticated')) {
        return 'auth_error';
      }
      if (msg.contains('amountminor must be') ||
          msg.contains('amount must be') ||
          msg.contains('status 400')) {
        return null;
      }
      if (msg.contains('socketexception') ||
          msg.contains('dns') ||
          msg.contains('timed out')) {
        return 'network_error';
      }
      return 'unknown_error';
    }
  }

  static String _normalizeCurrency(String value) {
    final clean = value.trim().toLowerCase();
    if (RegExp(r'^[a-z]{3}$').hasMatch(clean)) return clean;
    return 'usd';
  }
}
