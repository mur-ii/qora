import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdatePreferencesEvent extends ProfileEvent {
  const UpdatePreferencesEvent({
    this.language,
    this.notificationsEnabled,
    this.emailNotifications,
    this.pushNotifications,
    this.smsNotifications,
    this.marketingEmails,
  });

  final String? language;
  final bool? notificationsEnabled;
  final bool? emailNotifications;
  final bool? pushNotifications;
  final bool? smsNotifications;
  final bool? marketingEmails;

  @override
  List<Object?> get props => [
    language,
    notificationsEnabled,
    emailNotifications,
    pushNotifications,
    smsNotifications,
    marketingEmails,
  ];
}
