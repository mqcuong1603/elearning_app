import 'package:elearning_app/core/database/dao/student_dao.dart';
import 'package:elearning_app/features/student/domain/entities/student_entity.dart';
import 'package:elearning_app/features/student/domain/repositories/student_repository_interface.dart';

/// Implementation of StudentRepositoryInterface
class StudentRepository implements StudentRepositoryInterface {
  final StudentEnrollmentDao _studentDao;

  StudentRepository({StudentEnrollmentDao? studentDao})
      : _studentDao = studentDao ?? StudentEnrollmentDao();

  @override
  Future<bool> enrollStudent(StudentEnrollmentEntity enrollment) async {
    try {
      // DAO enforces one group per course rule
      final result = await _studentDao.insert(enrollment);
      return result > 0;
    } catch (e) {
      print('Error enrolling student: $e');
      return false;
    }
  }

  @override
  Future<StudentEnrollmentEntity?> getEnrollmentById(String id) async {
    try {
      return await _studentDao.getById(id);
    } catch (e) {
      print('Error getting enrollment by ID: $e');
      return null;
    }
  }

  @override
  Future<StudentEnrollmentEntity?> getEnrollmentByStudentAndCourse(
    String studentId,
    String courseId,
    String semesterId,
  ) async {
    try {
      return await _studentDao.getByStudentAndCourse(
        studentId,
        courseId,
        semesterId,
      );
    } catch (e) {
      print('Error getting enrollment: $e');
      return null;
    }
  }

  @override
  Future<List<StudentEnrollmentEntity>> getEnrollmentsByStudent(String studentId) async {
    try {
      return await _studentDao.getByStudent(studentId);
    } catch (e) {
      print('Error getting enrollments by student: $e');
      return [];
    }
  }

  @override
  Future<List<StudentEnrollmentEntity>> getStudentsByGroup(String groupId) async {
    try {
      return await _studentDao.getByGroup(groupId);
    } catch (e) {
      print('Error getting students by group: $e');
      return [];
    }
  }

  @override
  Future<List<StudentEnrollmentEntity>> getStudentsByCourse(String courseId) async {
    try {
      return await _studentDao.getByCourse(courseId);
    } catch (e) {
      print('Error getting students by course: $e');
      return [];
    }
  }

  @override
  Future<List<StudentEnrollmentEntity>> getEnrollmentsByCourseWithDetails(String courseId) async {
    try {
      return await _studentDao.getByCourseWithStudentDetails(courseId);
    } catch (e) {
      print('Error getting enrollments with details: $e');
      return [];
    }
  }

  @override
  Future<bool> isStudentEnrolled(String studentId, String courseId, String semesterId) async {
    try {
      return await _studentDao.isStudentEnrolled(studentId, courseId, semesterId);
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  @override
  Future<bool> updateEnrollment(StudentEnrollmentEntity enrollment) async {
    try {
      final result = await _studentDao.update(enrollment);
      return result > 0;
    } catch (e) {
      print('Error updating enrollment: $e');
      return false;
    }
  }

  @override
  Future<bool> removeEnrollment(String id) async {
    try {
      final result = await _studentDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error removing enrollment: $e');
      return false;
    }
  }

  /// Alias for removeEnrollment with clearer naming
  Future<bool> unenrollStudent(String enrollmentId) async {
    return await removeEnrollment(enrollmentId);
  }

  @override
  Future<List<String>> enrollBatch(List<StudentEnrollmentEntity> enrollments) async {
    try {
      return await _studentDao.insertBatch(enrollments);
    } catch (e) {
      print('Error batch enrolling students: $e');
      return [];
    }
  }

  @override
  Future<int> getEnrollmentCount({String? groupId, String? courseId}) async {
    try {
      return await _studentDao.getCount();
    } catch (e) {
      print('Error getting enrollment count: $e');
      return 0;
    }
  }
}
