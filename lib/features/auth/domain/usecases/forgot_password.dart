import '../repositories/auth_repository.dart';

class ForgotPassword {
  final AuthRepository repository;

  ForgotPassword(this.repository);

  Future<void> call(String email) {
    return repository.forgotPassword(email);
  }
}
