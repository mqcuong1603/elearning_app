import 'package:elearning_app/core/database/dao/material_dao.dart';
import 'package:elearning_app/features/material/domain/entities/material_entity.dart';
import 'package:elearning_app/features/material/domain/repositories/material_repository_interface.dart';

/// Implementation of MaterialRepositoryInterface
class MaterialRepository implements MaterialRepositoryInterface {
  final MaterialDao _materialDao;

  MaterialRepository({MaterialDao? materialDao})
      : _materialDao = materialDao ?? MaterialDao();

  @override
  Future<bool> createMaterial(MaterialEntity material) async {
    try {
      final result = await _materialDao.insert(material);
      return result > 0;
    } catch (e) {
      print('Error creating material: $e');
      return false;
    }
  }

  @override
  Future<MaterialEntity?> getMaterialById(String id) async {
    try {
      return await _materialDao.getByIdWithDetails(id);
    } catch (e) {
      print('Error getting material by ID: $e');
      return null;
    }
  }

  @override
  Future<List<MaterialEntity>> getMaterialsByCourse(String courseId) async {
    try {
      return await _materialDao.getByCourseWithDetails(courseId);
    } catch (e) {
      print('Error getting materials by course: $e');
      return [];
    }
  }

  @override
  Future<bool> updateMaterial(MaterialEntity material) async {
    try {
      final result = await _materialDao.update(material);
      return result > 0;
    } catch (e) {
      print('Error updating material: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteMaterial(String id) async {
    try {
      final result = await _materialDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting material: $e');
      return false;
    }
  }

  @override
  Future<int> getMaterialCount({String? courseId}) async {
    try {
      return await _materialDao.getCount(courseId: courseId);
    } catch (e) {
      print('Error getting material count: $e');
      return 0;
    }
  }
}
