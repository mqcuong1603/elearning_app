import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/assignment/data/repositories/assignment_repository.dart';
import 'package:elearning_app/features/assignment/domain/repositories/assignment_repository_interface.dart';

/// Provider for AssignmentRepository
final assignmentRepositoryProvider = Provider<AssignmentRepositoryInterface>((ref) {
  return AssignmentRepository();
});
