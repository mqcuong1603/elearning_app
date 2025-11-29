import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

/// Authentication Service
/// Handles login/logout for both instructor (admin/admin) and students
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is instructor
  bool get isInstructor =>
      _currentUser?.role == AppConstants.roleInstructor;

  /// Check if current user is student
  bool get isStudent => _currentUser?.role == AppConstants.roleStudent;

  /// Login with username and password
  /// Supports both admin (hardcoded) and student (from Firestore) credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      // Check for admin credentials (hardcoded as per requirement)
      if (username == AppConstants.adminUsername &&
          password == AppConstants.adminPassword) {
        // Create admin user model
        _currentUser = UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );

        // Sign in anonymously to Firebase Auth for Storage access
        try {
          await _auth.signInAnonymously();
          print('✅ Admin signed in anonymously for Storage access');
        } catch (e) {
          print('⚠️ Warning: Anonymous auth failed for admin: $e');
          print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
        }

        return _currentUser;
      }

      // For students, check Firestore
      final usersQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      final userData = usersQuery.docs.first.data();

      // Verify password (stored in plain text in Firestore for simplicity)
      // In production, you should use proper password hashing
      if (userData['password'] != password) {
        throw Exception(AppConstants.errorInvalidCredentials);
      }

      // Create user model from Firestore data
      _currentUser = UserModel.fromJson(userData);

      // Sign in anonymously to Firebase Auth for Storage access
      try {
        await _auth.signInAnonymously();
        print('✅ Student signed in anonymously for Storage access');
      } catch (e) {
        print('⚠️ Warning: Anonymous auth failed for student: $e');
        print('Storage uploads may not work. Enable Anonymous Auth in Firebase Console.');
      }

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().contains('Invalid')
          ? AppConstants.errorInvalidCredentials
          : AppConstants.errorAuth);
    }
  }

  /// Login with email and password (alternative method using Firebase Auth)
  /// This is for future use if you want to implement proper Firebase Authentication
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception(AppConstants.errorAuth);
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      _currentUser = UserModel.fromJson(userDoc.data()!);
      return _currentUser;
    } catch (e) {
      print('Login with email error: $e');
      throw Exception(AppConstants.errorAuth);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase Auth if authenticated
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  /// Register a new student (only instructor can do this)
  Future<UserModel?> registerStudent({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      // Check if user is instructor
      if (!isInstructor) {
        throw Exception(AppConstants.errorPermission);
      }

      // Generate username if not provided
      final finalUsername = username ?? studentId;

      // Check if student already exists
      final existingQuery = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Student with ID $studentId already exists');
      }

      // Create new student user
      final newUser = UserModel(
        id: _firestore.collection(AppConstants.collectionUsers).doc().id,
        username: finalUsername,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        avatarUrl: null,
        studentId: studentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        additionalInfo: null,
      );

      // Save to Firestore with password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(newUser.id)
          .set({
        ...newUser.toJson(),
        'password': password, // Store password (plain text for simplicity)
      });

      return newUser;
    } catch (e) {
      print('Register student error: $e');
      throw Exception('Failed to register student: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in Firestore (skip for admin)
      if (_currentUser!.id != 'admin') {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(_currentUser!.id)
            .update(updates);
      }

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        additionalInfo: additionalInfo,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Admin cannot change password (hardcoded)
    if (_currentUser!.id == 'admin') {
      throw Exception('Admin password cannot be changed');
    }

    try {
      // Get user document
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Verify current password
      if (userDoc.data()!['password'] != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUser!.id)
          .update({
        'password': newPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check for admin
      if (userId == 'admin') {
        return UserModel(
          id: 'admin',
          username: AppConstants.adminUsername,
          fullName: 'Administrator',
          email: 'admin@elearning.com',
          role: AppConstants.roleInstructor,
          avatarUrl: null,
          studentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          additionalInfo: {'isAdmin': true},
        );
      }

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromJson(userDoc.data()!);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Validate session on app start
  Future<bool> validateSession() async {
    try {
      // Check if there's a Firebase Auth session
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        // Restore user from Firestore
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromJson(userDoc.data()!);
          return true;
        }
      }

      // No valid session
      _currentUser = null;
      return false;
    } catch (e) {
      print('Session validation error: $e');
      _currentUser = null;
      return false;
    }
  }

  /// Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      // Check for admin username
      if (username == AppConstants.adminUsername) {
        return true;
      }

      final query = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Check username exists error: $e');
      return false;
    }
  }

  /// Create user credential (username/password pair in Firestore)
  /// This is a simple approach - in production, use proper auth with hashing
  Future<void> createUserCredential({
    required String username,
    required String password,
  }) async {
    try {
      // For this simple system, the password is stored in the user document
      // This is handled when creating the user, so this method is just a placeholder
      // In a real system, you'd create Firebase Auth credentials here
    } catch (e) {
      print('Create user credential error: $e');
      throw Exception('Failed to create credentials');
    }
  }

  /// Delete user credential
  Future<void> deleteUserCredential(String username) async {
    try {
      // In this simple system, credentials are deleted with the user document
      // This is just a placeholder for consistency
    } catch (e) {
      print('Delete user credential error: $e');
    }
  }
}
