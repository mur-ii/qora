import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithName(String fullName);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
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
  Future<UserModel> loginWithName(String fullName) {
    return authService.loginWithName(fullName);
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
  UserModel? getCurrentUser() {
    return authService.getCurrentUser();
  }
}
