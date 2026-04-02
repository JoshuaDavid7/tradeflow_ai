import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/theme_provider.dart';
import '../models/business_profile.dart';
import '../services/payment_service.dart';
import 'payment_settings_screen.dart';
import 'template_editor_screen.dart';
import 'settings/settings_account_screen.dart';
import 'settings/settings_business_profile_screen.dart';
import 'settings/settings_pricing_tax_screen.dart';
import 'settings/settings_documents_screen.dart';
import 'settings/settings_data_privacy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isPro = false;
  bool _isCheckingStripe = true;
  String? _stripeStatus;

  // Cached profile for subtitles
  BusinessProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        final p = BusinessProfile.fromJson(data);
        setState(() {
          _profile = p;
          _isPro = p.isPro;
        });
      }
    } catch (e) {
      debugPrint('Settings hub: failed to load profile: $e');
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

  // Reload profile when returning from a detail screen
  Future<void> _pushAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final userEmail = _supabase.auth.currentUser?.email ?? '';
    final p = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ═══════ 1. Appearance (inline) ═══════
          _buildAppearanceCard(colorScheme, themeMode),

          const SizedBox(height: 16),

          // ═══════ 2. Plan ═══════
          _buildPlanCard(colorScheme),

          const SizedBox(height: 24),

          // ═══════ 3. Account ═══════
          _buildNavRow(
            icon: Icons.person_outline_rounded,
            title: 'Account',
            subtitle: userEmail.isNotEmpty
                ? 'Signed in as $userEmail'
                : 'Manage your account',
            colorScheme: colorScheme,
            onTap: () => _pushAndRefresh(const SettingsAccountScreen()),
          ),

          // ═══════ 4. Business Profile ═══════
          _buildNavRow(
            icon: Icons.business_center_outlined,
            title: 'Business Profile',
            subtitle: _businessProfileSubtitle(p),
            colorScheme: colorScheme,
            onTap: () =>
                _pushAndRefresh(const SettingsBusinessProfileScreen()),
          ),

          // ═══════ 5. Pricing & Tax ═══════
          _buildNavRow(
            icon: Icons.monetization_on_outlined,
            title: 'Pricing & Tax',
            subtitle: _pricingSubtitle(p),
            colorScheme: colorScheme,
            onTap: () => _pushAndRefresh(const SettingsPricingTaxScreen()),
          ),

          // ═══════ 6. Documents & Defaults ═══════
          _buildNavRow(
            icon: Icons.description_outlined,
            title: 'Documents & Defaults',
            subtitle: _documentsSubtitle(p),
            colorScheme: colorScheme,
            onTap: () => _pushAndRefresh(const SettingsDocumentsScreen()),
          ),

          // ═══════ 7. Payments ═══════
          _buildNavRow(
            icon: Icons.payments_outlined,
            title: 'Payments',
            subtitle: _paymentsSubtitle(),
            colorScheme: colorScheme,
            onTap: () => _pushAndRefresh(const PaymentSettingsScreen()),
          ),

          // ═══════ 8. Invoice & Quote Template ═══════
          _buildNavRow(
            icon: Icons.design_services_outlined,
            title: 'Invoice & Quote Template',
            subtitle: 'Logo, colours, text, and layout',
            colorScheme: colorScheme,
            onTap: () {
              final profile = p ??
                  BusinessProfile(
                    id: _supabase.auth.currentUser?.id ?? '',
                    businessName: '',
                    hourlyRate: 85.0,
                    taxRate: 0.0,
                    currencySymbol: '\$',
                  );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateEditorScreen(profile: profile),
                ),
              );
            },
          ),

          // ═══════ 9. Data & Privacy ═══════
          _buildNavRow(
            icon: Icons.shield_outlined,
            title: 'Data & Privacy',
            subtitle: 'Export data · Privacy controls',
            colorScheme: colorScheme,
            onTap: () =>
                _pushAndRefresh(const SettingsDataPrivacyScreen()),
          ),

          const SizedBox(height: 24),

          // ═══════ Version ═══════
          Center(
            child: Text(
              'TradeFlow v1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Appearance Card (inline) ────────────────────────────────────────

  Widget _buildAppearanceCard(ColorScheme colorScheme, ThemeMode themeMode) {
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
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selected.first);
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

  // ─── Plan Card ───────────────────────────────────────────────────────

  Widget _buildPlanCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Icon(
            _isPro ? Icons.verified : Icons.workspace_premium,
            color: _isPro ? colorScheme.primary : colorScheme.tertiary,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPro ? 'Pro Member' : 'Tradesman Free',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  _isPro
                      ? 'Unlimited PDF exports & features'
                      : '3 PDF exports per month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (!_isPro)
            FilledButton(
              onPressed: () => setState(() => _isPro = true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  // ─── Navigation Row ──────────────────────────────────────────────────

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Subtitle helpers ────────────────────────────────────────────────

  String _businessProfileSubtitle(BusinessProfile? p) {
    if (p == null) return 'Not set';
    final parts = <String>[];
    if (p.businessName.isNotEmpty && p.businessName != 'My Trade Business') {
      parts.add(p.businessName);
    }
    if (p.businessAddress != null && p.businessAddress!.isNotEmpty) {
      // Take just the city portion if multi-line
      final firstLine = p.businessAddress!.split('\n').first.trim();
      if (firstLine.length > 30) {
        parts.add('${firstLine.substring(0, 27)}…');
      } else {
        parts.add(firstLine);
      }
    }
    if (parts.isEmpty) return 'Not set';
    return parts.join(' · ');
  }

  String _pricingSubtitle(BusinessProfile? p) {
    if (p == null) return 'Not set';
    final parts = <String>[];
    parts.add('${p.currencySymbol}${p.hourlyRate.toStringAsFixed(p.hourlyRate == p.hourlyRate.roundToDouble() ? 0 : 2)}/hr');
    parts.add('${p.taxRate.toStringAsFixed(p.taxRate == p.taxRate.roundToDouble() ? 0 : 1)}% tax');
    return parts.join(' · ');
  }

  String _documentsSubtitle(BusinessProfile? p) {
    if (p == null) return 'Not set';
    final parts = <String>[];
    parts.add('${p.invoicePrefix} / ${p.quotePrefix}');
    parts.add(p.defaultDueDays == 0
        ? 'Due on receipt'
        : 'Net ${p.defaultDueDays}');
    if (p.defaultMarkupPercent > 0) {
      parts.add('${p.defaultMarkupPercent.toStringAsFixed(0)}% markup');
    }
    return parts.join(' · ');
  }

  String _paymentsSubtitle() {
    if (_isCheckingStripe) return 'Checking…';
    if (_stripeStatus == null) return 'Stripe connected';
    if (_stripeStatus == 'not_configured') return 'Stripe not configured';
    return 'Payment setup needed';
  }
}
