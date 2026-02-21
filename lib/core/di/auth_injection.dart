import 'package:hive/hive.dart';

import '../../features/auth/data/datasources/auth_mock_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/forgot_password.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/research_log/data/datasources/login_session_local_datasource.dart';
import '../../features/research_log/data/models/login_session.dart';
import '../../features/research_log/data/repositories/login_session_repository_impl.dart';

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

    final loginSessionBox = Hive.box<LoginSession>('login_session_box');
    final metaBox = Hive.box<String>('app_meta');
    final loginSessionDataSource = LoginSessionLocalDataSource(
      box: loginSessionBox,
    );
    final loginSessionRepository = LoginSessionRepositoryImpl(
      localDataSource: loginSessionDataSource,
      metaBox: metaBox,
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
      loginSessionRepository: loginSessionRepository,
    );

    return _authBloc!;
  }

  static void dispose() {
    _authBloc?.close();
    _authBloc = null;
  }
}
