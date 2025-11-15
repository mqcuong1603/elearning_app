import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'hive_service.dart';
import 'firestore_service.dart';
import '../config/app_constants.dart';
import '../models/course_model.dart';
import '../models/announcement_model.dart';
import '../models/assignment_model.dart';
import '../models/assignment_submission_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_submission_model.dart';
import '../models/material_model.dart';
import '../models/group_model.dart';
import '../models/semester_model.dart';
import '../models/user_model.dart';

/// Offline Sync Service
/// Handles network connectivity detection and offline data synchronization
class OfflineSyncService {
  final HiveService _hiveService;
  final FirestoreService _firestoreService;
  final Connectivity _connectivity = Connectivity();

  // Connectivity state
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _connectivityController = StreamController<bool>.broadcast();

  OfflineSyncService({
    required HiveService hiveService,
    required FirestoreService firestoreService,
  })  : _hiveService = hiveService,
        _firestoreService = firestoreService;

  /// Get online status
  bool get isOnline => _isOnline;

  /// Get connectivity status stream
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    print('OfflineSyncService initialized. Online: $_isOnline');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isOnline = false;
      _connectivityController.add(false);
    }
  }

  /// Handle connectivity change
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;

    // Check if any of the results indicate we're online
    _isOnline = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (wasOnline != _isOnline) {
      print('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _connectivityController.add(_isOnline);

      // If we just came online, trigger a sync
      if (_isOnline) {
        _onConnectionRestored();
      }
    }
  }

  /// Called when connection is restored
  void _onConnectionRestored() {
    print('📡 Connection restored. Online sync available.');
    // Future enhancement: Could trigger automatic sync here
  }

  /// Sync user data for offline access
  Future<void> syncUserData(UserModel user) async {
    try {
      await _hiveService.save(
        boxName: AppConstants.hiveBoxUsers,
        key: user.id,
        value: user,
      );
      print('✅ Synced user data: ${user.fullName}');
    } catch (e) {
      print('Error syncing user data: $e');
    }
  }

  /// Sync semesters for offline access
  Future<void> syncSemesters(List<SemesterModel> semesters) async {
    try {
      for (final semester in semesters) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxSemesters,
          key: semester.id,
          value: semester,
        );
      }
      print('✅ Synced ${semesters.length} semesters');
    } catch (e) {
      print('Error syncing semesters: $e');
    }
  }

  /// Sync courses for offline access
  Future<void> syncCourses(List<CourseModel> courses) async {
    try {
      for (final course in courses) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxCourses,
          key: course.id,
          value: course,
        );
      }
      print('✅ Synced ${courses.length} courses');
    } catch (e) {
      print('Error syncing courses: $e');
    }
  }

  /// Sync groups for offline access
  Future<void> syncGroups(List<GroupModel> groups) async {
    try {
      for (final group in groups) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxGroups,
          key: group.id,
          value: group,
        );
      }
      print('✅ Synced ${groups.length} groups');
    } catch (e) {
      print('Error syncing groups: $e');
    }
  }

  /// Sync announcements for offline access
  Future<void> syncAnnouncements(List<AnnouncementModel> announcements) async {
    try {
      for (final announcement in announcements) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxAnnouncements,
          key: announcement.id,
          value: announcement,
        );
      }
      print('✅ Synced ${announcements.length} announcements');
    } catch (e) {
      print('Error syncing announcements: $e');
    }
  }

  /// Sync assignments for offline access
  Future<void> syncAssignments(List<AssignmentModel> assignments) async {
    try {
      for (final assignment in assignments) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxAssignments,
          key: assignment.id,
          value: assignment,
        );
      }
      print('✅ Synced ${assignments.length} assignments');
    } catch (e) {
      print('Error syncing assignments: $e');
    }
  }

  /// Sync quizzes for offline access
  Future<void> syncQuizzes(List<QuizModel> quizzes) async {
    try {
      for (final quiz in quizzes) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxQuizzes,
          key: quiz.id,
          value: quiz,
        );
      }
      print('✅ Synced ${quizzes.length} quizzes');
    } catch (e) {
      print('Error syncing quizzes: $e');
    }
  }

  /// Sync materials for offline access
  Future<void> syncMaterials(List<MaterialModel> materials) async {
    try {
      for (final material in materials) {
        await _hiveService.save(
          boxName: AppConstants.hiveBoxMaterials,
          key: material.id,
          value: material,
        );
      }
      print('✅ Synced ${materials.length} materials');
    } catch (e) {
      print('Error syncing materials: $e');
    }
  }

  /// Get courses from offline storage
  Future<List<CourseModel>> getOfflineCourses() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxCourses);
      return values
          .whereType<CourseModel>()
          .toList();
    } catch (e) {
      print('Error getting offline courses: $e');
      return [];
    }
  }

  /// Get announcements from offline storage
  Future<List<AnnouncementModel>> getOfflineAnnouncements() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxAnnouncements);
      return values
          .whereType<AnnouncementModel>()
          .toList();
    } catch (e) {
      print('Error getting offline announcements: $e');
      return [];
    }
  }

  /// Get assignments from offline storage
  Future<List<AssignmentModel>> getOfflineAssignments() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxAssignments);
      return values
          .whereType<AssignmentModel>()
          .toList();
    } catch (e) {
      print('Error getting offline assignments: $e');
      return [];
    }
  }

  /// Get quizzes from offline storage
  Future<List<QuizModel>> getOfflineQuizzes() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxQuizzes);
      return values
          .whereType<QuizModel>()
          .toList();
    } catch (e) {
      print('Error getting offline quizzes: $e');
      return [];
    }
  }

  /// Get materials from offline storage
  Future<List<MaterialModel>> getOfflineMaterials() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxMaterials);
      return values
          .whereType<MaterialModel>()
          .toList();
    } catch (e) {
      print('Error getting offline materials: $e');
      return [];
    }
  }

  /// Get groups from offline storage
  Future<List<GroupModel>> getOfflineGroups() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxGroups);
      return values
          .whereType<GroupModel>()
          .toList();
    } catch (e) {
      print('Error getting offline groups: $e');
      return [];
    }
  }

  /// Get semesters from offline storage
  Future<List<SemesterModel>> getOfflineSemesters() async {
    try {
      final values = _hiveService.getAllValues(AppConstants.hiveBoxSemesters);
      return values
          .whereType<SemesterModel>()
          .toList();
    } catch (e) {
      print('Error getting offline semesters: $e');
      return [];
    }
  }

  /// Sync all critical data for a student
  Future<void> syncStudentData({
    required String studentId,
    required String semesterId,
  }) async {
    if (!_isOnline) {
      print('⚠️ Cannot sync: Device is offline');
      return;
    }

    try {
      print('🔄 Syncing student data for offline access...');

      // Get student's groups
      final groupsData = await _firestoreService.getAll(
        collection: AppConstants.collectionGroups,
      );
      final studentGroups = groupsData
          .where((g) {
            final studentIds = List<String>.from(g['studentIds'] ?? []);
            return studentIds.contains(studentId);
          })
          .map((g) => GroupModel.fromJson(g))
          .toList();

      await syncGroups(studentGroups);

      // Get student's courses
      final courseIds =
          studentGroups.map((g) => g.courseId).toSet().toList();
      final courses = <CourseModel>[];
      for (final courseId in courseIds) {
        final courseData = await _firestoreService.read(
          collection: AppConstants.collectionCourses,
          documentId: courseId,
        );
        if (courseData != null) {
          courses.add(CourseModel.fromJson(courseData));
        }
      }
      await syncCourses(courses);

      // Sync announcements for student's courses
      for (final courseId in courseIds) {
        final announcementsData = await _firestoreService.query(
          collection: AppConstants.collectionAnnouncements,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: courseId),
          ],
        );
        final announcements = announcementsData
            .map((a) => AnnouncementModel.fromJson(a))
            .toList();
        await syncAnnouncements(announcements);

        // Sync assignments
        final assignmentsData = await _firestoreService.query(
          collection: AppConstants.collectionAssignments,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: courseId),
          ],
        );
        final assignments = assignmentsData
            .map((a) => AssignmentModel.fromJson(a))
            .toList();
        await syncAssignments(assignments);

        // Sync quizzes
        final quizzesData = await _firestoreService.query(
          collection: AppConstants.collectionQuizzes,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: courseId),
          ],
        );
        final quizzes = quizzesData
            .map((q) => QuizModel.fromJson(q))
            .toList();
        await syncQuizzes(quizzes);

        // Sync materials
        final materialsData = await _firestoreService.query(
          collection: AppConstants.collectionMaterials,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: courseId),
          ],
        );
        final materials = materialsData
            .map((m) => MaterialModel.fromJson(m))
            .toList();
        await syncMaterials(materials);
      }

      print('✅ Student data synced successfully for offline access');
    } catch (e) {
      print('❌ Error syncing student data: $e');
    }
  }

  /// Sync all critical data for an instructor
  Future<void> syncInstructorData({
    required String instructorId,
    required String semesterId,
  }) async {
    if (!_isOnline) {
      print('⚠️ Cannot sync: Device is offline');
      return;
    }

    try {
      print('🔄 Syncing instructor data for offline access...');

      // Get all courses for the semester
      final coursesData = await _firestoreService.query(
        collection: AppConstants.collectionCourses,
        filters: [
          QueryFilter(field: 'semesterId', isEqualTo: semesterId),
        ],
      );
      final courses = coursesData
          .map((c) => CourseModel.fromJson(c))
          .toList();
      await syncCourses(courses);

      // Get all groups
      final groupsData = await _firestoreService.getAll(
        collection: AppConstants.collectionGroups,
      );
      final groups = groupsData
          .map((g) => GroupModel.fromJson(g))
          .toList();
      await syncGroups(groups);

      // Get all students
      final studentsData = await _firestoreService.query(
        collection: AppConstants.collectionUsers,
        filters: [
          QueryFilter(field: 'role', isEqualTo: AppConstants.roleStudent),
        ],
      );
      for (final studentData in studentsData) {
        final student = UserModel.fromJson(studentData);
        await syncUserData(student);
      }

      // Sync course content (announcements, assignments, quizzes, materials)
      for (final course in courses) {
        // Announcements
        final announcementsData = await _firestoreService.query(
          collection: AppConstants.collectionAnnouncements,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: course.id),
          ],
        );
        await syncAnnouncements(
          announcementsData.map((a) => AnnouncementModel.fromJson(a)).toList(),
        );

        // Assignments
        final assignmentsData = await _firestoreService.query(
          collection: AppConstants.collectionAssignments,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: course.id),
          ],
        );
        await syncAssignments(
          assignmentsData.map((a) => AssignmentModel.fromJson(a)).toList(),
        );

        // Quizzes
        final quizzesData = await _firestoreService.query(
          collection: AppConstants.collectionQuizzes,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: course.id),
          ],
        );
        await syncQuizzes(
          quizzesData.map((q) => QuizModel.fromJson(q)).toList(),
        );

        // Materials
        final materialsData = await _firestoreService.query(
          collection: AppConstants.collectionMaterials,
          filters: [
            QueryFilter(field: 'courseId', isEqualTo: course.id),
          ],
        );
        await syncMaterials(
          materialsData.map((m) => MaterialModel.fromJson(m)).toList(),
        );
      }

      print('✅ Instructor data synced successfully for offline access');
    } catch (e) {
      print('❌ Error syncing instructor data: $e');
    }
  }

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
