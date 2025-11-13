import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/quiz_submission_model.dart';
import '../services/quiz_service.dart';
import '../services/question_service.dart';

/// Provider for managing quiz state and operations
class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final QuestionService _questionService = QuestionService();

  // Quiz state
  List<QuizModel> _quizzes = [];
  QuizModel? _selectedQuiz;
  bool _isLoadingQuizzes = false;
  String? _quizError;

  // Question state
  List<QuestionModel> _questions = [];
  List<QuestionModel> _quizQuestions = []; // Questions for active quiz
  bool _isLoadingQuestions = false;
  String? _questionError;

  // Quiz taking state
  bool _isQuizActive = false;
  DateTime? _quizStartTime;
  Map<String, String> _selectedAnswers = {}; // questionId -> choiceId
  int _timeRemainingSeconds = 0;

  // Submission state
  List<QuizSubmissionModel> _submissions = [];
  QuizSubmissionModel? _currentSubmission;
  bool _isLoadingSubmissions = false;
  String? _submissionError;

  // Statistics
  Map<String, dynamic>? _quizStatistics;
  Map<String, dynamic>? _questionStatistics;

  // Getters
  List<QuizModel> get quizzes => _quizzes;
  QuizModel? get selectedQuiz => _selectedQuiz;
  bool get isLoadingQuizzes => _isLoadingQuizzes;
  String? get quizError => _quizError;

  List<QuestionModel> get questions => _questions;
  List<QuestionModel> get quizQuestions => _quizQuestions;
  bool get isLoadingQuestions => _isLoadingQuestions;
  String? get questionError => _questionError;

  bool get isQuizActive => _isQuizActive;
  DateTime? get quizStartTime => _quizStartTime;
  Map<String, String> get selectedAnswers => _selectedAnswers;
  int get timeRemainingSeconds => _timeRemainingSeconds;

  List<QuizSubmissionModel> get submissions => _submissions;
  QuizSubmissionModel? get currentSubmission => _currentSubmission;
  bool get isLoadingSubmissions => _isLoadingSubmissions;
  String? get submissionError => _submissionError;

  Map<String, dynamic>? get quizStatistics => _quizStatistics;
  Map<String, dynamic>? get questionStatistics => _questionStatistics;

  // Computed properties
  int get answeredQuestionsCount => _selectedAnswers.length;
  int get totalQuestionsCount => _quizQuestions.length;
  bool get isQuizCompleted =>
      answeredQuestionsCount == totalQuestionsCount && totalQuestionsCount > 0;
  double get progressPercentage =>
      totalQuestionsCount > 0
          ? (answeredQuestionsCount / totalQuestionsCount) * 100
          : 0;

  /// Load quizzes for a course
  Future<void> loadQuizzesForCourse(String courseId) async {
    _isLoadingQuizzes = true;
    _quizError = null;
    notifyListeners();

    try {
      _quizzes = await _quizService.getQuizzesForCourse(courseId);
      _isLoadingQuizzes = false;
      notifyListeners();
    } catch (e) {
      _quizError = e.toString();
      _isLoadingQuizzes = false;
      notifyListeners();
    }
  }

  /// Load available quizzes for a student
  Future<void> loadAvailableQuizzes({
    required String courseId,
    required List<String> studentGroupIds,
  }) async {
    _isLoadingQuizzes = true;
    _quizError = null;
    notifyListeners();

    try {
      _quizzes = await _quizService.getAvailableQuizzesForStudent(
        courseId: courseId,
        studentGroupIds: studentGroupIds,
      );
      _isLoadingQuizzes = false;
      notifyListeners();
    } catch (e) {
      _quizError = e.toString();
      _isLoadingQuizzes = false;
      notifyListeners();
    }
  }

  /// Create a new quiz
  Future<bool> createQuiz({
    required String courseId,
    required String title,
    required String description,
    required DateTime openDate,
    required DateTime closeDate,
    required int durationMinutes,
    required int maxAttempts,
    required Map<String, int> questionStructure,
    required List<String> groupIds,
    required String instructorId,
    required String instructorName,
  }) async {
    try {
      final quiz = await _quizService.createQuiz(
        courseId: courseId,
        title: title,
        description: description,
        openDate: openDate,
        closeDate: closeDate,
        durationMinutes: durationMinutes,
        maxAttempts: maxAttempts,
        questionStructure: questionStructure,
        groupIds: groupIds,
        instructorId: instructorId,
        instructorName: instructorName,
      );

      _quizzes.insert(0, quiz);
      notifyListeners();
      return true;
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a quiz
  Future<bool> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    DateTime? openDate,
    DateTime? closeDate,
    int? durationMinutes,
    int? maxAttempts,
    Map<String, int>? questionStructure,
    List<String>? groupIds,
  }) async {
    try {
      final updatedQuiz = await _quizService.updateQuiz(
        quizId: quizId,
        title: title,
        description: description,
        openDate: openDate,
        closeDate: closeDate,
        durationMinutes: durationMinutes,
        maxAttempts: maxAttempts,
        questionStructure: questionStructure,
        groupIds: groupIds,
      );

      final index = _quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
      }

      if (_selectedQuiz?.id == quizId) {
        _selectedQuiz = updatedQuiz;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _quizService.deleteQuiz(quizId);
      _quizzes.removeWhere((q) => q.id == quizId);

      if (_selectedQuiz?.id == quizId) {
        _selectedQuiz = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Select a quiz
  Future<void> selectQuiz(String quizId) async {
    try {
      _selectedQuiz = await _quizService.getQuiz(quizId);
      notifyListeners();
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
    }
  }

  /// Load questions for a course
  Future<void> loadQuestions(String courseId) async {
    _isLoadingQuestions = true;
    _questionError = null;
    notifyListeners();

    try {
      _questions = await _questionService.getQuestionsForCourse(courseId);
      _isLoadingQuestions = false;
      notifyListeners();
    } catch (e) {
      _questionError = e.toString();
      _isLoadingQuestions = false;
      notifyListeners();
    }
  }

  /// Create a new question
  Future<bool> createQuestion({
    required String courseId,
    required String questionText,
    required List<ChoiceModel> choices,
    required String difficulty,
  }) async {
    try {
      final question = await _questionService.createQuestion(
        courseId: courseId,
        questionText: questionText,
        choices: choices,
        difficulty: difficulty,
      );

      _questions.insert(0, question);
      notifyListeners();
      return true;
    } catch (e) {
      _questionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a question
  Future<bool> updateQuestion({
    required String questionId,
    String? questionText,
    List<ChoiceModel>? choices,
    String? difficulty,
  }) async {
    try {
      final updatedQuestion = await _questionService.updateQuestion(
        questionId: questionId,
        questionText: questionText,
        choices: choices,
        difficulty: difficulty,
      );

      final index = _questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        _questions[index] = updatedQuestion;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _questionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _questionService.deleteQuestion(questionId);
      _questions.removeWhere((q) => q.id == questionId);
      notifyListeners();
      return true;
    } catch (e) {
      _questionError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load question statistics
  Future<void> loadQuestionStatistics(String courseId) async {
    try {
      _questionStatistics =
          await _questionService.getQuestionStatistics(courseId);
      notifyListeners();
    } catch (e) {
      _questionError = e.toString();
      notifyListeners();
    }
  }

  /// Start a quiz (generate questions and start timer)
  Future<bool> startQuiz(String quizId, String courseId) async {
    try {
      final quiz = await _quizService.getQuiz(quizId);
      if (quiz == null) {
        throw Exception('Quiz not found');
      }

      // Generate random questions
      _quizQuestions = await _quizService.generateQuizQuestions(
        courseId: courseId,
        questionStructure: quiz.questionStructure,
      );

      _selectedQuiz = quiz;
      _isQuizActive = true;
      _quizStartTime = DateTime.now();
      _selectedAnswers = {};
      _timeRemainingSeconds = quiz.durationMinutes * 60;

      notifyListeners();
      return true;
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Select an answer for a question
  void selectAnswer(String questionId, String choiceId) {
    _selectedAnswers[questionId] = choiceId;
    notifyListeners();
  }

  /// Update time remaining
  void updateTimeRemaining(int seconds) {
    _timeRemainingSeconds = seconds;
    notifyListeners();
  }

  /// Submit the quiz
  Future<bool> submitQuiz({
    required String studentId,
    required String studentName,
  }) async {
    if (_selectedQuiz == null || _quizStartTime == null) {
      _submissionError = 'No active quiz';
      notifyListeners();
      return false;
    }

    try {
      // Convert selected answers to QuizAnswerModel list
      final answers = _selectedAnswers.entries
          .map((entry) => QuizAnswerModel(
                questionId: entry.key,
                selectedChoiceId: entry.value,
                isCorrect: false, // Will be graded by service
              ))
          .toList();

      // Submit to service and get result
      final submission = await _quizService.submitQuiz(
        quizId: _selectedQuiz!.id,
        studentId: studentId,
        studentName: studentName,
        answers: answers,
        startedAt: _quizStartTime!,
        questions: _quizQuestions,
      );

      // Verify submission was created
      if (submission == null) {
        throw Exception('Failed to create quiz submission');
      }

      // Set current submission before resetting state
      _currentSubmission = submission;

      // Reset quiz state (but keep currentSubmission)
      _isQuizActive = false;
      _quizStartTime = null;
      _selectedAnswers = {};
      _quizQuestions = [];
      _timeRemainingSeconds = 0;
      _submissionError = null; // Clear any previous errors

      notifyListeners();
      return true;
    } catch (e) {
      _submissionError = e.toString();
      _currentSubmission = null; // Clear submission on error
      notifyListeners();
      return false;
    }
  }

  /// Cancel/exit quiz
  void cancelQuiz() {
    _isQuizActive = false;
    _quizStartTime = null;
    _selectedAnswers = {};
    _quizQuestions = [];
    _timeRemainingSeconds = 0;
    _currentSubmission = null; // Clear submission when canceling
    notifyListeners();
  }

  /// Load student submissions for a quiz
  Future<void> loadStudentSubmissions({
    required String quizId,
    required String studentId,
  }) async {
    _isLoadingSubmissions = true;
    _submissionError = null;
    notifyListeners();

    try {
      _submissions = await _quizService.getStudentSubmissions(
        quizId: quizId,
        studentId: studentId,
      );
      _isLoadingSubmissions = false;
      notifyListeners();
    } catch (e) {
      _submissionError = e.toString();
      _isLoadingSubmissions = false;
      notifyListeners();
    }
  }

  /// Load all submissions for a quiz (instructor view)
  Future<void> loadAllSubmissions(String quizId) async {
    _isLoadingSubmissions = true;
    _submissionError = null;
    notifyListeners();

    try {
      _submissions = await _quizService.getAllSubmissionsForQuiz(quizId);
      _isLoadingSubmissions = false;
      notifyListeners();
    } catch (e) {
      _submissionError = e.toString();
      _isLoadingSubmissions = false;
      notifyListeners();
    }
  }

  /// Load quiz statistics
  Future<void> loadQuizStatistics(String quizId) async {
    try {
      _quizStatistics = await _quizService.getQuizStatistics(quizId);
      notifyListeners();
    } catch (e) {
      _quizError = e.toString();
      notifyListeners();
    }
  }

  /// Check if student can take quiz
  Future<Map<String, dynamic>> checkQuizEligibility({
    required String quizId,
    required String studentId,
    required List<String> studentGroupIds,
  }) async {
    try {
      return await _quizService.canStudentTakeQuiz(
        quizId: quizId,
        studentId: studentId,
        studentGroupIds: studentGroupIds,
      );
    } catch (e) {
      return {'canTake': false, 'reason': 'Error checking eligibility'};
    }
  }

  /// Get attempt count for student
  Future<int> getAttemptCount({
    required String quizId,
    required String studentId,
  }) async {
    try {
      return await _quizService.getStudentAttemptCount(
        quizId: quizId,
        studentId: studentId,
      );
    } catch (e) {
      return 0;
    }
  }

  /// Clear errors
  void clearErrors() {
    _quizError = null;
    _questionError = null;
    _submissionError = null;
    notifyListeners();
  }

  /// Reset provider
  void reset() {
    _quizzes = [];
    _selectedQuiz = null;
    _questions = [];
    _quizQuestions = [];
    _isQuizActive = false;
    _quizStartTime = null;
    _selectedAnswers = {};
    _timeRemainingSeconds = 0;
    _submissions = [];
    _currentSubmission = null;
    _quizStatistics = null;
    _questionStatistics = null;
    clearErrors();
    notifyListeners();
  }
}
