import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogle {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  Future<User> call() {
    return repository.loginWithGoogle();
  }
}
