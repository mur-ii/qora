import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_payment_methods.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_preferences.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final GetPaymentMethods getPaymentMethods;
  final UpdatePreferences updatePreferences;

  ProfileBloc({
    required this.getProfile,
    required this.getPaymentMethods,
    required this.updatePreferences,
  }) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<LoadPaymentMethodsEvent>(_onLoadPaymentMethods);
    on<LoadPreferencesEvent>(_onLoadPreferences);
    on<UpdatePreferencesEvent>(_onUpdatePreferences);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final profile = await getProfile();
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethodsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      try {
        final paymentMethods = await getPaymentMethods();
        emit((state as ProfileLoaded).copyWith(paymentMethods: paymentMethods));
      } catch (e) {
        // Keep current state, just log error
      }
    }
  }

  Future<void> _onLoadPreferences(
    LoadPreferencesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Implementation for loading preferences
  }

  Future<void> _onUpdatePreferences(
    UpdatePreferencesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Implementation for updating preferences
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const LogoutSuccess());
  }
}
