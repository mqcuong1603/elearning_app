import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/semester/data/repositories/semester_repository.dart';
import 'package:elearning_app/features/semester/domain/repositories/semester_repository_interface.dart';

/// Provider for SemesterRepository
final semesterRepositoryProvider = Provider<SemesterRepositoryInterface>((ref) {
  return SemesterRepository();
});
