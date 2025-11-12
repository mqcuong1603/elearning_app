import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/assignment/domain/entities/assignment_entity.dart';
import 'package:elearning_app/features/assignment/presentation/providers/assignment_repository_provider.dart';

/// Provider for assignments by course
final assignmentsByCourseProvider = FutureProvider.family<List<AssignmentEntity>, String>((ref, courseId) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getAssignmentsByCourse(courseId);
});

/// Provider for assignments by group
final assignmentsByGroupProvider = FutureProvider.family<List<AssignmentEntity>, String>((ref, groupId) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getAssignmentsByGroup(groupId);
});

/// Provider for assignment detail
final assignmentDetailProvider = FutureProvider.family<AssignmentEntity?, String>((ref, assignmentId) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return await repository.getAssignmentById(assignmentId);
});
