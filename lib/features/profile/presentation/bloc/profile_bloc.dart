import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_payment_methods.dart';
import '../../domain/usecases/get_preferences.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/update_preferences.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final GetPaymentMethods getPaymentMethods;
  final GetPreferences getPreferences;
  final GetTransactions getTransactions;
  final UpdatePreferences updatePreferences;

  ProfileBloc({
    required this.getProfile,
    required this.getPaymentMethods,
    required this.getPreferences,
    required this.getTransactions,
    required this.updatePreferences,
  }) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdatePreferencesEvent>(_onUpdatePreferences);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final profile = await getProfile();
      final paymentMethodsFuture = getPaymentMethods().catchError(
        (_) => const <PaymentMethodEntity>[],
      );
      final transactionsFuture = getTransactions().catchError(
        (_) => const <TransactionEntity>[],
      );
      final preferencesFuture = getPreferences().catchError(
        (_) => null,
      );

      final paymentMethods = await paymentMethodsFuture;
      final transactions = await transactionsFuture;
      final preferences = await preferencesFuture;

      emit(
        ProfileLoaded(
          profile: profile,
          paymentMethods: paymentMethods.isEmpty
              ? null
              : List<PaymentMethodEntity>.from(paymentMethods),
          transactions: transactions.isEmpty
              ? null
              : List<TransactionEntity>.from(transactions),
          preferences: preferences,
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdatePreferences(
    UpdatePreferencesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    final preferences = current.preferences;
    if (preferences == null) return;

    final nextPreferences = preferences.copyWith(
      language: event.language,
      notificationsEnabled: event.notificationsEnabled,
      emailNotifications: event.emailNotifications,
      pushNotifications: event.pushNotifications,
      smsNotifications: event.smsNotifications,
      marketingEmails: event.marketingEmails,
    );

    try {
      final updated = await updatePreferences(nextPreferences);
      emit(current.copyWith(preferences: updated));
    } catch (_) {
      emit(current.copyWith(preferences: nextPreferences));
    }
  }
}
