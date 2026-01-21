import '../entities/payment_method_entity.dart';
import '../entities/profile_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/user_preferences_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<List<PaymentMethodEntity>> getPaymentMethods();
  Future<List<TransactionEntity>> getTransactions();
  Future<UserPreferencesEntity> getPreferences();
  Future<UserPreferencesEntity> updatePreferences(
    UserPreferencesEntity preferences,
  );
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<void> logout();
}
