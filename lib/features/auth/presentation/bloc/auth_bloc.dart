import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/login_with_name.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final LoginWithName loginWithName;
  final Register register;
  final Logout logout;

  AuthBloc({
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.loginWithName,
    required this.register,
    required this.logout,
  }) : super(const AuthInitial()) {
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithNameEvent>(_onLoginWithName);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(isEmailLogin: true));
    try {
      final user = await loginWithEmail(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(isGoogleLogin: true));
    try {
      final user = await loginWithGoogle();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoginWithName(
    LoginWithNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(isEmailLogin: true));
    try {
      final user = await loginWithName(event.fullName);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await register(event.email, event.password, event.name);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated());
  }
}
