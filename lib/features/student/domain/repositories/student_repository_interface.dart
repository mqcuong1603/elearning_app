import 'package:elearning_app/features/student/domain/entities/student_entity.dart';

/// Abstract repository interface for student enrollment operations
/// PDF Requirement: "within a course, each student can belong to only one group"
abstract class StudentRepositoryInterface {
  /// Enroll a student in a group
  /// Enforces one group per course rule
  Future<bool> enrollStudent(StudentEnrollmentEntity enrollment);

  /// Get enrollment by ID
  Future<StudentEnrollmentEntity?> getEnrollmentById(String id);

  /// Get student's enrollment in a specific course
  Future<StudentEnrollmentEntity?> getEnrollmentByStudentAndCourse(
    String studentId,
    String courseId,
    String semesterId,
  );

  /// Get all enrollments for a student
  Future<List<StudentEnrollmentEntity>> getEnrollmentsByStudent(String studentId);

  /// Get all students in a group
  Future<List<StudentEnrollmentEntity>> getStudentsByGroup(String groupId);

  /// Get all students in a course
  Future<List<StudentEnrollmentEntity>> getStudentsByCourse(String courseId);

  /// Get all enrollments in a course with student details (for list screen)
  Future<List<StudentEnrollmentEntity>> getEnrollmentsByCourseWithDetails(String courseId);

  /// Check if student is already enrolled in a course
  Future<bool> isStudentEnrolled(String studentId, String courseId, String semesterId);

  /// Update enrollment (change group)
  Future<bool> updateEnrollment(StudentEnrollmentEntity enrollment);

  /// Remove student from group
  Future<bool> removeEnrollment(String id);

  /// Batch enroll students (for CSV import)
  Future<List<String>> enrollBatch(List<StudentEnrollmentEntity> enrollments);

  /// Get enrollment count
  Future<int> getEnrollmentCount({String? groupId, String? courseId});
}
