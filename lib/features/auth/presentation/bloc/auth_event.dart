import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LoginWithGoogleEvent extends AuthEvent {
  const LoginWithGoogleEvent();
}

class LoginWithNameEvent extends AuthEvent {
  final String fullName;

  const LoginWithNameEvent({required this.fullName});

  @override
  List<Object?> get props => [fullName];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}
