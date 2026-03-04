import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/user_preferences_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    this.paymentMethods,
    this.transactions,
    this.preferences,
  });

  final ProfileEntity profile;
  final List<PaymentMethodEntity>? paymentMethods;
  final List<TransactionEntity>? transactions;
  final UserPreferencesEntity? preferences;

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    List<PaymentMethodEntity>? paymentMethods,
    List<TransactionEntity>? transactions,
    UserPreferencesEntity? preferences,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      transactions: transactions ?? this.transactions,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    paymentMethods,
    transactions,
    preferences,
  ];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
