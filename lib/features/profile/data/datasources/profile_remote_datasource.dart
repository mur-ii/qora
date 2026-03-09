import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  ProfileModel getProfile();
  Map<String, dynamic> getPaymentMethods();
  Map<String, dynamic> getTransactions();
  Map<String, dynamic> getPreferences();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  static const Map<String, dynamic> _profileResponse = {
    'success': true,
    'data': {
      'id': 'user_12345',
      'fullName': 'Ahmad Rafli',
      'email': 'ahmad.rafli@example.com',
      'username': 'rafli_traveler',
      'avatarUrl': 'https://i.pravatar.cc/300?img=12',
      'currentLevel': 12,
      'currentXP': 2400,
      'xpToNextLevel': 3000,
      'phoneNumber': '+62 812-3456-7890',
      'joinedDate': '2024-03-15T10:30:00Z',
      'bio': 'Love exploring new places and cultures.',
    },
  };

  static const Map<String, dynamic> _paymentMethodsResponse = {
    'success': true,
    'data': [
      {
        'id': 'pm_001',
        'type': 'visa',
        'cardNumber': '4532',
        'cardHolderName': 'Ahmad Rafli',
        'expiryDate': '12/26',
        'isDefault': true,
      },
      {
        'id': 'pm_002',
        'type': 'mastercard',
        'cardNumber': '8821',
        'cardHolderName': 'Ahmad Rafli',
        'expiryDate': '08/27',
        'isDefault': false,
      },
    ],
  };

  static const Map<String, dynamic> _transactionsResponse = {
    'success': true,
    'data': [
      {
        'id': 'tx_001',
        'type': 'payment',
        'amount': 1200000,
        'date': '2026-01-15T14:30:00Z',
        'status': 'completed',
        'description': 'Hotel Booking Payment',
        'hotelName': 'Grand Hyatt Bali',
      },
      {
        'id': 'tx_002',
        'type': 'reward',
        'amount': 50000,
        'date': '2026-01-10T09:15:00Z',
        'status': 'completed',
        'description': 'Level Up Bonus',
      },
      {
        'id': 'tx_003',
        'type': 'payment',
        'amount': 850000,
        'date': '2025-12-28T16:45:00Z',
        'status': 'completed',
        'description': 'Hotel Booking Payment',
        'hotelName': 'Aston Jakarta',
      },
      {
        'id': 'tx_004',
        'type': 'refund',
        'amount': 350000,
        'date': '2025-12-20T11:20:00Z',
        'status': 'completed',
        'description': 'Booking Cancellation Refund',
      },
    ],
  };

  static const Map<String, dynamic> _preferencesResponse = {
    'success': true,
    'data': {
      'language': 'id',
      'currency': 'IDR',
      'notificationsEnabled': true,
      'emailNotifications': true,
      'pushNotifications': true,
      'smsNotifications': false,
      'marketingEmails': true,
    },
  };

  @override
  ProfileModel getProfile() {
    return ProfileModel.fromJson(
      _profileResponse['data'] as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> getPaymentMethods() {
    return _paymentMethodsResponse;
  }

  @override
  Map<String, dynamic> getTransactions() {
    return _transactionsResponse;
  }

  @override
  Map<String, dynamic> getPreferences() {
    return _preferencesResponse;
  }
}
