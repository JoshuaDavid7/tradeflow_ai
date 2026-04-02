import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/business_profile.dart';
import '../../presentation/providers/profile_provider.dart';

/// Business Profile detail screen — name, address, phone, email.
class SettingsBusinessProfileScreen extends ConsumerStatefulWidget {
  const SettingsBusinessProfileScreen({super.key});

  @override
  ConsumerState<SettingsBusinessProfileScreen> createState() =>
      _SettingsBusinessProfileScreenState();
}

class _SettingsBusinessProfileScreenState
    extends ConsumerState<SettingsBusinessProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

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
    super.dispose();
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
      if (data != null) {
        final p = BusinessProfile.fromJson(data);
        _nameCtrl.text = p.businessName;
        _addressCtrl.text = p.businessAddress ?? '';
        _phoneCtrl.text = p.businessPhone ?? '';
        _emailCtrl.text = p.businessEmail ?? '';
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Business profile load failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'business_name': _nameCtrl.text.trim(),
        'business_address': _addressCtrl.text.trim(),
        'business_phone': _phoneCtrl.text.trim(),
        'business_email': _emailCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile saved')),
        );
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildField(
              controller: _nameCtrl,
              label: 'Business Name',
              icon: Icons.business_center,
              colorScheme: colorScheme,
            ),
            _buildField(
              controller: _addressCtrl,
              label: 'Physical Address',
              icon: Icons.location_pin,
              colorScheme: colorScheme,
              maxLines: 2,
            ),
            _buildField(
              controller: _phoneCtrl,
              label: 'Support Phone',
              icon: Icons.phone_android,
              colorScheme: colorScheme,
              keyboardType: TextInputType.phone,
            ),
            _buildField(
              controller: _emailCtrl,
              label: 'Public Email',
              icon: Icons.alternate_email,
              colorScheme: colorScheme,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
        ),
      ),
    );
  }
}
