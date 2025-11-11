import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/group/data/repositories/group_repository.dart';
import 'package:elearning_app/features/group/domain/repositories/group_repository_interface.dart';

/// Provider for GroupRepository
final groupRepositoryProvider = Provider<GroupRepositoryInterface>((ref) {
  return GroupRepository();
});
