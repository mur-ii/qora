import '../../domain/entities/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final bool isEmailLogin;
  final bool isGoogleLogin;

  AuthLoading({this.isEmailLogin = false, this.isGoogleLogin = false});
}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}

class ForgotPasswordSuccess extends AuthState {
  final String message;

  ForgotPasswordSuccess({required this.message});
}
