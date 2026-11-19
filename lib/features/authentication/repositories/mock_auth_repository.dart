import '../../../shared/models/user_model.dart';
import '../providers/auth_state.dart';
import 'auth_repository.dart';

class MockAuthUser {
  final String email;
  final String password;
  final String username;
  final String role;

  const MockAuthUser({
    required this.email,
    required this.password,
    required this.username,
    required this.role,
  });
}

class MockAuthenticationRepository implements AuthRepository {
  static const List<MockAuthUser> _mockUsers = [
    MockAuthUser(
      email: 'admin@chinram.com',
      password: 'Admin@123',
      username: 'Admin',
      role: 'Administrator',
    ),
    MockAuthUser(
      email: 'manager@chinram.com',
      password: 'Manager@123',
      username: 'Manager',
      role: 'Manager',
    ),
    MockAuthUser(
      email: 'supervisor@chinram.com',
      password: 'Supervisor@123',
      username: 'Supervisor',
      role: 'Supervisor',
    ),
    MockAuthUser(
      email: 'worker@chinram.com',
      password: 'Worker@123',
      username: 'Worker',
      role: 'Worker',
    ),
  ];

  const MockAuthenticationRepository();

  @override
  Future<AuthState> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final user = _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase() && u.password == password,
      );

      return AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          email: user.email,
          username: user.username,
          role: user.role,
        ),
        token: 'mock_jwt_token_for_${user.username}',
      );
    } catch (_) {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<AuthState> checkAuthStatus() async {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}
