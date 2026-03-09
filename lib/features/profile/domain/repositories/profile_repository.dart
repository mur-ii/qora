import '../entities/payment_method_entity.dart';
import '../entities/profile_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/user_preferences_entity.dart';

abstract class ProfileRepository {
  ProfileEntity getProfile();
  ProfileEntity updateProfile(ProfileEntity profile);
  List<PaymentMethodEntity> getPaymentMethods();
  List<TransactionEntity> getTransactions();
  UserPreferencesEntity getPreferences();
  UserPreferencesEntity updatePreferences(UserPreferencesEntity preferences);
  void changePassword(String oldPassword, String newPassword);
  void logout();
}
