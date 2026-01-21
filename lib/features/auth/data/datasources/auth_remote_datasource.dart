import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> loginWithGoogle();
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  UserModel? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final dynamic authService; // Can be replaced with actual API client

  AuthRemoteDataSourceImpl({required this.authService});

  @override
  Future<UserModel> loginWithEmail(String email, String password) {
    return authService.loginWithEmail(email, password);
  }

  @override
  Future<UserModel> loginWithGoogle() {
    return authService.loginWithGoogle();
  }

  @override
  Future<UserModel> register(String email, String password, String name) {
    return authService.register(email, password, name);
  }

  @override
  Future<void> logout() {
    return authService.logout();
  }

  @override
  Future<void> forgotPassword(String email) {
    return authService.forgotPassword(email);
  }

  @override
  UserModel? getCurrentUser() {
    return authService.getCurrentUser();
  }
}
