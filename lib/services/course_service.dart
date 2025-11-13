import '../models/course_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'auth_service.dart';

/// Course Service
/// Handles all course-related operations
class CourseService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final AuthService _authService;

  CourseService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required AuthService authService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _authService = authService;

  /// Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final data = await _firestoreService.getAll(
        collection: AppConstants.collectionCourses,
        orderBy: 'createdAt',
        descending: true,
      );

      final courses = data.map((json) => CourseModel.fromJson(json)).toList();

      // Cache courses
      await _cacheCourses(courses);

      return courses;
    } catch (e) {
      print('Get all courses error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedCourses();
    }
  }

  /// Get courses by semester ID
  Future<List<CourseModel>> getCoursesBySemester(String semesterId) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionCourses,
        filters: [
          QueryFilter(field: 'semesterId', isEqualTo: semesterId),
        ],
        orderBy: 'code',
      );

      return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      print('Get courses by semester error: $e');
      return [];
    }
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionCourses,
        documentId: id,
      );

      if (data == null) return null;

      return CourseModel.fromJson(data);
    } catch (e) {
      print('Get course by ID error: $e');
      return null;
    }
  }

  /// Create new course
  Future<CourseModel> createCourse({
    required String code,
    required String name,
    required String semesterId,
    required int sessions,
    String? description,
    String? coverImageUrl,
  }) async {
    try {
      final now = DateTime.now();
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final course = CourseModel(
        id: '', // Will be set by Firestore
        code: code,
        name: name,
        semesterId: semesterId,
        sessions: sessions,
        description: description,
        coverImageUrl: coverImageUrl,
        instructorId: currentUser.id,
        instructorName: currentUser.fullName,
        createdAt: now,
        updatedAt: now,
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionCourses,
        data: course.toJson(),
      );

      final createdCourse = course.copyWith(id: id);

      // Clear cache to force refresh
      await _clearCoursesCache();

      return createdCourse;
    } catch (e) {
      print('Create course error: $e');
      throw Exception('Failed to create course: ${e.toString()}');
    }
  }

  /// Update course
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionCourses,
        documentId: course.id,
        data: course.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearCoursesCache();
    } catch (e) {
      print('Update course error: $e');
      throw Exception('Failed to update course: ${e.toString()}');
    }
  }

  /// Delete course
  Future<void> deleteCourse(String id) async {
    try {
      // Check if course has groups
      final groupsCount = await _firestoreService.count(
        collection: AppConstants.collectionGroups,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: id),
        ],
      );

      if (groupsCount > 0) {
        throw Exception(
          'Cannot delete course. It has $groupsCount group(s) associated with it.',
        );
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionCourses,
        documentId: id,
      );

      // Clear cache to force refresh
      await _clearCoursesCache();
    } catch (e) {
      print('Delete course error: $e');
      throw Exception(e.toString());
    }
  }

  /// Batch create courses (for CSV import)
  Future<Map<String, dynamic>> batchCreateCourses(
    List<Map<String, String>> coursesData,
    String? defaultSemesterId,
  ) async {
    final results = <String, dynamic>{
      'total': coursesData.length,
      'success': 0,
      'failed': 0,
      'alreadyExists': 0,
      'details': <Map<String, dynamic>>[],
    };

    for (final data in coursesData) {
      try {
        final code = data['code']?.trim() ?? '';
        final name = data['name']?.trim() ?? '';
        final sessionsStr = data['sessions']?.trim() ?? '10';

        // Use semesterId from CSV or fall back to default
        final semesterId = data['semesterId']?.trim() ?? defaultSemesterId ?? '';

        if (code.isEmpty || name.isEmpty) {
          results['failed']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'failed',
            'error': 'Code and name are required',
          });
          continue;
        }

        // Validate semesterId
        if (semesterId.isEmpty) {
          results['failed']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'failed',
            'error': 'Semester ID is required',
          });
          continue;
        }

        // Validate that semester exists
        final semesterExists = await _firestoreService.read(
          collection: AppConstants.collectionSemesters,
          documentId: semesterId,
        );

        if (semesterExists == null) {
          results['failed']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'failed',
            'error': 'Semester ID "$semesterId" does not exist',
          });
          continue;
        }

        // Validate sessions
        final sessions = int.tryParse(sessionsStr) ?? 10;
        if (!AppConstants.allowedCourseSessions.contains(sessions)) {
          results['failed']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'failed',
            'error': 'Sessions must be 10 or 15',
          });
          continue;
        }

        // Check if course already exists in this semester
        final existing = await _firestoreService.query(
          collection: AppConstants.collectionCourses,
          filters: [
            QueryFilter(field: 'code', isEqualTo: code),
            QueryFilter(field: 'semesterId', isEqualTo: semesterId),
          ],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          results['alreadyExists']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'exists',
            'error': 'Course with this code already exists in this semester',
          });
          continue;
        }

        // Create course
        await createCourse(
          code: code,
          name: name,
          semesterId: semesterId,
          sessions: sessions,
          description: data['description']?.trim(),
        );

        results['success']++;
        results['details'].add({
          'code': code,
          'name': name,
          'status': 'success',
        });
      } catch (e) {
        results['failed']++;
        results['details'].add({
          'code': data['code'] ?? '',
          'name': data['name'] ?? '',
          'status': 'failed',
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  /// Stream courses by semester (real-time updates)
  Stream<List<CourseModel>> streamCoursesBySemester(String semesterId) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionCourses,
      filters: [
        QueryFilter(field: 'semesterId', isEqualTo: semesterId),
      ],
      orderBy: 'code',
    )
        .map((data) {
      return data.map((json) => CourseModel.fromJson(json)).toList();
    });
  }

  /// Check if course code exists in semester
  Future<bool> courseCodeExistsInSemester(
    String code,
    String semesterId, {
    String? excludeId,
  }) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionCourses,
        filters: [
          QueryFilter(field: 'code', isEqualTo: code),
          QueryFilter(field: 'semesterId', isEqualTo: semesterId),
        ],
      );

      if (excludeId != null) {
        return data.any((course) => course['id'] != excludeId);
      }

      return data.isNotEmpty;
    } catch (e) {
      print('Check course code exists error: $e');
      return false;
    }
  }

  /// Get course count by semester
  Future<int> getCourseCountBySemester(String semesterId) async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionCourses,
        filters: [
          QueryFilter(field: 'semesterId', isEqualTo: semesterId),
        ],
      );
    } catch (e) {
      print('Get course count error: $e');
      return 0;
    }
  }

  /// Private: Cache courses
  Future<void> _cacheCourses(List<CourseModel> courses) async {
    try {
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxCourses,
        key: 'all_courses',
        value: coursesJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache courses error: $e');
    }
  }

  /// Private: Get cached courses
  List<CourseModel> _getCachedCourses() {
    try {
      final cached = _hiveService.getCached(key: 'all_courses');
      if (cached != null && cached is List) {
        return cached
            .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached courses error: $e');
      return [];
    }
  }

  /// Private: Clear courses cache
  Future<void> _clearCoursesCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_courses',
      );
    } catch (e) {
      print('Clear courses cache error: $e');
    }
  }
}
