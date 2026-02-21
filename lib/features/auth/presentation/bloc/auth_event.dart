abstract class AuthEvent {}

class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  LoginWithEmailEvent({required this.email, required this.password});
}

class LoginWithGoogleEvent extends AuthEvent {}

class LoginWithNameEvent extends AuthEvent {
  final String fullName;

  LoginWithNameEvent({required this.fullName});
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });
}

class LogoutEvent extends AuthEvent {}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  ForgotPasswordEvent({required this.email});
}

class CheckAuthStatusEvent extends AuthEvent {}
