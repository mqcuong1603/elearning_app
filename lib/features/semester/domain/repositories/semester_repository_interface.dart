import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';

/// Abstract repository interface for semester operations
abstract class SemesterRepositoryInterface {
  /// Create a new semester
  Future<bool> createSemester(SemesterEntity semester);

  /// Get semester by ID
  Future<SemesterEntity?> getSemesterById(String id);

  /// Get semester by code
  Future<SemesterEntity?> getSemesterByCode(String code);

  /// Get semester by ID with counts (courses, students)
  Future<SemesterEntity?> getSemesterByIdWithCounts(String id);

  /// Get all semesters
  Future<List<SemesterEntity>> getAllSemesters();

  /// Get current (latest) semester
  /// PDF Requirement: "By default, the system loads the current (latest) semester"
  Future<SemesterEntity?> getCurrentSemester();

  /// Get past semesters (ended)
  Future<List<SemesterEntity>> getPastSemesters();

  /// Get active semesters (currently running)
  Future<List<SemesterEntity>> getActiveSemesters();

  /// Get future semesters (not yet started)
  Future<List<SemesterEntity>> getFutureSemesters();

  /// Set a semester as current
  Future<bool> setCurrentSemester(String semesterId);

  /// Update semester
  Future<bool> updateSemester(SemesterEntity semester);

  /// Delete semester
  Future<bool> deleteSemester(String id);

  /// Batch insert semesters (for CSV import)
  Future<List<String>> insertBatch(List<SemesterEntity> semesters);

  /// Get semester count
  Future<int> getSemesterCount();
}
