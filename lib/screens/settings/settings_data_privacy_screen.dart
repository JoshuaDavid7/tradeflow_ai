import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/legal_urls.dart';
import '../../data/local/database.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/demo_data_service.dart';
import '../../presentation/providers/profile_provider.dart';

/// Data & Privacy detail screen — exports, privacy info, legal links.
class SettingsDataPrivacyScreen extends ConsumerStatefulWidget {
  const SettingsDataPrivacyScreen({super.key});

  @override
  ConsumerState<SettingsDataPrivacyScreen> createState() =>
      _SettingsDataPrivacyScreenState();
}

class _SettingsDataPrivacyScreenState
    extends ConsumerState<SettingsDataPrivacyScreen> {
  final _supabase = Supabase.instance.client;
  String? _exportingKey;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> _export(String key) async {
    if (_userId == null || _exportingKey != null) return;
    setState(() => _exportingKey = key);
    try {
      switch (key) {
        case 'jobs':
          await CsvExportService.exportJobs(_userId!);
        case 'expenses':
          await CsvExportService.exportExpenses(_userId!);
        case 'clients':
          await CsvExportService.exportClients(_userId!);
        case 'payments':
          final db = ref.read(databaseProvider);
          await CsvExportService.exportPayments(_userId!, db);
      }
    } catch (e) {
      debugPrint('Export $key failed: $e');
      if (mounted) {
        final isOffline = e.toString().contains('SocketException') ||
            e.toString().contains('network');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline
                ? 'Export failed — check your internet connection.'
                : 'Export failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Privacy')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Export Data ──
          _sectionLabel('EXPORT DATA', textTheme, colorScheme),
          const SizedBox(height: 12),
          Container(
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
              children: [
                _exportRow('jobs', Icons.download_outlined, 'Export Jobs',
                    'Download all invoices and quotes as CSV', colorScheme),
                const Divider(height: 20),
                _exportRow('expenses', Icons.download_outlined,
                    'Export Expenses', 'Download all expenses as CSV', colorScheme),
                const Divider(height: 20),
                _exportRow('clients', Icons.download_outlined,
                    'Export Clients', 'Download all client records as CSV', colorScheme),
                const Divider(height: 20),
                _exportRow('payments', Icons.download_outlined,
                    'Export Payments', 'Download payment history as CSV', colorScheme),
                // Demo data clear
                FutureBuilder<bool>(
                  future: _userId != null
                      ? DemoDataService.isDemoLoaded(_userId!)
                      : Future.value(false),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const Divider(height: 20),
                        _actionRow(
                          Icons.cleaning_services_outlined,
                          'Clear Sample Data',
                          'Remove all demo jobs, clients, and expenses',
                          colorScheme,
                          color: colorScheme.error,
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Clear Sample Data?'),
                                content: const Text(
                                  'This will remove all demo jobs, clients, and expenses. Your real data will not be affected.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || _userId == null) return;
                            try {
                              await DemoDataService.clear(_userId!);
                              ref.invalidate(profileProvider);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Sample data cleared')),
                                );
                                setState(() {});
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not clear sample data')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Privacy ──
          _sectionLabel('PRIVACY', textTheme, colorScheme),
          const SizedBox(height: 12),
          Container(
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
                _privacyRow(Icons.cloud_outlined, 'Cloud Sync',
                    'Your data is stored locally and synced to Supabase (encrypted in transit).', colorScheme),
                const Divider(height: 20),
                _privacyRow(Icons.auto_awesome_outlined, 'AI Services',
                    'Voice and receipt data is processed by Google Gemini for extraction. No data is retained by AI services.', colorScheme),
                const Divider(height: 20),
                _privacyRow(Icons.payment_outlined, 'Stripe Payments',
                    'Payment processing is handled by Stripe. Card details are never stored in this app.', colorScheme),
                const Divider(height: 20),
                _privacyRow(Icons.shield_outlined, 'Your Rights',
                    'You can export or delete your data at any time. Use the delete account option in Account settings.', colorScheme),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(LegalUrls.privacyPolicy)),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Privacy Policy'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(LegalUrls.termsOfService)),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Terms of Service'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(
      String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(text,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.primary,
          letterSpacing: 1.2,
        ));
  }

  Widget _exportRow(String key, IconData icon, String title, String subtitle,
      ColorScheme colorScheme) {
    final isExporting = _exportingKey == key;
    return _actionRow(
      isExporting ? Icons.hourglass_top : icon,
      isExporting ? 'Exporting…' : title,
      subtitle,
      colorScheme,
      onTap: isExporting ? null : () => _export(key),
    );
  }

  Widget _actionRow(IconData icon, String title, String subtitle,
      ColorScheme colorScheme,
      {VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        )),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right,
                size: 20, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _privacyRow(
      IconData icon, String title, String description, ColorScheme colorScheme) {
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
}
