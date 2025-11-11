import 'package:elearning_app/core/database/dao/semester_dao.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/domain/repositories/semester_repository_interface.dart';

/// Implementation of SemesterRepositoryInterface
class SemesterRepository implements SemesterRepositoryInterface {
  final SemesterDao _semesterDao;

  SemesterRepository({SemesterDao? semesterDao})
      : _semesterDao = semesterDao ?? SemesterDao();

  @override
  Future<bool> createSemester(SemesterEntity semester) async {
    try {
      final result = await _semesterDao.insert(semester);
      return result > 0;
    } catch (e) {
      print('Error creating semester: $e');
      return false;
    }
  }

  @override
  Future<SemesterEntity?> getSemesterById(String id) async {
    try {
      return await _semesterDao.getById(id);
    } catch (e) {
      print('Error getting semester by ID: $e');
      return null;
    }
  }

  @override
  Future<SemesterEntity?> getSemesterByCode(String code) async {
    try {
      return await _semesterDao.getByCode(code);
    } catch (e) {
      print('Error getting semester by code: $e');
      return null;
    }
  }

  @override
  Future<SemesterEntity?> getSemesterByIdWithCounts(String id) async {
    try {
      return await _semesterDao.getByIdWithCounts(id);
    } catch (e) {
      print('Error getting semester with counts: $e');
      return null;
    }
  }

  @override
  Future<List<SemesterEntity>> getAllSemesters() async {
    try {
      return await _semesterDao.getAll();
    } catch (e) {
      print('Error getting all semesters: $e');
      return [];
    }
  }

  @override
  Future<SemesterEntity?> getCurrentSemester() async {
    try {
      return await _semesterDao.getCurrentSemester();
    } catch (e) {
      print('Error getting current semester: $e');
      return null;
    }
  }

  @override
  Future<List<SemesterEntity>> getPastSemesters() async {
    try {
      return await _semesterDao.getPastSemesters();
    } catch (e) {
      print('Error getting past semesters: $e');
      return [];
    }
  }

  @override
  Future<List<SemesterEntity>> getActiveSemesters() async {
    try {
      return await _semesterDao.getActiveSemesters();
    } catch (e) {
      print('Error getting active semesters: $e');
      return [];
    }
  }

  @override
  Future<List<SemesterEntity>> getFutureSemesters() async {
    try {
      return await _semesterDao.getFutureSemesters();
    } catch (e) {
      print('Error getting future semesters: $e');
      return [];
    }
  }

  @override
  Future<bool> setCurrentSemester(String semesterId) async {
    try {
      final result = await _semesterDao.setAsCurrent(semesterId);
      return result > 0;
    } catch (e) {
      print('Error setting current semester: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSemester(SemesterEntity semester) async {
    try {
      final result = await _semesterDao.update(semester);
      return result > 0;
    } catch (e) {
      print('Error updating semester: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteSemester(String id) async {
    try {
      final result = await _semesterDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting semester: $e');
      return false;
    }
  }

  @override
  Future<List<String>> insertBatch(List<SemesterEntity> semesters) async {
    try {
      return await _semesterDao.insertBatch(semesters);
    } catch (e) {
      print('Error batch inserting semesters: $e');
      return [];
    }
  }

  @override
  Future<int> getSemesterCount() async {
    try {
      return await _semesterDao.getCount();
    } catch (e) {
      print('Error getting semester count: $e');
      return 0;
    }
  }
}
