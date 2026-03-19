import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
/// Provides type-safe access to environment variables
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// The environment selected at app startup ("development" or "production").
  /// Kept for clearer error messages (so we don't depend on other env keys).
  static String _selectedEnvironment = 'development';

  /// Initialize environment configuration
  /// Call this before runApp() in main.dart
  static Future<void> initialize({required String environment}) async {
    _selectedEnvironment = environment;
    final envFile =
        environment == 'production' ? '.env.production' : '.env.development';

    await dotenv.load(fileName: envFile);
  }

  // Supabase Configuration
  static String get supabaseUrl => _getOrThrow('SUPABASE_URL');
  static String get supabaseAnonKey => _getOrThrow('SUPABASE_ANON_KEY');

  // AI Service Keys (for Edge Functions - not exposed to client)
  static String get deepgramApiKey => _getOptional('DEEPGRAM_API_KEY') ?? '';
  static String get geminiApiKey => _getOptional('GOOGLE_GEMINI_KEY') ?? '';

  // App Configuration
  static String get appEnv => _getOrThrow('APP_ENV');
  static String get appName => _getOrThrow('APP_NAME');
  static String get appVersion => _getOrThrow('APP_VERSION');
  static String get authRedirectUrl =>
      _getOptional('AUTH_REDIRECT_URL') ?? 'tradesmanledger://login-callback/';

  // Sentry
  static String get sentryDsn => _getOptional('SENTRY_DSN') ?? '';

  // Feature Flags
  static bool get enableAnalytics => _getBool('ENABLE_ANALYTICS');
  static bool get enableCrashReporting => _getBool('ENABLE_CRASH_REPORTING');
  static bool get enableProFeatures => _getBool('ENABLE_PRO_FEATURES');

  // Helper Methods
  static String _getOrThrow(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception(
        'Missing required environment variable: $key\n'
        'Please check your .env.$_selectedEnvironment file',
      );
    }
    return value;
  }

  static String? _getOptional(String key) => dotenv.env[key];

  static bool _getBool(String key) {
    final value = dotenv.env[key];
    return value?.toLowerCase() == 'true';
  }

  // Environment Checks
  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
  static bool get isDebug => !isProduction;
}
