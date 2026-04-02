import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../providers/customer_ledger_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/shimmer_loading.dart';
import '../../../data/services/supabase_service.dart';
import 'customer_detail_screen.dart';

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  ConsumerState<CustomerLedgerScreen> createState() =>
      _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerLedgerListProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const ValueKey('search_clients_field'),
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // Customer list
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = _searchQuery.isEmpty
                    ? customers
                    : customers.where((c) {
                        final name =
                            (c['name'] ?? '').toString().toLowerCase();
                        final email =
                            (c['email'] ?? '').toString().toLowerCase();
                        final phone =
                            (c['phone'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) ||
                            email.contains(_searchQuery) ||
                            phone.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  final cs = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 56, color: cs.outlineVariant),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No clients yet'
                              : 'No clients match your search',
                          style: AppTextStyles.emptyTitle(textTheme, cs),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Add your first client to start tracking jobs',
                            style: AppTextStyles.emptyBody(textTheme, cs),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _showAddCustomerDialog(context),
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Add Client'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(customerLedgerListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      return _buildCustomerCard(context, customer, currencySymbol);
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  ShimmerLoadingListItem(),
                  ShimmerLoadingListItem(),
                  ShimmerLoadingListItem(),
                ]),
              ),
              error: (_, __) {
                final cs = Theme.of(context).colorScheme;
                final textTheme = Theme.of(context).textTheme;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: cs.error.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('Could not load clients',
                          style: AppTextStyles.emptyTitle(textTheme, cs)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(customerLedgerListProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildCustomerCard(
      BuildContext context, Map<String, dynamic> customer, String currencySymbol) {
    final name = customer['name'] ?? 'Unknown';
    final email = customer['email'] ?? '';
    final phone = customer['phone'] ?? '';
    final totalBilled = (customer['total_billed'] as num?)?.toDouble() ?? 0.0;
    final balance = (customer['balance'] as num?)?.toDouble() ?? 0.0;
    final jobCount = (customer['job_count'] as num?)?.toInt() ?? 0;
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.cardTitle(textTheme)),
                    if (phone.isNotEmpty || email.isNotEmpty)
                      Text(
                        phone.isNotEmpty ? formatPhoneNumber(phone) : email,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.cardSubtitle(textTheme, cs),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChip('$jobCount ${jobCount == 1 ? 'job' : 'jobs'}', cs.primary),
                        if (totalBilled > 0)
                          _buildChip(
                              '$currencySymbol${totalBilled.toStringAsFixed(0)} billed',
                              AppColors.paid(context)),
                        if (balance > 0)
                          _buildChip(
                              '$currencySymbol${balance.toStringAsFixed(0)} due',
                              AppColors.sent(context)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.chipLabel(color)),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String? nameError;
    String? emailError;
    bool duplicateWarningShown = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Client'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Client Name *',
                    prefixIcon: const Icon(Icons.person),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null || duplicateWarningShown) {
                      setDialogState(() {
                        nameError = null;
                        duplicateWarningShown = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    errorText: emailError,
                  ),
                  onChanged: (_) {
                    if (emailError != null) {
                      setDialogState(() => emailError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate name
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => nameError = 'Client name is required');
                  return;
                }
                if (name.length < 2) {
                  setDialogState(() => nameError = 'Name must be at least 2 characters');
                  return;
                }

                // Validate email if provided
                final email = emailCtrl.text.trim();
                if (email.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  setDialogState(() => emailError = 'Enter a valid email address');
                  return;
                }

                // Check for duplicate name (soft warning, allow on second tap)
                if (!duplicateWarningShown) {
                  final existing = ref.read(customerLedgerListProvider).valueOrNull ?? [];
                  final duplicate = existing.any((c) =>
                      (c['name']?.toString() ?? '').trim().toLowerCase() ==
                      name.toLowerCase());
                  if (duplicate) {
                    setDialogState(() {
                      nameError = 'A client named "$name" already exists. Tap Add again to proceed.';
                      duplicateWarningShown = true;
                    });
                    return;
                  }
                }

                final supabase = ref.read(supabaseServiceProvider);
                final userId = ref.read(userIdProvider);
                if (userId == null) return;

                final now = DateTime.now().toIso8601String();
                final payload = <String, dynamic>{
                  'id': const Uuid().v4(),
                  'user_id': userId,
                  'name': name,
                  'phone': phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  'email': email.isEmpty ? null : email,
                  'address': addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                  'total_billed': 0,
                  'total_paid': 0,
                  'balance': 0,
                  'job_count': 0,
                  'updated_at': now,
                };

                try {
                  await supabase.ensureValidSession();
                  try {
                    await supabase.client.from('customers').insert(payload);
                  } catch (e) {
                    debugPrint('Customer insert with all columns failed, retrying: $e');
                    // Fallback: if new columns don't exist yet, try without them
                    payload.remove('total_billed');
                    payload.remove('total_paid');
                    payload.remove('balance');
                    payload.remove('job_count');
                    payload.remove('updated_at');
                    await supabase.client.from('customers').insert(payload);
                  }
                  ref.invalidate(customerLedgerListProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: const Text('Could not add client. Please try again.'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add Client'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      addressCtrl.dispose();
    });
  }
}
