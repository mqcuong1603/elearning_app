import 'package:elearning_app/features/course/domain/entities/course_entity.dart';

/// Abstract repository interface for course operations
abstract class CourseRepositoryInterface {
  /// Create a new course
  Future<bool> createCourse(CourseEntity course);

  /// Get course by ID
  Future<CourseEntity?> getCourseById(String id);

  /// Get course by ID with details (semester name, instructor name, counts)
  Future<CourseEntity?> getCourseByIdWithDetails(String id);

  /// Get all courses
  Future<List<CourseEntity>> getAllCourses();

  /// Get courses by semester
  Future<List<CourseEntity>> getCoursesBySemester(String semesterId);

  /// Get courses by instructor
  Future<List<CourseEntity>> getCoursesByInstructor(String instructorId);

  /// Get courses by student ID (enrolled courses)
  /// PDF Requirement: "For students, the homepage displays enrolled courses as cards"
  Future<List<CourseEntity>> getCoursesByStudent(String studentId, {String? semesterId});

  /// Search courses by name or code
  Future<List<CourseEntity>> searchCourses(String query, {String? semesterId});

  /// Update course
  Future<bool> updateCourse(CourseEntity course);

  /// Delete course
  Future<bool> deleteCourse(String id);

  /// Batch insert courses (for CSV import)
  Future<List<String>> insertBatch(List<CourseEntity> courses);

  /// Get course count
  Future<int> getCourseCount({String? semesterId});
}
