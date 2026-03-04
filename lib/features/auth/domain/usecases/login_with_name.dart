import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithName {
  final AuthRepository repository;

  LoginWithName(this.repository);

  Future<User> call(String fullName) {
    return repository.loginWithName(fullName);
  }
}
