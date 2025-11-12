import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/material/domain/entities/material_entity.dart';
import 'package:elearning_app/features/material/presentation/providers/material_repository_provider.dart';

/// Provider for materials by course
final materialsByCourseProvider = FutureProvider.family<List<MaterialEntity>, String>((ref, courseId) async {
  final repository = ref.watch(materialRepositoryProvider);
  return await repository.getMaterialsByCourse(courseId);
});

/// Provider for material detail
final materialDetailProvider = FutureProvider.family<MaterialEntity?, String>((ref, materialId) async {
  final repository = ref.watch(materialRepositoryProvider);
  return await repository.getMaterialById(materialId);
});
