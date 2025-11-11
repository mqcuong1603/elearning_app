import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/group/domain/entities/group_entity.dart';
import 'package:elearning_app/features/group/presentation/providers/group_repository_provider.dart';

/// Provider for groups by course
final groupsByCourseProvider = FutureProvider.family<List<GroupEntity>, String>((ref, courseId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return await repository.getGroupsByCourse(courseId);
});

/// Provider for groups by course with student counts
/// PDF Requirement: Display group information with student counts
final groupsByCourseWithCountsProvider = FutureProvider.family<List<GroupEntity>, String>((ref, courseId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return await repository.getGroupsByCourseWithCounts(courseId);
});
