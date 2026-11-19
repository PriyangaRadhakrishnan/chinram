import '../providers/auth_state.dart';
import '../repositories/auth_repository.dart';

class AuthenticationService {
  final AuthRepository _repository;

  const AuthenticationService(this._repository);

  Future<AuthState> login(String email, String password) {
    return _repository.login(email, password);
  }

  Future<void> logout() {
    return _repository.logout();
  }

  Future<AuthState> checkAuthStatus() {
    return _repository.checkAuthStatus();
  }
}
