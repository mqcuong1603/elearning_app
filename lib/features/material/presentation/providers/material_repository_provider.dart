import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/material/data/repositories/material_repository.dart';
import 'package:elearning_app/features/material/domain/repositories/material_repository_interface.dart';

/// Provider for MaterialRepository
final materialRepositoryProvider = Provider<MaterialRepositoryInterface>((ref) {
  return MaterialRepository();
});
