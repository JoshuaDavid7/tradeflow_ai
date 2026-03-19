import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  // Use ValueNotifiers to avoid full rebuilds on state changes
  final _isSignUp = ValueNotifier<bool>(false);
  final _isSubmitting = ValueNotifier<bool>(false);
  final _isSendingMagicLink = ValueNotifier<bool>(false);
  final _oauthProviderInProgress = ValueNotifier<OAuthProvider?>(null);
  final _obscurePassword = ValueNotifier<bool>(true);
  final _obscureConfirmPassword = ValueNotifier<bool>(true);

  // Rate limiting
  DateTime? _lastAuthAttempt;
  int _authAttemptCount = 0;
  static const _maxAttempts = 5;
  static const _cooldownSeconds = 30;

  bool get _isBusy =>
      _isSubmitting.value ||
      _isSendingMagicLink.value ||
      _oauthProviderInProgress.value != null;

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
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _isSignUp.dispose();
    _isSubmitting.dispose();
    _isSendingMagicLink.dispose();
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
          content: Text('Too many attempts. Please wait $remaining seconds.'),
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created and signed in')),
          );
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
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

  Future<void> _sendMagicLink() async {
    if (_isRateLimited()) return;
    final emailError = _validateEmail(_emailCtrl.text);
    if (emailError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    _isSendingMagicLink.value = true;
    final email = _emailCtrl.text.trim();

    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: _redirectTo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Magic link sent. Open it from your email to sign in.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send magic link. Try again.')),
      );
    } finally {
      if (mounted) _isSendingMagicLink.value = false;
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
                    _isSendingMagicLink,
                    _oauthProviderInProgress,
                  ]),
                  builder: (context, _) {
                    final isBusy = _isBusy;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                        // Email field — does not rebuild on password visibility changes
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

                        // Password field — isolated rebuild for visibility toggle
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

                        if (!_isSignUp.value) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isSendingMagicLink,
                              builder: (context, sending, _) {
                                return TextButton.icon(
                                  onPressed:
                                      isBusy ? null : _sendMagicLink,
                                  icon: sending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.mark_email_read_outlined,
                                          size: 18),
                                  label: const Text('Send Magic Link'),
                                );
                              },
                            ),
                          ),
                        ],

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
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
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

                        const SizedBox(height: 24),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
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

                        // Google OAuth
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
                                  text:
                                      'By signing in, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color: colorScheme.primary),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(Uri.parse(
                                      LegalUrls.termsOfService)),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: colorScheme.primary),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(Uri.parse(
                                      LegalUrls.privacyPolicy)),
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
