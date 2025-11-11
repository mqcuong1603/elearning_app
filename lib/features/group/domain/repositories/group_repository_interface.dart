import 'package:elearning_app/features/group/domain/entities/group_entity.dart';

/// Abstract repository interface for group operations
/// PDF Requirement: "within a course, each student can belong to only one group"
abstract class GroupRepositoryInterface {
  /// Create a new group
  Future<bool> createGroup(GroupEntity group);

  /// Get group by ID
  Future<GroupEntity?> getGroupById(String id);

  /// Get group by ID with student count
  Future<GroupEntity?> getGroupByIdWithCount(String id);

  /// Get all groups
  Future<List<GroupEntity>> getAllGroups();

  /// Get groups by course
  Future<List<GroupEntity>> getGroupsByCourse(String courseId);

  /// Get groups by course with student counts
  Future<List<GroupEntity>> getGroupsByCourseWithCounts(String courseId);

  /// Update group
  Future<bool> updateGroup(GroupEntity group);

  /// Delete group
  Future<bool> deleteGroup(String id);

  /// Batch insert groups (for CSV import)
  Future<List<String>> insertBatch(List<GroupEntity> groups);

  /// Get group count
  Future<int> getGroupCount({String? courseId});
}
