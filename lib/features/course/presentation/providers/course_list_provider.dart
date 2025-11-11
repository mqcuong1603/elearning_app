import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';

/// Provider for courses by semester
final coursesBySemesterProvider = FutureProvider.family<List<CourseEntity>, String?>((ref, semesterId) async {
  final repository = ref.watch(courseRepositoryProvider);

  if (semesterId == null) {
    return await repository.getAllCourses();
  }

  return await repository.getCoursesBySemester(semesterId);
});
