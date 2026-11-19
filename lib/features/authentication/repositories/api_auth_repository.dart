import '../providers/auth_state.dart';
import 'auth_repository.dart';

class ApiAuthenticationRepository implements AuthRepository {
  const ApiAuthenticationRepository();

  @override
  Future<AuthState> login(String email, String password) async {
    throw UnimplementedError('API Authentication is not implemented yet.');
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError('API Authentication is not implemented yet.');
  }

  @override
  Future<AuthState> checkAuthStatus() async {
    throw UnimplementedError('API Authentication is not implemented yet.');
  }
}
