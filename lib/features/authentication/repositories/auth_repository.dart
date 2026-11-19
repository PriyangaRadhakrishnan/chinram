import '../providers/auth_state.dart';

abstract class AuthRepository {
  Future<AuthState> login(String email, String password);
  Future<void> logout();
  Future<AuthState> checkAuthStatus();
}
