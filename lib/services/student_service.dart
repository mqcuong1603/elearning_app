import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'auth_service.dart';

/// Student Service
/// Handles all student-related operations
class StudentService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final AuthService _authService;

  StudentService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required AuthService authService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _authService = authService;

  /// Get all students
  Future<List<UserModel>> getAllStudents() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionUsers,
        filters: [
          QueryFilter(field: 'role', isEqualTo: AppConstants.roleStudent),
        ],
        orderBy: 'fullName',
      );

      final students = data.map((json) => UserModel.fromJson(json)).toList();

      // Cache students
      await _cacheStudents(students);

      return students;
    } catch (e) {
      print('Get all students error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedStudents();
    }
  }

  /// Get student by ID
  Future<UserModel?> getStudentById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionUsers,
        documentId: id,
      );

      if (data == null) return null;

      final user = UserModel.fromJson(data);

      // Verify it's a student
      if (!user.isStudent) return null;

      return user;
    } catch (e) {
      print('Get student by ID error: $e');
      return null;
    }
  }

  /// Create new student account
  Future<UserModel> createStudent({
    required String username,
    required String fullName,
    required String email,
    String? studentId,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Check if username already exists
      final usernameExists = await _authService.checkUsernameExists(username);
      if (usernameExists) {
        throw Exception('Username already exists');
      }

      // Check if email already exists
      final emailExists = await _checkEmailExists(email);
      if (emailExists) {
        throw Exception('Email already exists');
      }

      // Check if studentId already exists (if provided)
      if (studentId != null && studentId.isNotEmpty) {
        final studentIdExists = await _checkStudentIdExists(studentId);
        if (studentIdExists) {
          throw Exception('Student ID already exists');
        }
      }

      final now = DateTime.now();

      // Create student user account
      final student = UserModel(
        id: '', // Will be set by Firestore
        username: username,
        fullName: fullName,
        email: email,
        role: AppConstants.roleStudent,
        studentId: studentId,
        avatarUrl: avatarUrl,
        createdAt: now,
        updatedAt: now,
        additionalInfo: additionalInfo,
      );

      // Add password to the data (default password is username)
      final studentData = student.toJson();
      studentData['password'] = username; // Default password is username

      final id = await _firestoreService.create(
        collection: AppConstants.collectionUsers,
        data: studentData,
      );

      final createdStudent = student.copyWith(id: id);

      // Clear cache to force refresh
      await _clearStudentsCache();

      return createdStudent;
    } catch (e) {
      print('Create student error: $e');
      throw Exception('Failed to create student: ${e.toString()}');
    }
  }

  /// Update student
  Future<void> updateStudent(UserModel student) async {
    try {
      // Verify it's a student
      if (!student.isStudent) {
        throw Exception('User is not a student');
      }

      // Check if email changed and if new email exists
      final existingStudent = await getStudentById(student.id);
      if (existingStudent != null && existingStudent.email != student.email) {
        final emailExists = await _checkEmailExists(
          student.email,
          excludeId: student.id,
        );
        if (emailExists) {
          throw Exception('Email already exists');
        }
      }

      // Check if studentId changed and if new studentId exists
      if (existingStudent != null &&
          student.studentId != null &&
          existingStudent.studentId != student.studentId) {
        final studentIdExists = await _checkStudentIdExists(
          student.studentId!,
          excludeId: student.id,
        );
        if (studentIdExists) {
          throw Exception('Student ID already exists');
        }
      }

      await _firestoreService.update(
        collection: AppConstants.collectionUsers,
        documentId: student.id,
        data: student.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearStudentsCache();
    } catch (e) {
      print('Update student error: $e');
      throw Exception('Failed to update student: ${e.toString()}');
    }
  }

  /// Delete student
  Future<void> deleteStudent(String id) async {
    try {
      final student = await getStudentById(id);
      if (student == null) {
        throw Exception('Student not found');
      }

      // Check if student is enrolled in any groups
      final groupsCount = await _firestoreService.count(
        collection: AppConstants.collectionGroups,
        filters: [
          // This would need a proper query based on your group enrollment structure
          // For now, we'll skip this check or implement it based on your data model
        ],
      );

      // Delete student account
      await _firestoreService.delete(
        collection: AppConstants.collectionUsers,
        documentId: id,
      );

      // Delete auth credential
      await _authService.deleteUserCredential(student.username);

      // Clear cache to force refresh
      await _clearStudentsCache();
    } catch (e) {
      print('Delete student error: $e');
      throw Exception('Failed to delete student: ${e.toString()}');
    }
  }

  /// Batch create students (for CSV import with smart handling)
  Future<Map<String, dynamic>> batchCreateStudents(
    List<Map<String, String>> studentsData,
  ) async {
    final results = <String, dynamic>{
      'total': studentsData.length,
      'success': 0,
      'failed': 0,
      'alreadyExists': 0,
      'details': <Map<String, dynamic>>[],
    };

    for (final data in studentsData) {
      try {
        final username = data['username']?.trim() ?? '';
        final fullName = data['fullName']?.trim() ?? '';
        final email = data['email']?.trim() ?? '';
        final studentId = data['studentId']?.trim();

        if (username.isEmpty || fullName.isEmpty || email.isEmpty) {
          results['failed']++;
          results['details'].add({
            'username': username,
            'fullName': fullName,
            'status': 'failed',
            'error': 'Username, full name, and email are required',
          });
          continue;
        }

        // Check if username already exists
        final usernameExists = await _authService.checkUsernameExists(username);
        if (usernameExists) {
          results['alreadyExists']++;
          results['details'].add({
            'username': username,
            'fullName': fullName,
            'status': 'exists',
            'error': 'Username already exists',
          });
          continue;
        }

        // Check if email already exists
        final emailExists = await _checkEmailExists(email);
        if (emailExists) {
          results['alreadyExists']++;
          results['details'].add({
            'username': username,
            'fullName': fullName,
            'status': 'exists',
            'error': 'Email already exists',
          });
          continue;
        }

        // Check if studentId already exists (if provided)
        if (studentId != null && studentId.isNotEmpty) {
          final studentIdExists = await _checkStudentIdExists(studentId);
          if (studentIdExists) {
            results['alreadyExists']++;
            results['details'].add({
              'username': username,
              'fullName': fullName,
              'status': 'exists',
              'error': 'Student ID already exists',
            });
            continue;
          }
        }

        // Create student
        await createStudent(
          username: username,
          fullName: fullName,
          email: email,
          studentId: studentId,
        );

        results['success']++;
        results['details'].add({
          'username': username,
          'fullName': fullName,
          'status': 'success',
        });
      } catch (e) {
        results['failed']++;
        results['details'].add({
          'username': data['username'] ?? '',
          'fullName': data['fullName'] ?? '',
          'status': 'failed',
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  /// Stream all students (real-time updates)
  Stream<List<UserModel>> streamStudents() {
    return _firestoreService
        .streamCollection(
      collection: AppConstants.collectionUsers,
      filters: [
        QueryFilter(field: 'role', isEqualTo: AppConstants.roleStudent),
      ],
      orderBy: 'fullName',
    )
        .map((data) {
      return data.map((json) => UserModel.fromJson(json)).toList();
    });
  }

  /// Get student count
  Future<int> getStudentCount() async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionUsers,
        filters: [
          QueryFilter(field: 'role', isEqualTo: AppConstants.roleStudent),
        ],
      );
    } catch (e) {
      print('Get student count error: $e');
      return 0;
    }
  }

  /// Check if email exists
  Future<bool> _checkEmailExists(String email, {String? excludeId}) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionUsers,
        filters: [
          QueryFilter(field: 'email', isEqualTo: email),
        ],
      );

      if (excludeId != null) {
        return data.any((user) => user['id'] != excludeId);
      }

      return data.isNotEmpty;
    } catch (e) {
      print('Check email exists error: $e');
      return false;
    }
  }

  /// Check if student ID exists
  Future<bool> _checkStudentIdExists(
    String studentId, {
    String? excludeId,
  }) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionUsers,
        filters: [
          QueryFilter(field: 'studentId', isEqualTo: studentId),
          QueryFilter(field: 'role', isEqualTo: AppConstants.roleStudent),
        ],
      );

      if (excludeId != null) {
        return data.any((user) => user['id'] != excludeId);
      }

      return data.isNotEmpty;
    } catch (e) {
      print('Check student ID exists error: $e');
      return false;
    }
  }

  /// Private: Cache students
  Future<void> _cacheStudents(List<UserModel> students) async {
    try {
      final studentsJson = students.map((s) => s.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxUsers,
        key: 'all_students',
        value: studentsJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache students error: $e');
    }
  }

  /// Private: Get cached students
  List<UserModel> _getCachedStudents() {
    try {
      final cached = _hiveService.getCached(key: 'all_students');
      if (cached != null && cached is List) {
        return cached
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached students error: $e');
      return [];
    }
  }

  /// Private: Clear students cache
  Future<void> _clearStudentsCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_students',
      );
    } catch (e) {
      print('Clear students cache error: $e');
    }
  }
}
