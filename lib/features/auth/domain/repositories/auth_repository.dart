import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> loginWithGoogle();
  Future<User> loginWithName(String fullName);
  Future<User> register(String email, String password, String name);
  Future<void> logout();
  User? getCurrentUser();
}
