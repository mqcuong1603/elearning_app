import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';

/// Abstract repository interface for authentication operations
/// Following Clean Architecture principles - domain layer defines contracts
abstract class AuthRepositoryInterface {
  /// Authenticate user with username and password
  /// PDF Requirement: Fixed admin/admin credentials
  Future<UserEntity?> authenticate(String username, String password);

  /// Get current logged-in user
  Future<UserEntity?> getCurrentUser();

  /// Logout current user
  Future<void> logout();

  /// Get user by ID
  Future<UserEntity?> getUserById(String id);

  /// Get user by username
  Future<UserEntity?> getUserByUsername(String username);

  /// Update user profile
  Future<bool> updateUser(UserEntity user);

  /// Update user's last login timestamp
  Future<bool> updateLastLogin(String userId);

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
