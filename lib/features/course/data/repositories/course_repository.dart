import 'package:elearning_app/core/database/dao/course_dao.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/domain/repositories/course_repository_interface.dart';

/// Implementation of CourseRepositoryInterface
class CourseRepository implements CourseRepositoryInterface {
  final CourseDao _courseDao;

  CourseRepository({CourseDao? courseDao})
      : _courseDao = courseDao ?? CourseDao();

  @override
  Future<bool> createCourse(CourseEntity course) async {
    try {
      final result = await _courseDao.insert(course);
      return result > 0;
    } catch (e) {
      print('Error creating course: $e');
      return false;
    }
  }

  @override
  Future<CourseEntity?> getCourseById(String id) async {
    try {
      return await _courseDao.getById(id);
    } catch (e) {
      print('Error getting course by ID: $e');
      return null;
    }
  }

  @override
  Future<CourseEntity?> getCourseByIdWithDetails(String id) async {
    try {
      return await _courseDao.getByIdWithCounts(id);
    } catch (e) {
      print('Error getting course with details: $e');
      return null;
    }
  }

  @override
  Future<List<CourseEntity>> getAllCourses() async {
    try {
      return await _courseDao.getAll();
    } catch (e) {
      print('Error getting all courses: $e');
      return [];
    }
  }

  @override
  Future<List<CourseEntity>> getCoursesBySemester(String semesterId) async {
    try {
      return await _courseDao.getBySemester(semesterId);
    } catch (e) {
      print('Error getting courses by semester: $e');
      return [];
    }
  }

  @override
  Future<List<CourseEntity>> getCoursesByInstructor(String instructorId) async {
    try {
      return await _courseDao.getByInstructor(instructorId);
    } catch (e) {
      print('Error getting courses by instructor: $e');
      return [];
    }
  }

  @override
  Future<List<CourseEntity>> getCoursesByStudent(String studentId, {String? semesterId}) async {
    try {
      return await _courseDao.getByStudentId(studentId, semesterId: semesterId);
    } catch (e) {
      print('Error getting courses by student: $e');
      return [];
    }
  }

  @override
  Future<List<CourseEntity>> searchCourses(String query, {String? semesterId}) async {
    try {
      return await _courseDao.search(query, semesterId: semesterId);
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  @override
  Future<bool> updateCourse(CourseEntity course) async {
    try {
      final result = await _courseDao.update(course);
      return result > 0;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteCourse(String id) async {
    try {
      final result = await _courseDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }

  @override
  Future<List<String>> insertBatch(List<CourseEntity> courses) async {
    try {
      return await _courseDao.insertBatch(courses);
    } catch (e) {
      print('Error batch inserting courses: $e');
      return [];
    }
  }

  @override
  Future<int> getCourseCount({String? semesterId}) async {
    try {
      return await _courseDao.getCount(semesterId: semesterId);
    } catch (e) {
      print('Error getting course count: $e');
      return 0;
    }
  }
}
