import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';
import 'package:elearning_app/features/auth/presentation/providers/current_user_provider.dart';

/// Provider for student's enrolled courses
/// PDF Requirement: "For students, the homepage displays enrolled courses as cards"
final enrolledCoursesProvider = FutureProvider.family<List<CourseEntity>, String?>((ref, semesterId) async {
  final repository = ref.watch(courseRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return [];
  }

  return await repository.getCoursesByStudent(currentUser.id, semesterId: semesterId);
});

/// Provider for courses by instructor
final coursesByInstructorProvider = FutureProvider.family<List<CourseEntity>, String>((ref, instructorId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return await repository.getCoursesByInstructor(instructorId);
});
