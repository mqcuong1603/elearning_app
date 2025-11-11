import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/domain/repositories/semester_repository_interface.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';

/// Provider for all semesters
final allSemestersProvider = FutureProvider<List<SemesterEntity>>((ref) async {
  final repository = ref.watch(semesterRepositoryProvider);
  return await repository.getAllSemesters();
});

/// Provider for past semesters (read-only)
final pastSemestersProvider = FutureProvider<List<SemesterEntity>>((ref) async {
  final repository = ref.watch(semesterRepositoryProvider);
  return await repository.getPastSemesters();
});

/// Provider for active semesters
final activeSemestersProvider = FutureProvider<List<SemesterEntity>>((ref) async {
  final repository = ref.watch(semesterRepositoryProvider);
  return await repository.getActiveSemesters();
});

/// Provider for future semesters
final futureSemestersProvider = FutureProvider<List<SemesterEntity>>((ref) async {
  final repository = ref.watch(semesterRepositoryProvider);
  return await repository.getFutureSemesters();
});

/// State notifier for semester CRUD operations
class SemesterListNotifier extends AsyncNotifier<List<SemesterEntity>> {
  late final SemesterRepositoryInterface _repository;

  @override
  Future<List<SemesterEntity>> build() async {
    _repository = ref.read(semesterRepositoryProvider);
    return await _repository.getAllSemesters();
  }

  Future<void> loadSemesters() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getAllSemesters();
    });
  }

  Future<bool> createSemester(SemesterEntity semester) async {
    final success = await _repository.createSemester(semester);
    if (success) {
      await loadSemesters(); // Refresh list
    }
    return success;
  }

  Future<bool> updateSemester(SemesterEntity semester) async {
    final success = await _repository.updateSemester(semester);
    if (success) {
      await loadSemesters(); // Refresh list
    }
    return success;
  }

  Future<bool> deleteSemester(String id) async {
    final success = await _repository.deleteSemester(id);
    if (success) {
      await loadSemesters(); // Refresh list
    }
    return success;
  }

  Future<bool> setCurrentSemester(String semesterId) async {
    final success = await _repository.setCurrentSemester(semesterId);
    if (success) {
      await loadSemesters(); // Refresh list
    }
    return success;
  }

  Future<List<String>> importFromCSV(List<SemesterEntity> semesters) async {
    final results = await _repository.insertBatch(semesters);
    await loadSemesters(); // Refresh list
    return results;
  }
}

/// Provider for semester list with CRUD operations
final semesterListNotifierProvider = AsyncNotifierProvider<SemesterListNotifier, List<SemesterEntity>>(SemesterListNotifier.new);
