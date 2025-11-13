import '../models/group_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';

/// Group Service
/// Handles all group-related operations
class GroupService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;

  GroupService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService;

  /// Get all groups
  Future<List<GroupModel>> getAllGroups() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionGroups,
        orderBy: 'name',
      );

      final groups = data.map((json) => GroupModel.fromJson(json)).toList();

      // Cache groups
      await _cacheGroups(groups);

      return groups;
    } catch (e) {
      print('Get all groups error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedGroups();
    }
  }

  /// Get groups by course
  Future<List<GroupModel>> getGroupsByCourse(String courseId) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionGroups,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
        orderBy: 'name',
      );

      final groups = data.map((json) => GroupModel.fromJson(json)).toList();

      return groups;
    } catch (e) {
      print('Get groups by course error: $e');

      // Fallback: Try without orderBy if index is missing, then sort in memory
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          print('Attempting query without orderBy and sorting in memory...');
          final data = await _firestoreService.query(
            collection: AppConstants.collectionGroups,
            filters: [
              QueryFilter(field: 'courseId', isEqualTo: courseId),
            ],
          );

          final groups = data.map((json) => GroupModel.fromJson(json)).toList();

          // Sort in memory by name
          groups.sort((a, b) => a.name.compareTo(b.name));

          return groups;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get group by ID
  Future<GroupModel?> getGroupById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionGroups,
        documentId: id,
      );

      if (data == null) return null;

      return GroupModel.fromJson(data);
    } catch (e) {
      print('Get group by ID error: $e');
      return null;
    }
  }

  /// Create new group
  Future<GroupModel> createGroup({
    required String name,
    required String courseId,
    List<String>? studentIds,
  }) async {
    try {
      // Check if group name already exists in this course
      final nameExists = await _checkGroupNameExistsInCourse(name, courseId);
      if (nameExists) {
        throw Exception('Group name already exists in this course');
      }

      final now = DateTime.now();

      final group = GroupModel(
        id: '', // Will be set by Firestore
        name: name,
        courseId: courseId,
        studentIds: studentIds ?? [],
        createdAt: now,
        updatedAt: now,
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionGroups,
        data: group.toJson(),
      );

      final createdGroup = group.copyWith(id: id);

      // Clear cache to force refresh
      await _clearGroupsCache();

      return createdGroup;
    } catch (e) {
      print('Create group error: $e');
      throw Exception('Failed to create group: ${e.toString()}');
    }
  }

  /// Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      // Check if name changed and if new name exists in this course
      final existingGroup = await getGroupById(group.id);
      if (existingGroup != null && existingGroup.name != group.name) {
        final nameExists = await _checkGroupNameExistsInCourse(
          group.name,
          group.courseId,
          excludeId: group.id,
        );
        if (nameExists) {
          throw Exception('Group name already exists in this course');
        }
      }

      await _firestoreService.update(
        collection: AppConstants.collectionGroups,
        documentId: group.id,
        data: group.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearGroupsCache();
    } catch (e) {
      print('Update group error: $e');
      throw Exception('Failed to update group: ${e.toString()}');
    }
  }

  /// Delete group
  Future<void> deleteGroup(String id) async {
    try {
      final group = await getGroupById(id);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Check if group has students
      if (group.hasStudents) {
        throw Exception(
          'Cannot delete group with students. Please remove all students first.',
        );
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionGroups,
        documentId: id,
      );

      // Clear cache to force refresh
      await _clearGroupsCache();
    } catch (e) {
      print('Delete group error: $e');
      throw Exception('Failed to delete group: ${e.toString()}');
    }
  }

  /// Add student to group
  Future<void> addStudentToGroup({
    required String groupId,
    required String studentId,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Check if student is already in this group
      if (group.hasStudent(studentId)) {
        throw Exception('Student is already in this group');
      }

      // Check if student is in another group for the same course
      final studentGroups = await _getStudentGroupsInCourse(
        studentId,
        group.courseId,
      );
      if (studentGroups.isNotEmpty) {
        throw Exception(
          'Student is already in group "${studentGroups.first.name}" for this course',
        );
      }

      final updatedStudentIds = [...group.studentIds, studentId];
      await updateGroup(group.copyWith(studentIds: updatedStudentIds));
    } catch (e) {
      print('Add student to group error: $e');
      throw Exception('Failed to add student to group: ${e.toString()}');
    }
  }

  /// Remove student from group
  Future<void> removeStudentFromGroup({
    required String groupId,
    required String studentId,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      if (!group.hasStudent(studentId)) {
        throw Exception('Student is not in this group');
      }

      final updatedStudentIds = group.studentIds
          .where((id) => id != studentId)
          .toList();
      await updateGroup(group.copyWith(studentIds: updatedStudentIds));
    } catch (e) {
      print('Remove student from group error: $e');
      throw Exception('Failed to remove student from group: ${e.toString()}');
    }
  }

  /// Batch create groups (for CSV import)
  Future<Map<String, dynamic>> batchCreateGroups(
    List<Map<String, String>> groupsData,
  ) async {
    final results = <String, dynamic>{
      'total': groupsData.length,
      'success': 0,
      'failed': 0,
      'alreadyExists': 0,
      'details': <Map<String, dynamic>>[],
    };

    for (final data in groupsData) {
      final name = data['name']?.trim() ?? '';
      final courseId = data['courseId']?.trim() ?? '';

      try {
        if (name.isEmpty || courseId.isEmpty) {
          results['failed']++;
          results['details'].add({
            'code': name,
            'name': name,
            'status': 'failed',
            'error': 'Group name and course ID are required',
          });
          continue;
        }

        // Check if group name already exists in this course
        final nameExists = await _checkGroupNameExistsInCourse(name, courseId);
        if (nameExists) {
          results['alreadyExists']++;
          results['details'].add({
            'code': name,
            'name': name,
            'status': 'exists',
            'error': 'Group name already exists in this course',
          });
          continue;
        }

        // Create group
        await createGroup(
          name: name,
          courseId: courseId,
        );

        results['success']++;
        results['details'].add({
          'code': name,
          'name': name,
          'status': 'success',
        });
      } catch (e) {
        results['failed']++;
        results['details'].add({
          'code': name,
          'name': name,
          'status': 'failed',
          'error': e.toString(),
        });
      }
    }

    return results;
  }

  /// Batch assign students to groups (for CSV import)
  Future<Map<String, dynamic>> batchAssignStudentsToGroups(
    List<Map<String, String>> assignmentsData,
  ) async {
    final results = <String, dynamic>{
      'total': assignmentsData.length,
      'success': 0,
      'failed': 0,
      'alreadyExists': 0,
      'details': <Map<String, dynamic>>[],
    };

    for (final data in assignmentsData) {
      final studentId = data['studentId']?.trim() ?? '';
      final groupId = data['groupId']?.trim() ?? '';

      try {
        if (studentId.isEmpty || groupId.isEmpty) {
          results['failed']++;
          results['details'].add({
            'code': '$studentId-$groupId',
            'name': 'Student: $studentId, Group: $groupId',
            'status': 'failed',
            'error': 'Student ID and Group ID are required',
          });
          continue;
        }

        // Try to add student to group
        await addStudentToGroup(
          groupId: groupId,
          studentId: studentId,
        );

        results['success']++;
        results['details'].add({
          'code': '$studentId-$groupId',
          'name': 'Student: $studentId, Group: $groupId',
          'status': 'success',
        });
      } catch (e) {
        // Check if error is because student is already in group
        if (e.toString().contains('already in')) {
          results['alreadyExists']++;
          results['details'].add({
            'code': '$studentId-$groupId',
            'name': 'Student: $studentId, Group: $groupId',
            'status': 'exists',
            'error': e.toString(),
          });
        } else {
          results['failed']++;
          results['details'].add({
            'code': '$studentId-$groupId',
            'name': 'Student: $studentId, Group: $groupId',
            'status': 'failed',
            'error': e.toString(),
          });
        }
      }
    }

    return results;
  }

  /// Get student's groups in a specific course
  Future<List<GroupModel>> _getStudentGroupsInCourse(
    String studentId,
    String courseId,
  ) async {
    try {
      final groups = await getGroupsByCourse(courseId);
      return groups.where((group) => group.hasStudent(studentId)).toList();
    } catch (e) {
      print('Get student groups in course error: $e');
      return [];
    }
  }

  /// Stream groups by course (real-time updates)
  Stream<List<GroupModel>> streamGroupsByCourse(String courseId) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionGroups,
      filters: [
        QueryFilter(field: 'courseId', isEqualTo: courseId),
      ],
      orderBy: 'name',
    )
        .map((data) {
      return data.map((json) => GroupModel.fromJson(json)).toList();
    });
  }

  /// Get group count
  Future<int> getGroupCount() async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionGroups,
      );
    } catch (e) {
      print('Get group count error: $e');
      return 0;
    }
  }

  /// Get group count by course
  Future<int> getGroupCountByCourse(String courseId) async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionGroups,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
      );
    } catch (e) {
      print('Get group count by course error: $e');
      return 0;
    }
  }

  /// Check if group name exists in course
  Future<bool> _checkGroupNameExistsInCourse(
    String name,
    String courseId, {
    String? excludeId,
  }) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionGroups,
        filters: [
          QueryFilter(field: 'name', isEqualTo: name),
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
      );

      if (excludeId != null) {
        return data.any((group) => group['id'] != excludeId);
      }

      return data.isNotEmpty;
    } catch (e) {
      print('Check group name exists error: $e');
      return false;
    }
  }

  /// Private: Cache groups
  Future<void> _cacheGroups(List<GroupModel> groups) async {
    try {
      final groupsJson = groups.map((g) => g.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxGroups,
        key: 'all_groups',
        value: groupsJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache groups error: $e');
    }
  }

  /// Private: Get cached groups
  List<GroupModel> _getCachedGroups() {
    try {
      final cached = _hiveService.getCached(key: 'all_groups');
      if (cached != null && cached is List) {
        return cached
            .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached groups error: $e');
      return [];
    }
  }

  /// Private: Clear groups cache
  Future<void> _clearGroupsCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_groups',
      );
    } catch (e) {
      print('Clear groups cache error: $e');
    }
  }
}
