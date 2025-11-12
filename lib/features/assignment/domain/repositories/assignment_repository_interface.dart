import 'package:elearning_app/features/assignment/domain/entities/assignment_entity.dart';

/// Abstract repository interface for assignment operations
/// PDF Requirement: Group-scoped assignments with deadlines and tracking
abstract class AssignmentRepositoryInterface {
  /// Create a new assignment
  Future<bool> createAssignment(AssignmentEntity assignment);

  /// Get assignment by ID
  Future<AssignmentEntity?> getAssignmentById(String id);

  /// Get all assignments for a course
  Future<List<AssignmentEntity>> getAssignmentsByCourse(String courseId);

  /// Get assignments for a specific group
  Future<List<AssignmentEntity>> getAssignmentsByGroup(String groupId);

  /// Update an assignment
  Future<bool> updateAssignment(AssignmentEntity assignment);

  /// Delete an assignment
  Future<bool> deleteAssignment(String id);

  /// Get assignment count
  Future<int> getAssignmentCount({String? courseId});
}
