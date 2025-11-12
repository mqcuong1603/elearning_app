import 'package:elearning_app/features/quiz/domain/entities/quiz_entity.dart';

/// Abstract repository interface for quiz operations
/// PDF Requirement: Quizzes with question bank and difficulty levels
abstract class QuizRepositoryInterface {
  /// Create a new quiz
  Future<bool> createQuiz(QuizEntity quiz);

  /// Get quiz by ID
  Future<QuizEntity?> getQuizById(String id);

  /// Get all quizzes for a course
  Future<List<QuizEntity>> getQuizzesByCourse(String courseId);

  /// Get quizzes for a specific group
  Future<List<QuizEntity>> getQuizzesByGroup(String groupId);

  /// Update a quiz
  Future<bool> updateQuiz(QuizEntity quiz);

  /// Delete a quiz
  Future<bool> deleteQuiz(String id);

  /// Get quiz count
  Future<int> getQuizCount({String? courseId});
}
