import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/student/data/repositories/student_repository.dart';
import 'package:elearning_app/features/student/domain/repositories/student_repository_interface.dart';

/// Provider for StudentRepository
final studentRepositoryProvider = Provider<StudentRepositoryInterface>((ref) {
  return StudentRepository();
});
