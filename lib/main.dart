import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env_config.dart';
import 'core/errors/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/main_shell_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  // Catch uncaught platform/FFI errors (e.g. objective_c framework on iOS 26
  // simulators) so they don't crash the app.
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('objective_c') || msg.contains('DOBJC_')) {
      // Known simulator issue – swallow silently.
      ErrorHandler.warning('Suppressed platform error (objective_c)', {
        'error': msg,
      });
      return true; // Handled – don't propagate.
    }
    // Let other errors through to the default handler.
    return false;
  };

  // Initialize environment configuration
  await _initializeApp();

  // Initialize Sentry for crash reporting in production
  final sentryDsn = EnvConfig.sentryDsn;
  if (sentryDsn.isNotEmpty && EnvConfig.enableCrashReporting) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = EnvConfig.appEnv;
        options.tracesSampleRate = 0.2;
        options.sendDefaultPii = false;
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: TradesmanLedgerApp(),
        ),
      ),
    );
  } else {
    runApp(
      const ProviderScope(
        child: TradesmanLedgerApp(),
      ),
    );
  }
}

Future<void> _initializeApp() async {
  try {
    // Load environment variables
    await EnvConfig.initialize(
      environment:
          const String.fromEnvironment('ENV', defaultValue: 'development'),
    );

    ErrorHandler.info('Initializing Tradesman Ledger', {
      'environment': EnvConfig.appEnv,
      'version': EnvConfig.appVersion,
    });

    // Initialize Supabase with secure configuration
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      debug: EnvConfig.isDebug,
    );

    ErrorHandler.info('Supabase initialized successfully');
    final auth = Supabase.instance.client.auth;
    if (auth.currentUser != null) {
      ErrorHandler.info(
          'Existing session found', {'userId': auth.currentUser?.id});
    }

    // Note: Drift database is initialized lazily via provider
    // Sync service will start automatically when first accessed
  } catch (error, stackTrace) {
    ErrorHandler.handle(error, stackTrace);
    rethrow;
  }
}

class TradesmanLedgerApp extends ConsumerWidget {
  const TradesmanLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const _AppEntryGate(),
    );
  }
}

class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _supabase.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }

        final userId = session.user.id;
        return FutureBuilder<bool>(
          future: OnboardingHelper.isCompleteForUser(userId),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final onboardingDone = onboardingSnapshot.data ?? false;
            if (!onboardingDone) {
              return _OnboardingWrapper(
                userId: userId,
                onFinished: () => setState(() {}),
              );
            }

            return const MainShellScreen();
          },
        );
      },
    );
  }
}

class _OnboardingWrapper extends StatelessWidget {
  final String userId;
  final VoidCallback onFinished;

  const _OnboardingWrapper({
    required this.userId,
    required this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onComplete: () async {
        await OnboardingHelper.markCompleteForUser(userId);
        onFinished();
      },
    );
  }
}
