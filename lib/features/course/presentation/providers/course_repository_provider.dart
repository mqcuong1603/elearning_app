import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/course/data/repositories/course_repository.dart';
import 'package:elearning_app/features/course/domain/repositories/course_repository_interface.dart';

/// Provider for CourseRepository
final courseRepositoryProvider = Provider<CourseRepositoryInterface>((ref) {
  return CourseRepository();
});
