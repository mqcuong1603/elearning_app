import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import '../models/quiz_model.dart';
import '../models/quiz_submission_model.dart';
import '../models/question_model.dart';
import 'question_service.dart';
import 'notification_service.dart';

/// Service for managing quizzes with CRUD operations and random question selection
class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QuestionService _questionService = QuestionService();
  final _uuid = const Uuid();
  NotificationService? _notificationService;

  /// Set notification service for sending notifications
  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  /// Get quizzes collection reference
  CollectionReference get _quizzesCollection =>
      _firestore.collection(AppConstants.collectionQuizzes);

  /// Get quiz submissions collection reference
  CollectionReference get _submissionsCollection =>
      _firestore.collection(AppConstants.collectionQuizSubmissions);

  /// Create a new quiz
  Future<QuizModel> createQuiz({
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
      // Validate dates
      if (closeDate.isBefore(openDate)) {
        throw Exception('Close date must be after open date');
      }

      // Validate question structure
      if (questionStructure.isEmpty) {
        throw Exception('Question structure cannot be empty');
      }

      // Check if enough questions exist in the question bank
      final hasEnoughQuestions = await _questionService.validateQuizStructure(
        courseId: courseId,
        questionStructure: questionStructure,
      );

      if (!hasEnoughQuestions) {
        throw Exception(
            'Not enough questions in question bank for this structure');
      }

      final now = DateTime.now();
      final quiz = QuizModel(
        id: _uuid.v4(),
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
        createdAt: now,
        updatedAt: now,
      );

      await _quizzesCollection.doc(quiz.id).set(quiz.toJson());

      // Send notifications to students in assigned groups
      if (_notificationService != null) {
        try {
          // Get student IDs from groups
          final studentIds = await _getStudentIdsFromGroups(groupIds, courseId);

          if (studentIds.isNotEmpty) {
            await _notificationService!.createNotificationsForUsers(
              userIds: studentIds,
              type: AppConstants.notificationTypeQuiz,
              title: 'New Quiz Available: $title',
              message:
                  'A new quiz "$title" has been posted. Open date: ${openDate.toString().split('.')[0]}',
              relatedId: quiz.id,
              relatedType: 'quiz',
              data: {
                'courseId': courseId,
                'quizTitle': title,
                'openDate': openDate.toIso8601String(),
                'closeDate': closeDate.toIso8601String(),
              },
            );
          }
        } catch (e) {
          print('Failed to send quiz creation notifications: $e');
        }
      }

      return quiz;
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }

  /// Update an existing quiz
  Future<QuizModel> updateQuiz({
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
      final doc = await _quizzesCollection.doc(quizId).get();
      if (!doc.exists) {
        throw Exception('Quiz not found');
      }

      final currentQuiz =
          QuizModel.fromJson(doc.data() as Map<String, dynamic>);

      // Validate dates if both are provided
      final newOpenDate = openDate ?? currentQuiz.openDate;
      final newCloseDate = closeDate ?? currentQuiz.closeDate;
      if (newCloseDate.isBefore(newOpenDate)) {
        throw Exception('Close date must be after open date');
      }

      // Validate question structure if provided
      if (questionStructure != null) {
        final hasEnoughQuestions = await _questionService.validateQuizStructure(
          courseId: currentQuiz.courseId,
          questionStructure: questionStructure,
        );

        if (!hasEnoughQuestions) {
          throw Exception(
              'Not enough questions in question bank for this structure');
        }
      }

      final updatedQuiz = currentQuiz.copyWith(
        title: title,
        description: description,
        openDate: openDate,
        closeDate: closeDate,
        durationMinutes: durationMinutes,
        maxAttempts: maxAttempts,
        questionStructure: questionStructure,
        groupIds: groupIds,
        updatedAt: DateTime.now(),
      );

      await _quizzesCollection.doc(quizId).update(updatedQuiz.toJson());
      return updatedQuiz;
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      // Also delete all submissions for this quiz
      final submissions =
          await _submissionsCollection.where('quizId', isEqualTo: quizId).get();

      final batch = _firestore.batch();
      for (final doc in submissions.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_quizzesCollection.doc(quizId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }

  /// Get a single quiz by ID
  Future<QuizModel?> getQuiz(String quizId) async {
    try {
      final doc = await _quizzesCollection.doc(quizId).get();
      if (!doc.exists) {
        return null;
      }
      return QuizModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  /// Get all quizzes for a course
  Future<List<QuizModel>> getQuizzesForCourse(String courseId) async {
    try {
      final snapshot =
          await _quizzesCollection.where('courseId', isEqualTo: courseId).get();

      final quizzes = snapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort in memory to avoid requiring a composite index
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get quizzes: $e');
    }
  }

  /// Get available quizzes for a student (based on groups and availability)
  Future<List<QuizModel>> getAvailableQuizzesForStudent({
    required String courseId,
    required List<String> studentGroupIds,
  }) async {
    try {
      final allQuizzes = await getQuizzesForCourse(courseId);
      final now = DateTime.now();

      return allQuizzes.where((quiz) {
        // Check if quiz is available time-wise
        if (!quiz.isAvailable) return false;

        // Check if student's groups match quiz groups (or quiz is for all groups)
        if (quiz.isForAllGroups) return true;

        // Check if student is in any of the quiz's target groups
        return quiz.groupIds
            .any((groupId) => studentGroupIds.contains(groupId));
      }).toList();
    } catch (e) {
      throw Exception('Failed to get available quizzes: $e');
    }
  }

  /// Generate random questions for a quiz based on the question structure
  Future<List<QuestionModel>> generateQuizQuestions({
    required String courseId,
    required Map<String, int> questionStructure,
  }) async {
    try {
      final List<QuestionModel> selectedQuestions = [];

      for (final entry in questionStructure.entries) {
        final difficulty = entry.key;
        final count = entry.value;

        if (count > 0) {
          final questions =
              await _questionService.getRandomQuestionsByDifficulty(
            courseId: courseId,
            difficulty: difficulty,
            count: count,
          );
          selectedQuestions.addAll(questions);
        }
      }

      // Shuffle the final list so questions aren't grouped by difficulty
      selectedQuestions.shuffle();
      return selectedQuestions;
    } catch (e) {
      throw Exception('Failed to generate quiz questions: $e');
    }
  }

  /// Submit a quiz
  Future<QuizSubmissionModel> submitQuiz({
    required String quizId,
    required String studentId,
    required String studentName,
    required List<QuizAnswerModel> answers,
    required DateTime startedAt,
    required List<QuestionModel> questions,
  }) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz == null) {
        throw Exception('Quiz not found');
      }

      // Check if quiz is still available
      if (!quiz.isAvailable) {
        throw Exception('Quiz is no longer available');
      }

      // Get student's attempt count
      final attemptNumber = await getStudentAttemptCount(
            quizId: quizId,
            studentId: studentId,
          ) +
          1;

      // Check if student has attempts left
      if (attemptNumber > quiz.maxAttempts) {
        throw Exception('Maximum attempts reached');
      }

      // Grade the answers
      final gradedAnswers = <QuizAnswerModel>[];
      for (final answer in answers) {
        final question = questions.firstWhere((q) => q.id == answer.questionId);
        final isCorrect = question.isChoiceCorrect(answer.selectedChoiceId);
        gradedAnswers.add(QuizAnswerModel(
          questionId: answer.questionId,
          selectedChoiceId: answer.selectedChoiceId,
          isCorrect: isCorrect,
        ));
      }

      // Calculate score
      final correctCount = gradedAnswers.where((a) => a.isCorrect).length;
      final score = (correctCount / gradedAnswers.length) * 100;

      // Calculate duration
      final submittedAt = DateTime.now();
      final durationSeconds = submittedAt.difference(startedAt).inSeconds;

      final submission = QuizSubmissionModel(
        id: _uuid.v4(),
        quizId: quizId,
        studentId: studentId,
        studentName: studentName,
        answers: gradedAnswers,
        score: score,
        submittedAt: submittedAt,
        attemptNumber: attemptNumber,
        startedAt: startedAt,
        durationSeconds: durationSeconds,
      );

      await _submissionsCollection.doc(submission.id).set(submission.toJson());

      // Send notification to student confirming submission
      if (_notificationService != null) {
        try {
          await _notificationService!.createNotification(
            userId: studentId,
            type: AppConstants.notificationTypeQuiz,
            title: 'Quiz Submitted Successfully',
            message:
                'Your quiz submission for "${quiz.title}" has been received. Score: ${score.toStringAsFixed(1)}%',
            relatedId: quizId,
            relatedType: 'quiz',
            data: {
              'quizTitle': quiz.title,
              'score': score,
              'attemptNumber': attemptNumber,
              'submittedAt': submittedAt.toIso8601String(),
            },
          );
        } catch (e) {
          print('Failed to send quiz submission notification: $e');
        }
      }

      return submission;
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  /// Get student's attempt count for a quiz
  Future<int> getStudentAttemptCount({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final snapshot = await _submissionsCollection
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get attempt count: $e');
    }
  }

  /// Get student's submissions for a quiz
  Future<List<QuizSubmissionModel>> getStudentSubmissions({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final snapshot = await _submissionsCollection
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .get();

      final submissions = snapshot.docs
          .map((doc) =>
              QuizSubmissionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort in memory to avoid requiring a composite index
      submissions.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));

      return submissions;
    } catch (e) {
      throw Exception('Failed to get student submissions: $e');
    }
  }

  /// Get best submission for a student
  Future<QuizSubmissionModel?> getBestSubmission({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final submissions = await getStudentSubmissions(
        quizId: quizId,
        studentId: studentId,
      );

      if (submissions.isEmpty) return null;

      // Sort by score descending
      submissions.sort((a, b) => b.score.compareTo(a.score));
      return submissions.first;
    } catch (e) {
      throw Exception('Failed to get best submission: $e');
    }
  }

  /// Get all submissions for a quiz (for instructor)
  Future<List<QuizSubmissionModel>> getAllSubmissionsForQuiz(
      String quizId) async {
    try {
      final snapshot =
          await _submissionsCollection.where('quizId', isEqualTo: quizId).get();

      final submissions = snapshot.docs
          .map((doc) =>
              QuizSubmissionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort in memory to avoid requiring a composite index
      submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      return submissions;
    } catch (e) {
      throw Exception('Failed to get quiz submissions: $e');
    }
  }

  /// Get quiz statistics
  Future<Map<String, dynamic>> getQuizStatistics(String quizId) async {
    try {
      final submissions = await getAllSubmissionsForQuiz(quizId);

      if (submissions.isEmpty) {
        return {
          'totalSubmissions': 0,
          'uniqueStudents': 0,
          'averageScore': 0.0,
          'highestScore': 0.0,
          'lowestScore': 0.0,
          'passRate': 0.0,
        };
      }

      // Get unique students
      final uniqueStudents = submissions.map((s) => s.studentId).toSet();

      // Get best submission for each student
      final bestSubmissions = <QuizSubmissionModel>[];
      for (final studentId in uniqueStudents) {
        final studentSubs =
            submissions.where((s) => s.studentId == studentId).toList();
        studentSubs.sort((a, b) => b.score.compareTo(a.score));
        bestSubmissions.add(studentSubs.first);
      }

      // Calculate statistics based on best submissions
      final scores = bestSubmissions.map((s) => s.score).toList();
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;
      final highestScore = scores.reduce((a, b) => a > b ? a : b);
      final lowestScore = scores.reduce((a, b) => a < b ? a : b);
      final passCount = scores.where((s) => s >= 50).length;
      final passRate = (passCount / scores.length) * 100;

      return {
        'totalSubmissions': submissions.length,
        'uniqueStudents': uniqueStudents.length,
        'averageScore': averageScore,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'passRate': passRate,
      };
    } catch (e) {
      throw Exception('Failed to get quiz statistics: $e');
    }
  }

  /// Check if student can take quiz
  Future<Map<String, dynamic>> canStudentTakeQuiz({
    required String quizId,
    required String studentId,
    required List<String> studentGroupIds,
  }) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz == null) {
        return {'canTake': false, 'reason': 'Quiz not found'};
      }

      // Check if quiz is available
      if (quiz.isUpcoming) {
        return {'canTake': false, 'reason': 'Quiz has not opened yet'};
      }

      if (quiz.isClosed) {
        return {'canTake': false, 'reason': 'Quiz is closed'};
      }

      // Check if student is in the right group
      if (!quiz.isForAllGroups) {
        final hasAccess =
            quiz.groupIds.any((groupId) => studentGroupIds.contains(groupId));
        if (!hasAccess) {
          return {
            'canTake': false,
            'reason': 'You are not in a group assigned to this quiz'
          };
        }
      }

      // Check attempts
      final attemptCount = await getStudentAttemptCount(
        quizId: quizId,
        studentId: studentId,
      );

      if (attemptCount >= quiz.maxAttempts) {
        return {
          'canTake': false,
          'reason': 'Maximum attempts reached (${quiz.maxAttempts})'
        };
      }

      return {
        'canTake': true,
        'attemptsLeft': quiz.maxAttempts - attemptCount,
        'attemptNumber': attemptCount + 1,
      };
    } catch (e) {
      return {'canTake': false, 'reason': 'Error checking quiz availability'};
    }
  }

  /// Stream quizzes for a course (real-time updates)
  Stream<List<QuizModel>> streamQuizzesForCourse(String courseId) {
    return _firestore
        .collection(AppConstants.collectionQuizzes)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
      final quizzes =
          snapshot.docs.map((doc) => QuizModel.fromJson(doc.data())).toList();

      // Sort in memory to avoid requiring a composite index
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return quizzes;
    });
  }

  /// Get student IDs from group IDs
  Future<List<String>> _getStudentIdsFromGroups(List<String> groupIds, String courseId) async {
    try {
      final Set<String> studentIds = {};

      // Determine which groups to notify
      List<String> targetGroupIds = groupIds;

      // If groupIds is empty, it means "All Groups" - fetch all groups for this course
      if (groupIds.isEmpty) {
        final groupsSnapshot = await _firestore
            .collection(AppConstants.collectionGroups)
            .where('courseId', isEqualTo: courseId)
            .get();
        targetGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();
      }

      for (final groupId in targetGroupIds) {
        final groupDoc = await _firestore
            .collection(AppConstants.collectionGroups)
            .doc(groupId)
            .get();

        if (groupDoc.exists) {
          final groupData = groupDoc.data() as Map<String, dynamic>;
          final List<dynamic> students = groupData['studentIds'] ?? [];
          studentIds.addAll(students.cast<String>());
        }
      }

      return studentIds.toList();
    } catch (e) {
      print('Error getting student IDs from groups: $e');
      return [];
    }
  }
}
