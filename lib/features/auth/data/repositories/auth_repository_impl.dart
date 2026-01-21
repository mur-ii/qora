import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> loginWithEmail(String email, String password) async {
    try {
      final userModel = await remoteDataSource.loginWithEmail(email, password);
      return userModel.toEntity();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<User> loginWithGoogle() async {
    try {
      final userModel = await remoteDataSource.loginWithGoogle();
      return userModel.toEntity();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<User> register(String email, String password, String name) async {
    try {
      final userModel = await remoteDataSource.register(email, password, name);
      return userModel.toEntity();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  User? getCurrentUser() {
    final userModel = remoteDataSource.getCurrentUser();
    return userModel?.toEntity();
  }
}
