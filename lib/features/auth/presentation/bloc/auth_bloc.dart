import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../research_log/domain/repositories/login_session_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final Register register;
  final Logout logout;
  final ForgotPassword forgotPassword;
  final LoginSessionRepository loginSessionRepository;
  String? _activeSessionId;

  AuthBloc({
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.register,
    required this.logout,
    required this.forgotPassword,
    required this.loginSessionRepository,
  }) : super(AuthInitial()) {
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<LoginWithNameEvent>(_onLoginWithName);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(isEmailLogin: true));
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
    emit(AuthLoading(isGoogleLogin: true));
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
    emit(AuthLoading(isEmailLogin: true));
    try {
      final session = await loginSessionRepository.startSession(event.fullName);
      _activeSessionId = session.sessionId;
      final user = User(
        id: session.sessionId,
        email: '',
        name: event.fullName,
        photoUrl: null,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await register(event.email, event.password, event.name);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final sessionId =
          _activeSessionId ?? loginSessionRepository.getActiveSessionId();
      if (sessionId != null) {
        await loginSessionRepository.endSession(sessionId);
        _activeSessionId = null;
      }
      await logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await forgotPassword(event.email);
      emit(
        ForgotPasswordSuccess(
          message: 'Password reset link sent to ${event.email}',
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthUnauthenticated());
  }
}
