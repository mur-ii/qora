import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/usecases/get_payment_methods.dart';
import '../../features/profile/domain/usecases/get_preferences.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/get_transactions.dart';
import '../../features/profile/domain/usecases/update_preferences.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

class ProfileInjection {
  static ProfileBloc createBloc() {
    final dataSource = ProfileRemoteDataSourceImpl();
    final repository = ProfileRepositoryImpl(dataSource);
    return ProfileBloc(
      getProfile: GetProfile(repository),
      getPaymentMethods: GetPaymentMethods(repository),
      getPreferences: GetPreferences(repository),
      getTransactions: GetTransactions(repository),
      updatePreferences: UpdatePreferences(repository),
    );
  }
}
