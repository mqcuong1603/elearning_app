import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';
import 'package:elearning_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_repository_provider.dart';

/// Auth state - represents authentication status
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.role == UserRole.admin;
  bool get isStudent => user?.role == UserRole.student;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Auth state notifier - manages authentication state
class AuthStateNotifier extends Notifier<AuthState> {
  late final AuthRepositoryInterface _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  /// Login with username and password
  /// PDF Requirement: Fixed admin/admin credentials
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authRepository.authenticate(username, password);

      if (user != null) {
        state = AuthState(user: user, isLoading: false);
        return true;
      } else {
        state = const AuthState(
          isLoading: false,
          error: 'Invalid username or password',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState();
  }

  /// Check if user is already authenticated
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await _authRepository.getCurrentUser();
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth && user != null) {
        state = AuthState(user: user, isLoading: false);
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isLoading: false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserEntity updatedUser) async {
    try {
      final success = await _authRepository.updateUser(updatedUser);

      if (success) {
        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for auth state
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);
