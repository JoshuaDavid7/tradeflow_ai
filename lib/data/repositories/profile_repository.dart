import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/business_profile.dart';
import '../services/supabase_service.dart';
import '../../core/utils/retry_util.dart';
import '../../core/errors/app_exception.dart';

/// Profile repository interface
abstract class IProfileRepository {
  Future<BusinessProfile?> getProfile(String userId);
  Future<BusinessProfile> updateProfile(String userId, BusinessProfile profile);
  Future<BusinessProfile> createProfile(String userId, BusinessProfile profile);
}

/// Profile repository implementation
class ProfileRepository implements IProfileRepository {
  final SupabaseService _supabase;

  ProfileRepository(this._supabase);

  @override
  Future<BusinessProfile?> getProfile(String userId) async {
    return RetryUtil.retry(
      () async {
        // profiles table uses 'id' as primary key (= auth user id), not 'user_id'
        final data = await _supabase.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .limit(1);

        if (data.isEmpty) {
          return null;
        }

        return BusinessProfile.fromJson(data.first as Map<String, dynamic>);
      },
      config: const RetryConfig.conservative(),
    );
  }

  @override
  Future<BusinessProfile> updateProfile(
    String userId,
    BusinessProfile profile,
  ) async {
    return RetryUtil.retry(
      () async {
        final data = await _supabase.update(
          table: 'profiles',
          id: userId,
          data: {
            'business_name': profile.businessName,
            'business_address': profile.businessAddress,
            'business_phone': profile.businessPhone,
            'business_email': profile.businessEmail,
            'tax_id': profile.taxId,
            'hourly_rate': profile.defaultHourlyRate,
            'tax_rate': profile.defaultTaxRate,
            'currency_symbol': profile.currencySymbol,
            'is_pro': profile.isPro,
            'subscription_status': profile.isPro ? 'active' : 'free',
          },
        );

        return BusinessProfile.fromJson(data);
      },
      config: const RetryConfig(),
    );
  }

  @override
  Future<BusinessProfile> createProfile(
    String userId,
    BusinessProfile profile,
  ) async {
    return RetryUtil.retry(
      () async {
        final data = await _supabase.insert(
          table: 'profiles',
          data: {
            'id': userId,
            'business_name': profile.businessName,
            'business_address': profile.businessAddress,
            'business_phone': profile.businessPhone,
            'business_email': profile.businessEmail,
            'tax_id': profile.taxId,
            'hourly_rate': profile.defaultHourlyRate,
            'tax_rate': profile.defaultTaxRate,
            'currency_symbol': profile.currencySymbol,
            'is_pro': profile.isPro,
            'subscription_status': profile.isPro ? 'active' : 'free',
          },
        );

        return BusinessProfile.fromJson(data);
      },
      config: const RetryConfig(),
    );
  }
}

/// Provider for Profile repository
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ProfileRepository(supabase);
});
