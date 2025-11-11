import 'package:elearning_app/core/database/dao/group_dao.dart';
import 'package:elearning_app/features/group/domain/entities/group_entity.dart';
import 'package:elearning_app/features/group/domain/repositories/group_repository_interface.dart';

/// Implementation of GroupRepositoryInterface
class GroupRepository implements GroupRepositoryInterface {
  final GroupDao _groupDao;

  GroupRepository({GroupDao? groupDao}) : _groupDao = groupDao ?? GroupDao();

  @override
  Future<bool> createGroup(GroupEntity group) async {
    try {
      final result = await _groupDao.insert(group);
      return result > 0;
    } catch (e) {
      print('Error creating group: $e');
      return false;
    }
  }

  @override
  Future<GroupEntity?> getGroupById(String id) async {
    try {
      return await _groupDao.getById(id);
    } catch (e) {
      print('Error getting group by ID: $e');
      return null;
    }
  }

  @override
  Future<GroupEntity?> getGroupByIdWithCount(String id) async {
    try {
      return await _groupDao.getByIdWithCounts(id);
    } catch (e) {
      print('Error getting group with count: $e');
      return null;
    }
  }

  @override
  Future<List<GroupEntity>> getAllGroups() async {
    try {
      return await _groupDao.getAll();
    } catch (e) {
      print('Error getting all groups: $e');
      return [];
    }
  }

  @override
  Future<List<GroupEntity>> getGroupsByCourse(String courseId) async {
    try {
      return await _groupDao.getByCourse(courseId);
    } catch (e) {
      print('Error getting groups by course: $e');
      return [];
    }
  }

  @override
  Future<List<GroupEntity>> getGroupsByCourseWithCounts(String courseId) async {
    try {
      return await _groupDao.getByCourseWithCounts(courseId);
    } catch (e) {
      print('Error getting groups with counts: $e');
      return [];
    }
  }

  @override
  Future<bool> updateGroup(GroupEntity group) async {
    try {
      final result = await _groupDao.update(group);
      return result > 0;
    } catch (e) {
      print('Error updating group: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteGroup(String id) async {
    try {
      final result = await _groupDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  @override
  Future<List<String>> insertBatch(List<GroupEntity> groups) async {
    try {
      return await _groupDao.insertBatch(groups);
    } catch (e) {
      print('Error batch inserting groups: $e');
      return [];
    }
  }

  @override
  Future<int> getGroupCount({String? courseId}) async {
    try {
      return await _groupDao.getCount(courseId: courseId);
    } catch (e) {
      print('Error getting group count: $e');
      return 0;
    }
  }
}
