import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : super(
         ProfileLoaded(
           profile: getProfile(),
           paymentMethods: _nullableList(getPaymentMethods()),
           transactions: _nullableList(getTransactions()),
           preferences: getPreferences(),
         ),
       ) {
    on<UpdatePreferencesEvent>(_onUpdatePreferences);
  }

  static List<T>? _nullableList<T>(List<T> value) {
    if (value.isEmpty) {
      return null;
    }
    return List<T>.from(value);
  }

  void _onUpdatePreferences(
    UpdatePreferencesEvent event,
    Emitter<ProfileState> emit,
  ) {
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
      final updated = updatePreferences(nextPreferences);
      emit(current.copyWith(preferences: updated));
    } catch (_) {
      emit(current.copyWith(preferences: nextPreferences));
    }
  }
}
