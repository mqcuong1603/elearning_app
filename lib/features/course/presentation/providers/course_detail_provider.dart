import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';

/// Provider for course details with counts
final courseDetailProvider = FutureProvider.family<CourseEntity?, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return await repository.getCourseByIdWithDetails(courseId);
});
