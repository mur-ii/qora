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
  Future<ProfileEntity> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    // Simulate update
    await Future.delayed(const Duration(milliseconds: 500));
    return profile;
  }

  @override
  Future<List<PaymentMethodEntity>> getPaymentMethods() async {
    final response = await remoteDataSource.getPaymentMethods();
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
  Future<List<TransactionEntity>> getTransactions() async {
    final response = await remoteDataSource.getTransactions();
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
  Future<UserPreferencesEntity> getPreferences() async {
    final response = await remoteDataSource.getPreferences();
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
  Future<UserPreferencesEntity> updatePreferences(
    UserPreferencesEntity preferences,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return preferences;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
