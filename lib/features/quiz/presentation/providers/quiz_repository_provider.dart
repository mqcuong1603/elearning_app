import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/quiz/data/repositories/quiz_repository.dart';
import 'package:elearning_app/features/quiz/domain/repositories/quiz_repository_interface.dart';

/// Provider for QuizRepository
final quizRepositoryProvider = Provider<QuizRepositoryInterface>((ref) {
  return QuizRepository();
});
