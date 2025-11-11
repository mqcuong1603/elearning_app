import 'package:elearning_app/core/database/dao/user_dao.dart';
import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';
import 'package:elearning_app/features/auth/domain/repositories/auth_repository_interface.dart';

/// Implementation of AuthRepositoryInterface
/// Wraps UserDao with error handling and business logic
class AuthRepository implements AuthRepositoryInterface {
  final UserDao _userDao;
  UserEntity? _currentUser;

  AuthRepository({UserDao? userDao}) : _userDao = userDao ?? UserDao();

  @override
  Future<UserEntity?> authenticate(String username, String password) async {
    try {
      // PDF Requirement: Fixed admin/admin credentials
      final user = await _userDao.authenticate(username, password);

      if (user != null) {
        _currentUser = user;
        // Update last login timestamp
        await _userDao.updateLastLogin(user.id);
      }

      return user;
    } catch (e) {
      // Log error and return null
      print('Authentication error: $e');
      return null;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      return await _userDao.getById(id);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    try {
      return await _userDao.getByUsername(username);
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  @override
  Future<bool> updateUser(UserEntity user) async {
    try {
      final result = await _userDao.update(user);

      // Update current user if it's the same user
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }

      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  @override
  Future<bool> updateLastLogin(String userId) async {
    try {
      final result = await _userDao.updateLastLogin(userId);
      return result > 0;
    } catch (e) {
      print('Error updating last login: $e');
      return false;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _currentUser != null;
  }
}
