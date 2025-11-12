import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/quiz/domain/entities/quiz_entity.dart';
import 'package:elearning_app/features/quiz/presentation/providers/quiz_repository_provider.dart';

/// Provider for quizzes by course
final quizzesByCourseProvider = FutureProvider.family<List<QuizEntity>, String>((ref, courseId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return await repository.getQuizzesByCourse(courseId);
});

/// Provider for quizzes by group
final quizzesByGroupProvider = FutureProvider.family<List<QuizEntity>, String>((ref, groupId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return await repository.getQuizzesByGroup(groupId);
});

/// Provider for quiz detail
final quizDetailProvider = FutureProvider.family<QuizEntity?, String>((ref, quizId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return await repository.getQuizById(quizId);
});
