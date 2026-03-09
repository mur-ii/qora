import '../entities/user_preferences_entity.dart';
import '../repositories/profile_repository.dart';

class GetPreferences {
  final ProfileRepository repository;

  GetPreferences(this.repository);

  UserPreferencesEntity call() {
    return repository.getPreferences();
  }
}
