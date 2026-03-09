import '../entities/user_preferences_entity.dart';
import '../repositories/profile_repository.dart';

class UpdatePreferences {
  final ProfileRepository repository;

  UpdatePreferences(this.repository);

  UserPreferencesEntity call(UserPreferencesEntity preferences) {
    return repository.updatePreferences(preferences);
  }
}
