import '../../features/auth/data/datasources/auth_mock_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/forgot_password.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class AuthInjection {
  static AuthBloc? _authBloc;

  static AuthBloc getAuthBloc() {
    if (_authBloc != null) return _authBloc!;

    // Data sources
    final authMockService = AuthMockService();
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      authService: authMockService,
    );

    // Repository
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
    );

    // Use cases
    final loginWithEmail = LoginWithEmail(authRepository);
    final loginWithGoogle = LoginWithGoogle(authRepository);
    final register = Register(authRepository);
    final logout = Logout(authRepository);
    final forgotPassword = ForgotPassword(authRepository);

    // BLoC
    _authBloc = AuthBloc(
      loginWithEmail: loginWithEmail,
      loginWithGoogle: loginWithGoogle,
      register: register,
      logout: logout,
      forgotPassword: forgotPassword,
    );

    return _authBloc!;
  }

  static void dispose() {
    _authBloc?.close();
    _authBloc = null;
  }
}
