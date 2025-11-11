import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_state_provider.dart';

/// Provider for current logged-in user
/// Convenience provider that extracts user from auth state
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// Provider to check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAdmin;
});

/// Provider to check if current user is student
final isStudentProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isStudent;
});
