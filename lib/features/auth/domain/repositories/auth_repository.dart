import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> loginWithGoogle();
  Future<User> register(String email, String password, String name);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  User? getCurrentUser();
}
