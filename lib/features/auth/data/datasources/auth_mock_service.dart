import '../models/user_model.dart';

class AuthMockService {
  UserModel? _currentUser;

  Future<UserModel> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    // Mock successful login
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@')[0],
      photoUrl: null,
    );

    _currentUser = user;
    return user;
  }

  Future<UserModel> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 2));

    // Mock Google login
    final user = UserModel(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@gmail.com',
      name: 'Google User',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
    );

    _currentUser = user;
    return user;
  }

  Future<UserModel> loginWithName(String fullName) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (fullName.trim().isEmpty) {
      throw Exception('Full name is required');
    }

    // Mock quick access flow for test sessions
    final user = UserModel(
      id: 'tester_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      name: fullName.trim(),
      photoUrl: null,
    );

    _currentUser = user;
    return user;
  }

  Future<UserModel> register(String email, String password, String name) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('All fields are required');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    if (name.length < 2) {
      throw Exception('Name must be at least 2 characters');
    }

    // Mock successful registration
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      photoUrl: null,
    );

    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  UserModel? getCurrentUser() {
    return _currentUser;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
