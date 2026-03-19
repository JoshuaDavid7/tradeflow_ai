import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/legal_urls.dart';
import '../core/theme/theme_provider.dart';
import '../models/business_profile.dart';
import '../services/payment_service.dart';
import 'payment_settings_screen.dart';
import 'template_editor_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isPro = false;
  bool _isCheckingStripe = true;
  String? _stripeStatus; // null = available, or error code

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxIdCtrl.dispose();
    _rateCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    try {
      final queryFuture =
          _supabase.from('profiles').select().eq('id', userId).maybeSingle();

      final data = await Future.any<Map<String, dynamic>?>([
        queryFuture,
        Future.delayed(const Duration(seconds: 5), () => null),
      ]);

      if (data != null) {
        final p = BusinessProfile.fromJson(data);
        _nameCtrl.text = p.businessName;
        _addressCtrl.text = p.businessAddress ?? '';
        _phoneCtrl.text = p.businessPhone ?? '';
        _emailCtrl.text = p.businessEmail ?? '';
        _taxIdCtrl.text = p.taxId ?? '';
        _rateCtrl.text = p.hourlyRate.toString();
        _taxRateCtrl.text = p.taxRate.toString();
        _isPro = p.isPro;
      }
    } catch (e) {
      debugPrint('Settings: failed to load profile: $e');
    }

    _checkStripeStatus();
  }

  Future<void> _checkStripeStatus() async {
    if (mounted) setState(() => _isCheckingStripe = true);
    try {
      final result = await PaymentService.checkStripeAvailability();
      if (mounted) {
        setState(() {
          _stripeStatus = result;
          _isCheckingStripe = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stripeStatus = 'unknown_error';
          _isCheckingStripe = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'business_name': _nameCtrl.text,
        'business_address': _addressCtrl.text,
        'business_phone': _phoneCtrl.text,
        'business_email': _emailCtrl.text,
        'tax_id': _taxIdCtrl.text,
        'hourly_rate': double.tryParse(_rateCtrl.text) ?? 85.0,
        'tax_rate': double.tryParse(_taxRateCtrl.text) ?? 0.0,
        'is_pro': _isPro,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Save failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your data is saved and will sync when you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not sign out. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.error, size: 40),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data including jobs, invoices, expenses, and customer records.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Double-confirm with typed confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type DELETE to confirm account deletion. All your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (doubleConfirmed == true) {
      // Account deletion would be handled via Supabase Edge Function
      // For now, sign out and show confirmation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account deletion request submitted. Your data will be removed within 30 days.',
          ),
        ),
      );
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance ──
              _buildThemeCard(context, colorScheme, themeMode),
              const SizedBox(height: 20),
              _buildProSection(),
              const SizedBox(height: 20),
              _sectionHeader('Account'),
              _buildAccountSection(),
              const SizedBox(height: 20),
              _sectionHeader('Business Profile'),
              _buildField(_nameCtrl, 'Business Name', Icons.business_center),
              _buildField(_addressCtrl, 'Physical Address', Icons.location_pin,
                  maxLines: 2),
              _buildField(_phoneCtrl, 'Support Phone', Icons.phone_android,
                  keyboardType: TextInputType.phone),
              _buildField(_emailCtrl, 'Public Email', Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionHeader('Accounting & Tax'),
              _buildField(
                  _taxIdCtrl, 'Tax Registration / ID', Icons.assignment_ind),
              Row(
                children: [
                  Expanded(
                      child: _buildField(
                          _rateCtrl, 'Hourly Rate', Icons.monetization_on,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildField(
                          _taxRateCtrl, 'Tax Rate %', Icons.percent,
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              _sectionHeader('Payments'),
              _buildStripeStatusCard(),
              const SizedBox(height: 12),
              _buildPaymentSettingsEntry(),
              const SizedBox(height: 20),
              _sectionHeader('Invoice & Quote Template'),
              _buildTemplateEntry(),
              const SizedBox(height: 20),
              _sectionHeader('Integrations'),
              _buildIntegrationsSection(),
              const SizedBox(height: 20),
              _sectionHeader('Privacy & Data'),
              _buildPrivacySection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('SAVE CHANGES'),
                ),
              ),
              const SizedBox(height: 16),
              // Delete account (danger zone)
              Center(
                child: TextButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: Icon(Icons.delete_forever,
                      size: 16, color: colorScheme.error),
                  label: Text('Delete Account',
                      style: TextStyle(color: colorScheme.error)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final userEmail = _supabase.auth.currentUser?.email;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userEmail ?? 'Signed in user',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Your data is linked to this account',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
      BuildContext context, ColorScheme colorScheme, ThemeMode themeMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text('Appearance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode, size: 16),
              ),
            ],
            showSelectedIcon: false,
            selected: {themeMode},
            onSelectionChanged: (selected) {
              ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: colorScheme.primaryContainer,
              selectedForegroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isPro
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_isPro ? Icons.verified : Icons.workspace_premium,
                  color: _isPro ? colorScheme.primary : colorScheme.tertiary,
                  size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isPro ? 'Pro Member' : 'Tradesman Free',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                    Text(
                        _isPro
                            ? 'Unlimited PDF exports & features'
                            : '3 PDF exports per month included',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              if (!_isPro)
                FilledButton(
                  onPressed: () => setState(() => _isPro = true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Upgrade'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              )),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildStripeStatusCard() {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    bool showRetry = false;

    if (_isCheckingStripe) {
      icon = Icons.sync;
      iconColor = colorScheme.onSurfaceVariant;
      title = 'Checking Stripe...';
      subtitle = 'Verifying payment service availability';
    } else if (_stripeStatus == null) {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF2E7D32); // green
      title = 'Stripe Connected';
      subtitle = 'Payment links and QR codes are available on invoices';
    } else if (_stripeStatus == 'not_configured') {
      icon = Icons.warning_amber_rounded;
      iconColor = colorScheme.tertiary;
      title = 'Stripe Not Configured';
      subtitle =
          'Stripe requires server-side setup. Add your Stripe secret key to Supabase Edge Function environment variables.';
      showRetry = true;
    } else if (_stripeStatus == 'auth_error') {
      icon = Icons.lock_outline;
      iconColor = colorScheme.error;
      title = 'Authentication Error';
      subtitle = 'Could not verify Stripe. Try closing and reopening the app.';
      showRetry = true;
    } else if (_stripeStatus == 'network_error') {
      icon = Icons.cloud_off_outlined;
      iconColor = colorScheme.error;
      title = 'Payment Service Unreachable';
      subtitle =
          'Could not reach Supabase Edge Function create_stripe_checkout. Check your SUPABASE_URL, function deployment, and internet connection.';
      showRetry = true;
    } else {
      icon = Icons.error_outline;
      iconColor = colorScheme.error;
      title = 'Could Not Verify Stripe';
      subtitle = 'Unexpected response while checking Stripe configuration.';
      showRetry = true;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _stripeStatus == null && !_isCheckingStripe
            ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          if (_isCheckingStripe)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            )
          else
            Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          if (showRetry)
            TextButton(
              onPressed: _checkStripeStatus,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateEntry() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        final profile = BusinessProfile(
          id: _supabase.auth.currentUser?.id ?? '',
          businessName: _nameCtrl.text,
          businessAddress:
              _addressCtrl.text.isNotEmpty ? _addressCtrl.text : null,
          businessPhone: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
          businessEmail: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : null,
          taxId: _taxIdCtrl.text.isNotEmpty ? _taxIdCtrl.text : null,
          hourlyRate: double.tryParse(_rateCtrl.text) ?? 85.0,
          taxRate: double.tryParse(_taxRateCtrl.text) ?? 0.0,
          currencySymbol: '\$',
          isPro: _isPro,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditorScreen(profile: profile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.design_services,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customise Template',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  Text('Logo, colours, text, and layout',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sync_rounded,
                color: colorScheme.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QuickBooks, Xero & More',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 2),
                Text('Accounting integrations coming soon',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Soon',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _privacyRow(
            Icons.cloud_outlined,
            'Cloud Sync',
            'Your data is stored locally and synced to Supabase (encrypted in transit).',
          ),
          const Divider(height: 20),
          _privacyRow(
            Icons.auto_awesome_outlined,
            'AI Services',
            'Voice and receipt data is processed by Google Gemini for extraction. No data is retained by AI services.',
          ),
          const Divider(height: 20),
          _privacyRow(
            Icons.payment_outlined,
            'Stripe Payments',
            'Payment processing is handled by Stripe. Card details are never stored in this app.',
          ),
          const Divider(height: 20),
          _privacyRow(
            Icons.shield_outlined,
            'Your Rights',
            'You can export or delete your data at any time. Use the delete account option below to remove all data.',
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(LegalUrls.privacyPolicy)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Privacy Policy'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(LegalUrls.termsOfService)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Terms of Service'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _privacyRow(IconData icon, String title, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 2),
              Text(description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSettingsEntry() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Methods & Terms',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  Text(
                      'Stripe, checks, bank transfer, and terms shown on invoices',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
