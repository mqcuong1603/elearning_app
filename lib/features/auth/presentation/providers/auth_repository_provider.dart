import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/auth/data/repositories/auth_repository.dart';
import 'package:elearning_app/features/auth/domain/repositories/auth_repository_interface.dart';

/// Provider for AuthRepository
/// Singleton instance used throughout the app
final authRepositoryProvider = Provider<AuthRepositoryInterface>((ref) {
  return AuthRepository();
});
