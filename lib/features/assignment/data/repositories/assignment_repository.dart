import 'package:elearning_app/core/database/dao/assignment_dao.dart';
import 'package:elearning_app/features/assignment/domain/entities/assignment_entity.dart';
import 'package:elearning_app/features/assignment/domain/repositories/assignment_repository_interface.dart';

/// Implementation of AssignmentRepositoryInterface
class AssignmentRepository implements AssignmentRepositoryInterface {
  final AssignmentDao _assignmentDao;

  AssignmentRepository({AssignmentDao? assignmentDao})
      : _assignmentDao = assignmentDao ?? AssignmentDao();

  @override
  Future<bool> createAssignment(AssignmentEntity assignment) async {
    try {
      final result = await _assignmentDao.insert(assignment);
      return result > 0;
    } catch (e) {
      print('Error creating assignment: $e');
      return false;
    }
  }

  @override
  Future<AssignmentEntity?> getAssignmentById(String id) async {
    try {
      return await _assignmentDao.getByIdWithDetails(id);
    } catch (e) {
      print('Error getting assignment by ID: $e');
      return null;
    }
  }

  @override
  Future<List<AssignmentEntity>> getAssignmentsByCourse(String courseId) async {
    try {
      return await _assignmentDao.getByCourseWithDetails(courseId);
    } catch (e) {
      print('Error getting assignments by course: $e');
      return [];
    }
  }

  @override
  Future<List<AssignmentEntity>> getAssignmentsByGroup(String groupId) async {
    try {
      return await _assignmentDao.getByGroup(groupId);
    } catch (e) {
      print('Error getting assignments by group: $e');
      return [];
    }
  }

  @override
  Future<bool> updateAssignment(AssignmentEntity assignment) async {
    try {
      final result = await _assignmentDao.update(assignment);
      return result > 0;
    } catch (e) {
      print('Error updating assignment: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAssignment(String id) async {
    try {
      final result = await _assignmentDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }

  @override
  Future<int> getAssignmentCount({String? courseId}) async {
    try {
      return await _assignmentDao.getCount(courseId: courseId);
    } catch (e) {
      print('Error getting assignment count: $e');
      return 0;
    }
  }
}
