import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/env_config.dart';
import '../core/config/legal_urls.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Secure credential storage
  static const _secureStorage = FlutterSecureStorage();
  static const _emailKey = 'tl_saved_email';
  static const _passwordKey = 'tl_saved_password';
  static const _rememberMeKey = 'tl_remember_me';
  static const _biometricEnabledKey = 'tl_biometric_enabled';

  final _localAuth = LocalAuthentication();

  // UI state
  final _isSignUp = ValueNotifier<bool>(false);
  final _isSubmitting = ValueNotifier<bool>(false);
  final _oauthProviderInProgress = ValueNotifier<OAuthProvider?>(null);
  final _obscurePassword = ValueNotifier<bool>(true);
  final _obscureConfirmPassword = ValueNotifier<bool>(true);

  bool _rememberMe = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasSavedCredentials = false;
  bool _initializing = true;

  // Rate limiting
  DateTime? _lastAuthAttempt;
  int _authAttemptCount = 0;
  static const _maxAttempts = 5;
  static const _cooldownSeconds = 30;

  bool get _isBusy =>
      _isSubmitting.value || _oauthProviderInProgress.value != null;

  String? get _redirectTo {
    final value = EnvConfig.authRedirectUrl.trim();
    return value.isEmpty ? null : value;
  }

  bool get _supportsAppleSignIn {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _initBiometricsAndCredentials();
  }

  Future<void> _initBiometricsAndCredentials() async {
    try {
      // Check biometric hardware
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _biometricAvailable = canAuth && isDeviceSupported;

      // Check saved preferences
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool(_rememberMeKey) ?? true;
      _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

      // Check if we have saved credentials
      final savedEmail = await _secureStorage.read(key: _emailKey);
      final savedPassword = await _secureStorage.read(key: _passwordKey);
      _hasSavedCredentials =
          savedEmail != null &&
          savedEmail.isNotEmpty &&
          savedPassword != null &&
          savedPassword.isNotEmpty;

      if (_hasSavedCredentials && _rememberMe) {
        _emailCtrl.text = savedEmail!;
      }

      if (mounted) setState(() => _initializing = false);

      // Auto-trigger biometric if enabled and has credentials
      if (_biometricEnabled && _hasSavedCredentials && _biometricAvailable) {
        await _signInWithBiometrics();
      }
    } catch (e) {
      debugPrint('Biometric init error: $e');
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _isSignUp.dispose();
    _isSubmitting.dispose();
    _oauthProviderInProgress.dispose();
    _obscurePassword.dispose();
    _obscureConfirmPassword.dispose();
    super.dispose();
  }

  bool _isRateLimited() {
    if (_lastAuthAttempt != null &&
        _authAttemptCount >= _maxAttempts &&
        DateTime.now().difference(_lastAuthAttempt!).inSeconds <
            _cooldownSeconds) {
      final remaining = _cooldownSeconds -
          DateTime.now().difference(_lastAuthAttempt!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Too many attempts. Please wait $remaining seconds.')),
      );
      return true;
    }
    if (_lastAuthAttempt != null &&
        DateTime.now().difference(_lastAuthAttempt!).inSeconds >=
            _cooldownSeconds) {
      _authAttemptCount = 0;
    }
    _authAttemptCount++;
    _lastAuthAttempt = DateTime.now();
    return false;
  }

  /// Save credentials securely after successful login.
  Future<void> _saveCredentials(String email, String password) async {
    if (_rememberMe) {
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordKey, value: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, true);
    }
  }

  /// Enable biometric auth after first successful login.
  Future<void> _promptBiometricEnrollment() async {
    if (!_biometricAvailable || _biometricEnabled || !_hasSavedCredentials) {
      return;
    }
    // Only prompt if we just saved credentials
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_biometricEnabledKey) == true) return;

    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Face ID / Biometrics?'),
        content: const Text(
          'Sign in faster next time using Face ID or fingerprint.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (enable == true) {
      await prefs.setBool(_biometricEnabledKey, true);
      _biometricEnabled = true;
    }
  }

  /// Sign in with biometrics (Face ID / fingerprint).
  Future<void> _signInWithBiometrics() async {
    if (!_biometricAvailable || !_hasSavedCredentials) return;

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Sign in to Tradesman Ledger',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) return;

      _isSubmitting.value = true;

      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (email == null || password == null) {
        _isSubmitting.value = false;
        return;
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (e) {
      debugPrint('Biometric sign-in error: $e');
    } finally {
      if (mounted) _isSubmitting.value = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRateLimited()) return;

    _isSubmitting.value = true;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      if (_isSignUp.value) {
        final result = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;
        if (result.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to verify, then sign in.',
              ),
            ),
          );
          _isSignUp.value = false;
        } else {
          await _saveCredentials(email, password);
          _hasSavedCredentials = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created and signed in')),
          );
          _promptBiometricEnrollment();
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        await _saveCredentials(email, password);
        _hasSavedCredentials = true;
        _promptBiometricEnrollment();
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication failed. Please try again.')),
      );
    } finally {
      if (mounted) _isSubmitting.value = false;
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    _oauthProviderInProgress.value = provider;
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectTo,
        scopes:
            provider == OAuthProvider.apple ? 'name email' : 'email profile',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('OAuth sign-in failed. Please try again.')),
      );
    } finally {
      if (mounted) _oauthProviderInProgress.value = null;
    }
  }

  String? _validateEmail(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isSignUp.value) return null;
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_initializing) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    _isSignUp,
                    _isSubmitting,
                    _oauthProviderInProgress,
                  ]),
                  builder: (context, _) {
                    final isBusy = _isBusy;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ──
                        Container(
                          width: 84,
                          height: 84,
                          margin: const EdgeInsets.only(bottom: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.lock_person_rounded,
                            color: colorScheme.primary,
                            size: 40,
                          ),
                        ),
                        Text(
                          _isSignUp.value
                              ? 'Create your account'
                              : 'Sign in to Tradesman Ledger',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp.value
                              ? 'Use your business email to create a secure account.'
                              : 'Sign in to access your jobs, invoices, and customers.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Email field ──
                        TextFormField(
                          key: const ValueKey('auth_email'),
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),

                        // ── Password field ──
                        ValueListenableBuilder<bool>(
                          valueListenable: _obscurePassword,
                          builder: (context, obscure, _) {
                            return TextFormField(
                              key: const ValueKey('auth_password'),
                              controller: _passwordCtrl,
                              obscureText: obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => _obscurePassword.value =
                                      !_obscurePassword.value,
                                  icon: Icon(obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                              validator: _validatePassword,
                            );
                          },
                        ),

                        // ── Confirm Password (sign-up only) ──
                        if (_isSignUp.value) ...[
                          const SizedBox(height: 14),
                          ValueListenableBuilder<bool>(
                            valueListenable: _obscureConfirmPassword,
                            builder: (context, obscure, _) {
                              return TextFormField(
                                controller: _confirmPasswordCtrl,
                                obscureText: obscure,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        _obscureConfirmPassword.value =
                                            !_obscureConfirmPassword.value,
                                    icon: Icon(obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                  ),
                                ),
                                validator: _validateConfirmPassword,
                              );
                            },
                          ),
                        ],

                        // ── Remember Me (sign-in only) ──
                        if (!_isSignUp.value) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) async {
                                    setState(() => _rememberMe = v ?? false);
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        _rememberMeKey, _rememberMe);
                                    if (!_rememberMe) {
                                      // Clear saved credentials
                                      await _secureStorage.delete(
                                          key: _emailKey);
                                      await _secureStorage.delete(
                                          key: _passwordKey);
                                      _hasSavedCredentials = false;
                                    }
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Sign In / Create Account button ──
                        ValueListenableBuilder<bool>(
                          valueListenable: _isSubmitting,
                          builder: (context, submitting, _) {
                            return FilledButton(
                              onPressed: isBusy ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: submitting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(_isSignUp.value
                                      ? 'Create Account'
                                      : 'Sign In'),
                            );
                          },
                        ),

                        // ── Biometric sign-in button ──
                        if (!_isSignUp.value &&
                            _biometricAvailable &&
                            _hasSavedCredentials &&
                            _biometricEnabled) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: isBusy ? null : _signInWithBiometrics,
                            icon: Icon(
                              defaultTargetPlatform == TargetPlatform.iOS
                                  ? Icons.face
                                  : Icons.fingerprint,
                              size: 20,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            label: Text(
                              defaultTargetPlatform == TargetPlatform.iOS
                                  ? 'Sign in with Face ID'
                                  : 'Sign in with Biometrics',
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: isBusy
                              ? null
                              : () {
                                  _isSignUp.value = !_isSignUp.value;
                                  _confirmPasswordCtrl.clear();
                                },
                          child: Text(_isSignUp.value
                              ? 'Already have an account? Sign in'
                              : 'Need an account? Create one'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Google OAuth ──
                        ValueListenableBuilder<OAuthProvider?>(
                          valueListenable: _oauthProviderInProgress,
                          builder: (context, activeProvider, _) {
                            final isLoading =
                                activeProvider == OAuthProvider.google;
                            return OutlinedButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () =>
                                      _signInWithOAuth(OAuthProvider.google),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : SvgPicture.asset(
                                      'assets/images/google_logo.svg',
                                      width: 20,
                                      height: 20,
                                    ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              label: const Text('Continue with Google'),
                            );
                          },
                        ),

                        // ── Apple OAuth ──
                        if (_supportsAppleSignIn) ...[
                          const SizedBox(height: 10),
                          ValueListenableBuilder<OAuthProvider?>(
                            valueListenable: _oauthProviderInProgress,
                            builder: (context, activeProvider, _) {
                              final isLoading =
                                  activeProvider == OAuthProvider.apple;
                              return OutlinedButton.icon(
                                onPressed: isBusy
                                    ? null
                                    : () => _signInWithOAuth(
                                        OAuthProvider.apple),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.apple, size: 22),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                label: const Text('Continue with Apple'),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'By signing in, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(color: colorScheme.primary),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(
                                      Uri.parse(LegalUrls.termsOfService)),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: colorScheme.primary),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(
                                      Uri.parse(LegalUrls.privacyPolicy)),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
