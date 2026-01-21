import '../entities/user_preferences_entity.dart';
import '../repositories/profile_repository.dart';

class UpdatePreferences {
  final ProfileRepository repository;

  UpdatePreferences(this.repository);

  Future<UserPreferencesEntity> call(UserPreferencesEntity preferences) async {
    return await repository.updatePreferences(preferences);
  }
}
