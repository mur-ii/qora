import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<User> call(String email, String password, String name) {
    return repository.register(email, password, name);
  }
}
