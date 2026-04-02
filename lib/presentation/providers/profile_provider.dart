import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/business_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/supabase_service.dart';
import '../../core/errors/error_handler.dart';

/// Profile state
class ProfileState {
  final BusinessProfile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    BusinessProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Profile provider with state management
class ProfileNotifier extends StateNotifier<ProfileState> {
  final IProfileRepository _repository;
  final String? _userId;

  ProfileNotifier(this._repository, this._userId) : super(const ProfileState()) {
    if (_userId != null) {
      loadProfile();
    }
  }

  /// Load profile
  Future<void> loadProfile() async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      var profile = await _repository.getProfile(_userId!);

      // First time user — create a default profile automatically
      if (profile == null) {
        ErrorHandler.info('No profile found, creating default profile');
        await ensureProfile();
        return;
      }

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );

      ErrorHandler.debug('Profile loaded successfully');
    } catch (error, stackTrace) {
      // Profile fetch failed — app still works without it (uses defaults)
      ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Update profile
  Future<void> updateProfile(BusinessProfile profile) async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updated = await _repository.updateProfile(_userId!, profile);
      
      state = state.copyWith(
        profile: updated,
        isLoading: false,
      );

      ErrorHandler.info('Profile updated successfully');
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handle(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Create default profile if none exists
  Future<void> ensureProfile() async {
    if (_userId == null || state.profile != null) return;

    try {
      final defaultProfile = BusinessProfile(
        id: _userId!,
        businessName: 'My Trade Business',
        defaultHourlyRate: 85.0,
        defaultTaxRate: 0.0,
        currencySymbol: '\$',
      );

      await _repository.createProfile(_userId!, defaultProfile);
      await loadProfile();
    } catch (error, stackTrace) {
      ErrorHandler.warning('Failed to create default profile', {'error': error});
    }
  }
}

/// Provider for profile state
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  
  return ProfileNotifier(repository, userId);
});

/// Convenience provider for just the profile
final businessProfileProvider = Provider<BusinessProfile?>((ref) {
  return ref.watch(profileProvider).profile;
});

/// Provider for currency symbol
final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).profile?.currencySymbol ?? '\$';
});

/// Provider for hourly rate
final hourlyRateProvider = Provider<double>((ref) {
  return ref.watch(profileProvider).profile?.defaultHourlyRate ?? 85.0;
});

/// Provider for tax rate
final taxRateProvider = Provider<double>((ref) {
  return ref.watch(profileProvider).profile?.defaultTaxRate ?? 0.0;
});

/// Provider for Pro status
final isProProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).profile?.isPro ?? false;
});

/// Provider for default due days
final defaultDueDaysProvider = Provider<int>((ref) {
  return ref.watch(profileProvider).profile?.defaultDueDays ?? 14;
});

/// Provider for default markup percent
final defaultMarkupProvider = Provider<double>((ref) {
  return ref.watch(profileProvider).profile?.defaultMarkupPercent ?? 0.0;
});

/// Provider for invoice prefix
final invoicePrefixProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).profile?.invoicePrefix ?? 'INV';
});

/// Provider for quote prefix
final quotePrefixProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).profile?.quotePrefix ?? 'QUO';
});
