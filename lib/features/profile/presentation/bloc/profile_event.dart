import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class LoadPaymentMethodsEvent extends ProfileEvent {
  const LoadPaymentMethodsEvent();
}

class LoadTransactionsEvent extends ProfileEvent {
  const LoadTransactionsEvent();
}

class LoadPreferencesEvent extends ProfileEvent {
  const LoadPreferencesEvent();
}

class UpdatePreferencesEvent extends ProfileEvent {
  const UpdatePreferencesEvent({
    this.language,
    this.emailNotifications,
    this.pushNotifications,
    this.smsNotifications,
    this.marketingEmails,
  });

  final String? language;
  final bool? emailNotifications;
  final bool? pushNotifications;
  final bool? smsNotifications;
  final bool? marketingEmails;

  @override
  List<Object?> get props => [
        language,
        emailNotifications,
        pushNotifications,
        smsNotifications,
        marketingEmails,
      ];
}

class LogoutEvent extends ProfileEvent {
  const LogoutEvent();
}
