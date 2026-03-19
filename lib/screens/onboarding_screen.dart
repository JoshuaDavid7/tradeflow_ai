import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/legal_urls.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Business setup fields
  final _nameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '85');

  // Business address fields
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  // Company logo
  File? _logoFile;

  // Payment provider fields
  final _stripeIdCtrl = TextEditingController();
  final _paypalEmailCtrl = TextEditingController();
  final _venmoUsernameCtrl = TextEditingController();

  // Privacy consent
  bool _acceptedTerms = false;

  static const _totalPages = 8;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _stripeIdCtrl.dispose();
    _paypalEmailCtrl.dispose();
    _venmoUsernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _totalPages,
                    (i) => Container(
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildVoicePage(),
                  _buildFeaturesPage(),
                  _buildSetupPage(),
                  _buildAddressPage(),
                  _buildLogoPage(),
                  _buildPaymentProvidersPage(),
                  _buildPrivacyPage(),
                ],
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  // Show Skip button on the 3 new optional pages (indices 4, 5, 6)
                  if (_currentPage >= 4 && _currentPage <= 6)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Skip'),
                      ),
                    ),
                  FilledButton(
                    onPressed: _canProceed() ? _handleNext : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    // On the privacy page, require terms acceptance
    if (_currentPage == _totalPages - 1) return _acceptedTerms;
    return true;
  }

  Widget _buildWelcomePage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/siteinvoice_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to\nTradesman Ledger',
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The AI-powered invoicing and job management app built specifically for tradespeople.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.record_voice_over,
                size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text('Speak, Don\'t Type',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 16),
          Text(
            'Just talk naturally about the job \u2014 mention the client, materials, hours, and costs. Our AI extracts everything into a professional invoice or quote.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Example bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    size: 24),
                const SizedBox(height: 8),
                Text(
                  '\u201cInvoice David for 3 hours work, materials were two copper pipes at 25 each and a valve at 50 dollars\u201d',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    textStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Everything You Need',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 32),
          _featureItem(Icons.mic, 'Voice to Invoice',
              'Speak naturally, get professional invoices'),
          _featureItem(Icons.receipt_long, 'AI Receipt Scanner',
              'Snap a receipt \u2014 AI extracts every line item'),
          _featureItem(Icons.payment, 'Stripe Payments',
              'Add payment links and QR codes to invoices'),
          _featureItem(Icons.analytics, 'Analytics',
              'Charts for revenue, expenses, and profit'),
          _featureItem(Icons.people, 'Customer Ledger',
              'Full client history and job tracking'),
          _featureItem(Icons.design_services, 'Custom Templates',
              'Your logo, colours, and branding on PDFs'),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                Text(subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Text('Quick Setup',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(
              'You can always change these later in Settings.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                hintText: 'e.g., Smith Plumbing',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Default Hourly Rate',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── New optional page 1: Business Address ──

  Widget _buildAddressPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_outlined,
                  size: 36, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Business Address',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(
              'This will appear on your invoices (optional)',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _streetCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g., 123 Main Street',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g., Denver',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stateCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'State / Province',
                      hintText: 'e.g., CO',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _zipCtrl,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Zip / Postal Code',
                      hintText: 'e.g., 80202',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: 'e.g., United States',
                prefixIcon: Icon(Icons.public_outlined),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── New optional page 2: Company Logo ──

  Widget _buildLogoPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Text('Company Logo',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(
              'Add your logo to invoices and quotes (optional)',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _logoFile != null
                    ? Image.file(
                        _logoFile!,
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 56, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select logo',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_logoFile != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _logoFile = null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  // ── New optional page 3: Payment Providers ──

  Widget _buildPaymentProvidersPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_outlined,
                  size: 36, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Payment Setup',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(
              'Connect payment providers to get paid faster (optional)',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _stripeIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Stripe Account ID',
                hintText: 'e.g., acct_1A2B3C4D5E',
                helperText:
                    'Enter your Stripe account ID to accept card payments',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paypalEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'PayPal Email',
                hintText: 'e.g., payments@mybusiness.com',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _venmoUsernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Venmo Username',
                hintText: 'e.g., @my-business',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined,
                    size: 24, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Your Privacy Matters',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Here\u2019s how we handle your data:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data handling cards
            _privacyItem(
              Icons.phone_android,
              'Offline-First',
              'Your data is stored locally on your device first. It syncs securely to the cloud (Supabase) so you never lose anything.',
            ),
            _privacyItem(
              Icons.auto_awesome,
              'AI Processing',
              'Voice recordings and receipt photos are processed by Google\u2019s AI services to extract job details. Audio is transcribed on-device when possible.',
            ),
            _privacyItem(
              Icons.payment,
              'Payments',
              'Stripe handles all payment processing securely. We never see or store your clients\u2019 card details.',
            ),
            _privacyItem(
              Icons.delete_outline,
              'Your Control',
              'You can delete your account and all associated data at any time from Settings.',
            ),
            _privacyItem(
              Icons.lock_outline,
              'No Selling',
              'We never sell your data. Your business information is yours alone.',
            ),

            const SizedBox(height: 12),

            // Terms acceptance
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedTerms
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) =>
                            setState(() => _acceptedTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(color: colorScheme.primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrl(Uri.parse(LegalUrls.termsOfService)),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: colorScheme.primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrl(Uri.parse(LegalUrls.privacyPolicy)),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _privacyItem(IconData icon, String title, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Save business name + rate if provided
      await _saveSetup();
      widget.onComplete();
    }
  }

  Future<void> _saveSetup() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final name = _nameCtrl.text.trim();
      final rate = double.tryParse(_rateCtrl.text.trim()) ?? 85.0;

      // Build the profile payload
      final payload = <String, dynamic>{
        'id': userId,
        'hourly_rate': rate,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name.isNotEmpty) {
        payload['business_name'] = name;
      }

      // Business address — combine fields into a single string if any are filled
      final street = _streetCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final state = _stateCtrl.text.trim();
      final zip = _zipCtrl.text.trim();
      final country = _countryCtrl.text.trim();

      final addressParts = <String>[
        if (street.isNotEmpty) street,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty && zip.isNotEmpty) '$state $zip'
        else if (state.isNotEmpty) state
        else if (zip.isNotEmpty) zip,
        if (country.isNotEmpty) country,
      ];

      if (addressParts.isNotEmpty) {
        payload['business_address'] = addressParts.join(', ');
      }

      // Payment provider fields
      final stripeId = _stripeIdCtrl.text.trim();
      final paypalEmail = _paypalEmailCtrl.text.trim();
      final venmoUsername = _venmoUsernameCtrl.text.trim();

      if (stripeId.isNotEmpty) {
        payload['stripe_account_id'] = stripeId;
      }
      if (paypalEmail.isNotEmpty) {
        payload['paypal_email'] = paypalEmail;
      }
      if (venmoUsername.isNotEmpty) {
        payload['venmo_username'] = venmoUsername;
      }

      // Only upsert if there is meaningful data
      if (name.isNotEmpty ||
          addressParts.isNotEmpty ||
          stripeId.isNotEmpty ||
          paypalEmail.isNotEmpty ||
          venmoUsername.isNotEmpty) {
        await supabase.from('profiles').upsert(payload);
      }

      // Upload logo to Supabase Storage if one was selected
      if (_logoFile != null) {
        await _uploadLogo(supabase, userId);
      }
    } catch (_) {
      // Non-critical — user can set up later
    }
  }

  Future<void> _uploadLogo(SupabaseClient supabase, String userId) async {
    try {
      final ext = _logoFile!.path.split('.').last.toLowerCase();
      final fileName = '$userId/logo.$ext';

      await supabase.storage.from('logos').upload(
            fileName,
            _logoFile!,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final url = supabase.storage.from('logos').getPublicUrl(fileName);
      final logoUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // Save the logo URL to the profile as well
      await supabase.from('profiles').upsert({
        'id': userId,
        'logo_url': logoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-critical — user can upload later from template editor
    }
  }
}

/// Helper to check if onboarding has been completed
class OnboardingHelper {
  static const _keyPrefix = 'onboarding_complete_';

  static String _keyForUser(String userId) => '$_keyPrefix$userId';

  static Future<bool> isCompleteForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyForUser(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleteForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyForUser(userId), true);
    } catch (_) {
      // Non-critical
    }
  }

  static Future<bool> isComplete() async {
    return false;
  }

  static Future<void> markComplete() async {
    // Deprecated: onboarding is now stored per authenticated user.
  }
}
