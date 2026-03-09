import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  ProfileEntity getProfile() {
    return remoteDataSource.getProfile();
  }

  @override
  ProfileEntity updateProfile(ProfileEntity profile) {
    return profile;
  }

  @override
  List<PaymentMethodEntity> getPaymentMethods() {
    final response = remoteDataSource.getPaymentMethods();
    final List<dynamic> data = response['data'] as List<dynamic>;

    return data.map((json) {
      return PaymentMethodEntity(
        id: json['id'] as String,
        type: json['type'] as String,
        cardNumber: json['cardNumber'] as String,
        cardHolderName: json['cardHolderName'] as String,
        expiryDate: json['expiryDate'] as String,
        isDefault: json['isDefault'] as bool,
      );
    }).toList();
  }

  @override
  List<TransactionEntity> getTransactions() {
    final response = remoteDataSource.getTransactions();
    final List<dynamic> data = response['data'] as List<dynamic>;

    return data.map((json) {
      return TransactionEntity(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        status: json['status'] as String,
        description: json['description'] as String,
        hotelName: json['hotelName'] as String?,
      );
    }).toList();
  }

  @override
  UserPreferencesEntity getPreferences() {
    final response = remoteDataSource.getPreferences();
    final data = response['data'] as Map<String, dynamic>;

    return UserPreferencesEntity(
      language: data['language'] as String,
      currency: data['currency'] as String,
      notificationsEnabled: data['notificationsEnabled'] as bool,
      emailNotifications: data['emailNotifications'] as bool,
      pushNotifications: data['pushNotifications'] as bool,
      smsNotifications: data['smsNotifications'] as bool,
      marketingEmails: data['marketingEmails'] as bool,
    );
  }

  @override
  UserPreferencesEntity updatePreferences(UserPreferencesEntity preferences) {
    return preferences;
  }

  @override
  void changePassword(String oldPassword, String newPassword) {}

  @override
  void logout() {}
}
