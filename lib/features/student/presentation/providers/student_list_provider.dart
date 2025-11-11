import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/student/domain/entities/student_entity.dart';
import 'package:elearning_app/features/student/presentation/providers/student_repository_provider.dart';

/// Provider for students by course (for People tab)
/// PDF Requirement: Lists groups and students enrolled in the course
final studentsByCourseProvider = FutureProvider.family<List<StudentEnrollmentEntity>, String>((ref, courseId) async {
  final repository = ref.watch(studentRepositoryProvider);
  return await repository.getStudentsByCourse(courseId);
});

/// Provider for students by group
final studentsByGroupProvider = FutureProvider.family<List<StudentEnrollmentEntity>, String>((ref, groupId) async {
  final repository = ref.watch(studentRepositoryProvider);
  return await repository.getStudentsByGroup(groupId);
});
