import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semester_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';

/// Semester Service
/// Handles all semester-related operations
class SemesterService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;

  SemesterService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService;

  /// Get all semesters
  Future<List<SemesterModel>> getAllSemesters() async {
    try {
      final data = await _firestoreService.getAll(
        collection: AppConstants.collectionSemesters,
        orderBy: 'createdAt',
        descending: true,
      );

      final semesters = data.map((json) => SemesterModel.fromJson(json)).toList();

      // Cache semesters
      await _cacheSemesters(semesters);

      return semesters;
    } catch (e) {
      print('Get all semesters error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedSemesters();
    }
  }

  /// Get semester by ID
  Future<SemesterModel?> getSemesterById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionSemesters,
        documentId: id,
      );

      if (data == null) return null;

      return SemesterModel.fromJson(data);
    } catch (e) {
      print('Get semester by ID error: $e');
      return null;
    }
  }

  /// Get current semester
  Future<SemesterModel?> getCurrentSemester() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionSemesters,
        filters: [
          QueryFilter(field: 'isCurrent', isEqualTo: true),
        ],
        limit: 1,
      );

      if (data.isEmpty) return null;

      return SemesterModel.fromJson(data.first);
    } catch (e) {
      print('Get current semester error: $e');
      return null;
    }
  }

  /// Create new semester
  Future<SemesterModel> createSemester({
    required String code,
    required String name,
    bool isCurrent = false,
  }) async {
    try {
      // If this is marked as current, unmark all others first
      if (isCurrent) {
        await _unmarkAllCurrentSemesters();
      }

      final now = DateTime.now();
      final semester = SemesterModel(
        id: '', // Will be set by Firestore
        code: code,
        name: name,
        createdAt: now,
        updatedAt: now,
        isCurrent: isCurrent,
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionSemesters,
        data: semester.toJson(),
      );

      final createdSemester = semester.copyWith(id: id);

      // Clear cache to force refresh
      await _clearSemestersCache();

      return createdSemester;
    } catch (e) {
      print('Create semester error: $e');
      throw Exception('Failed to create semester: ${e.toString()}');
    }
  }

  /// Update semester
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      // If marking as current, unmark all others first
      if (semester.isCurrent) {
        await _unmarkAllCurrentSemesters();
      }

      await _firestoreService.update(
        collection: AppConstants.collectionSemesters,
        documentId: semester.id,
        data: semester.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearSemestersCache();
    } catch (e) {
      print('Update semester error: $e');
      throw Exception('Failed to update semester: ${e.toString()}');
    }
  }

  /// Delete semester
  Future<void> deleteSemester(String id) async {
    try {
      // Check if semester has courses
      final coursesCount = await _firestoreService.count(
        collection: AppConstants.collectionCourses,
        filters: [
          QueryFilter(field: 'semesterId', isEqualTo: id),
        ],
      );

      if (coursesCount > 0) {
        throw Exception(
          'Cannot delete semester. It has $coursesCount course(s) associated with it.',
        );
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionSemesters,
        documentId: id,
      );

      // Clear cache to force refresh
      await _clearSemestersCache();
    } catch (e) {
      print('Delete semester error: $e');
      throw Exception(e.toString());
    }
  }

  /// Mark semester as current
  Future<void> markAsCurrent(String id) async {
    try {
      // Unmark all current semesters
      await _unmarkAllCurrentSemesters();

      // Mark this one as current
      await _firestoreService.update(
        collection: AppConstants.collectionSemesters,
        documentId: id,
        data: {
          'isCurrent': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Clear cache to force refresh
      await _clearSemestersCache();
    } catch (e) {
      print('Mark as current error: $e');
      throw Exception('Failed to mark semester as current: ${e.toString()}');
    }
  }

  /// Batch create semesters (for CSV import)
  Future<Map<String, dynamic>> batchCreateSemesters(
    List<Map<String, String>> semestersData,
  ) async {
    final results = <String, dynamic>{
      'total': semestersData.length,
      'success': 0,
      'failed': 0,
      'alreadyExists': 0,
      'details': <Map<String, dynamic>>[],
    };

    for (final data in semestersData) {
      try {
        final code = data['code']?.trim() ?? '';
        final name = data['name']?.trim() ?? '';

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

        // Check if semester already exists
        final existing = await _firestoreService.query(
          collection: AppConstants.collectionSemesters,
          filters: [
            QueryFilter(field: 'code', isEqualTo: code),
          ],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          results['alreadyExists']++;
          results['details'].add({
            'code': code,
            'name': name,
            'status': 'exists',
            'error': 'Semester with this code already exists',
          });
          continue;
        }

        // Create semester
        await createSemester(
          code: code,
          name: name,
          isCurrent: false,
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

  /// Stream all semesters (real-time updates)
  Stream<List<SemesterModel>> streamSemesters() {
    return _firestoreService
        .streamCollection(
      collection: AppConstants.collectionSemesters,
      orderBy: 'createdAt',
      descending: true,
    )
        .map((data) {
      return data.map((json) => SemesterModel.fromJson(json)).toList();
    });
  }

  /// Check if semester code exists
  Future<bool> semesterCodeExists(String code, {String? excludeId}) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionSemesters,
        filters: [
          QueryFilter(field: 'code', isEqualTo: code),
        ],
      );

      if (excludeId != null) {
        return data.any((semester) => semester['id'] != excludeId);
      }

      return data.isNotEmpty;
    } catch (e) {
      print('Check semester code exists error: $e');
      return false;
    }
  }

  /// Private: Unmark all current semesters
  Future<void> _unmarkAllCurrentSemesters() async {
    try {
      final currentSemesters = await _firestoreService.query(
        collection: AppConstants.collectionSemesters,
        filters: [
          QueryFilter(field: 'isCurrent', isEqualTo: true),
        ],
      );

      if (currentSemesters.isNotEmpty) {
        final updates = currentSemesters.map((semester) {
          return BatchUpdateItem(
            documentId: semester['id'] as String,
            data: {
              'isCurrent': false,
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }).toList();

        await _firestoreService.batchUpdate(
          collection: AppConstants.collectionSemesters,
          updates: updates,
        );
      }
    } catch (e) {
      print('Unmark all current semesters error: $e');
    }
  }

  /// Private: Cache semesters
  Future<void> _cacheSemesters(List<SemesterModel> semesters) async {
    try {
      final semestersJson = semesters.map((s) => s.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxSemesters,
        key: 'all_semesters',
        value: semestersJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache semesters error: $e');
    }
  }

  /// Private: Get cached semesters
  List<SemesterModel> _getCachedSemesters() {
    try {
      final cached = _hiveService.getCached(key: 'all_semesters');
      if (cached != null && cached is List) {
        return cached
            .map((json) => SemesterModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached semesters error: $e');
      return [];
    }
  }

  /// Private: Clear semesters cache
  Future<void> _clearSemestersCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_semesters',
      );
    } catch (e) {
      print('Clear semesters cache error: $e');
    }
  }
}
