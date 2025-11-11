import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';

/// Provider for current semester
/// PDF Requirement: "By default, the system loads the current (latest) semester"
final currentSemesterProvider = FutureProvider<SemesterEntity?>((ref) async {
  final repository = ref.watch(semesterRepositoryProvider);
  return await repository.getCurrentSemester();
});

/// State notifier for managing selected semester (allows switching)
class SelectedSemesterNotifier extends Notifier<SemesterEntity?> {
  @override
  SemesterEntity? build() => null;

  void selectSemester(SemesterEntity? semester) {
    state = semester;
  }

  void clearSelection() {
    state = null;
  }
}

/// Provider for selected semester (user can switch semesters)
final selectedSemesterProvider = NotifierProvider<SelectedSemesterNotifier, SemesterEntity?>(SelectedSemesterNotifier.new);

/// Provider that returns either selected semester or current semester
/// This is what UI components should use
final activeSemesterProvider = Provider<AsyncValue<SemesterEntity?>>((ref) {
  final selected = ref.watch(selectedSemesterProvider);

  if (selected != null) {
    return AsyncValue.data(selected);
  }

  // Fall back to current semester
  return ref.watch(currentSemesterProvider);
});
