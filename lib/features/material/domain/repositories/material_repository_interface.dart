import 'package:elearning_app/features/material/domain/entities/material_entity.dart';

/// Abstract repository interface for material operations
/// PDF Requirement: Materials are course-wide (visible to all students)
abstract class MaterialRepositoryInterface {
  /// Create a new material
  Future<bool> createMaterial(MaterialEntity material);

  /// Get material by ID
  Future<MaterialEntity?> getMaterialById(String id);

  /// Get all materials for a course
  Future<List<MaterialEntity>> getMaterialsByCourse(String courseId);

  /// Update a material
  Future<bool> updateMaterial(MaterialEntity material);

  /// Delete a material
  Future<bool> deleteMaterial(String id);

  /// Get material count
  Future<int> getMaterialCount({String? courseId});
}
