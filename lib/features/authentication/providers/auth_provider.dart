import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock_auth_repository.dart';
import '../repositories/api_auth_repository.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isMockMode) {
    return const MockAuthenticationRepository();
  } else {
    return const ApiAuthenticationRepository();
  }
});

final authServiceProvider = Provider<AuthenticationService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthenticationService(repository);
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthenticationService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    return const AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _authService.login(email, password);
      state = result;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void checkAuth() async {
    final result = await _authService.checkAuthStatus();
    state = result;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
