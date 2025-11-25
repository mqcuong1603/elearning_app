import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import '../models/question_model.dart';

/// Service for managing quiz questions with difficulty tagging
class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Get questions collection reference
  CollectionReference get _questionsCollection =>
      _firestore.collection(AppConstants.collectionQuestions);

  /// Create a new question
  Future<QuestionModel> createQuestion({
    required String courseId,
    required String questionText,
    required List<ChoiceModel> choices,
    required String difficulty,
  }) async {
    try {
      // Validate question
      if (choices.length < 2) {
        throw Exception('Question must have at least 2 choices');
      }

      final correctChoices = choices.where((c) => c.isCorrect).length;
      if (correctChoices != 1) {
        throw Exception('Question must have exactly 1 correct answer');
      }

      if (!['easy', 'medium', 'hard'].contains(difficulty)) {
        throw Exception('Invalid difficulty level');
      }

      final now = DateTime.now();
      final question = QuestionModel(
        id: _uuid.v4(),
        courseId: courseId,
        questionText: questionText,
        choices: choices,
        difficulty: difficulty,
        createdAt: now,
        updatedAt: now,
      );

      await _questionsCollection.doc(question.id).set(question.toJson());
      return question;
    } catch (e) {
      throw Exception('Failed to create question: $e');
    }
  }

  /// Update an existing question
  Future<QuestionModel> updateQuestion({
    required String questionId,
    String? questionText,
    List<ChoiceModel>? choices,
    String? difficulty,
  }) async {
    try {
      final doc = await _questionsCollection.doc(questionId).get();
      if (!doc.exists) {
        throw Exception('Question not found');
      }

      final currentQuestion =
          QuestionModel.fromJson(doc.data() as Map<String, dynamic>);

      // Validate choices if provided
      if (choices != null) {
        if (choices.length < 2) {
          throw Exception('Question must have at least 2 choices');
        }
        final correctChoices = choices.where((c) => c.isCorrect).length;
        if (correctChoices != 1) {
          throw Exception('Question must have exactly 1 correct answer');
        }
      }

      // Validate difficulty if provided
      if (difficulty != null &&
          !['easy', 'medium', 'hard'].contains(difficulty)) {
        throw Exception('Invalid difficulty level');
      }

      final updatedQuestion = currentQuestion.copyWith(
        questionText: questionText,
        choices: choices,
        difficulty: difficulty,
        updatedAt: DateTime.now(),
      );

      await _questionsCollection
          .doc(questionId)
          .update(updatedQuestion.toJson());
      return updatedQuestion;
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _questionsCollection.doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  /// Get a single question by ID
  Future<QuestionModel?> getQuestion(String questionId) async {
    try {
      final doc = await _questionsCollection.doc(questionId).get();
      if (!doc.exists) {
        return null;
      }
      return QuestionModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get question: $e');
    }
  }

  /// Get all questions for a course
  Future<List<QuestionModel>> getQuestionsForCourse(String courseId) async {
    try {
      final snapshot = await _questionsCollection
          .where('courseId', isEqualTo: courseId)
          .get();

      final questions = snapshot.docs
          .map((doc) =>
              QuestionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort in memory to avoid requiring a composite index
      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return questions;
    } catch (e) {
      throw Exception('Failed to get questions: $e');
    }
  }

  /// Get questions by difficulty for a course
  Future<List<QuestionModel>> getQuestionsByDifficulty({
    required String courseId,
    required String difficulty,
  }) async {
    try {
      final snapshot = await _questionsCollection
          .where('courseId', isEqualTo: courseId)
          .where('difficulty', isEqualTo: difficulty)
          .get();

      return snapshot.docs
          .map((doc) =>
              QuestionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions by difficulty: $e');
    }
  }

  /// Get random questions by difficulty
  /// Returns a list of random questions based on the difficulty and count
  Future<List<QuestionModel>> getRandomQuestionsByDifficulty({
    required String courseId,
    required String difficulty,
    required int count,
  }) async {
    try {
      final allQuestions = await getQuestionsByDifficulty(
        courseId: courseId,
        difficulty: difficulty,
      );

      if (allQuestions.length < count) {
        throw Exception(
            'Not enough $difficulty questions available. Need $count, have ${allQuestions.length}');
      }

      // Shuffle and take the required count
      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Failed to get random questions: $e');
    }
  }

  /// Get question statistics for a course
  Future<Map<String, dynamic>> getQuestionStatistics(String courseId) async {
    try {
      final questions = await getQuestionsForCourse(courseId);

      final easyCount =
          questions.where((q) => q.difficulty == 'easy').length;
      final mediumCount =
          questions.where((q) => q.difficulty == 'medium').length;
      final hardCount =
          questions.where((q) => q.difficulty == 'hard').length;

      return {
        'total': questions.length,
        'easy': easyCount,
        'medium': mediumCount,
        'hard': hardCount,
      };
    } catch (e) {
      throw Exception('Failed to get question statistics: $e');
    }
  }

  /// Validate if enough questions exist for a quiz structure
  Future<bool> validateQuizStructure({
    required String courseId,
    required Map<String, int> questionStructure,
  }) async {
    try {
      for (final entry in questionStructure.entries) {
        final difficulty = entry.key;
        final requiredCount = entry.value;

        final availableQuestions = await getQuestionsByDifficulty(
          courseId: courseId,
          difficulty: difficulty,
        );

        if (availableQuestions.length < requiredCount) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Bulk import questions
  Future<List<QuestionModel>> bulkImportQuestions({
    required String courseId,
    required List<Map<String, dynamic>> questionsData,
  }) async {
    try {
      final List<QuestionModel> importedQuestions = [];

      for (final data in questionsData) {
        final question = await createQuestion(
          courseId: courseId,
          questionText: data['questionText'] as String,
          choices: (data['choices'] as List<dynamic>)
              .map((c) => ChoiceModel.fromJson(c as Map<String, dynamic>))
              .toList(),
          difficulty: data['difficulty'] as String,
        );
        importedQuestions.add(question);
      }

      return importedQuestions;
    } catch (e) {
      throw Exception('Failed to bulk import questions: $e');
    }
  }

  /// Search questions by text
  Future<List<QuestionModel>> searchQuestions({
    required String courseId,
    required String searchText,
  }) async {
    try {
      final allQuestions = await getQuestionsForCourse(courseId);
      final searchLower = searchText.toLowerCase();

      return allQuestions
          .where((q) => q.questionText.toLowerCase().contains(searchLower))
          .toList();
    } catch (e) {
      throw Exception('Failed to search questions: $e');
    }
  }

  /// Create sample choices for testing
  static List<ChoiceModel> createSampleChoices({
    required List<String> options,
    required int correctIndex,
  }) {
    return List.generate(
      options.length,
      (index) => ChoiceModel(
        id: const Uuid().v4(),
        text: options[index],
        isCorrect: index == correctIndex,
      ),
    );
  }
}
