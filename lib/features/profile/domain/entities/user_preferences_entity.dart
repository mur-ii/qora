import 'package:equatable/equatable.dart';

class UserPreferencesEntity extends Equatable {
  const UserPreferencesEntity({
    required this.language,
    required this.currency,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.marketingEmails,
  });

  final String language;
  final String currency;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool marketingEmails;

  UserPreferencesEntity copyWith({
    String? language,
    String? currency,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? marketingEmails,
  }) {
    return UserPreferencesEntity(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }

  @override
  List<Object?> get props => [
    language,
    currency,
    notificationsEnabled,
    emailNotifications,
    pushNotifications,
    smsNotifications,
    marketingEmails,
  ];
}
