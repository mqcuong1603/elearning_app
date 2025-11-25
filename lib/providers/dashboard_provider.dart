// import 'package:flutter/foundation.dart';
// import '../models/assignment_model.dart';
// import '../models/quiz_model.dart';
// import '../models/assignment_submission_model.dart';
// import '../models/quiz_submission_model.dart';
// import '../services/assignment_service.dart';
// import '../services/quiz_service.dart';

// /// Dashboard Provider
// /// Manages comprehensive learning progress data for student dashboard
// class DashboardProvider with ChangeNotifier {
//   final AssignmentService _assignmentService;
//   final QuizService _quizService;

//   // Assignment data
//   List<AssignmentModel> _allAssignments = [];
//   Map<String, AssignmentSubmissionModel?> _latestSubmissions = {};

//   // Quiz data
//   List<QuizModel> _allQuizzes = [];
//   Map<String, List<QuizSubmissionModel>> _quizSubmissions = {};

//   // Loading states
//   bool _isLoadingAssignments = false;
//   bool _isLoadingQuizzes = false;
//   final bool _isLoadingSubmissions = false;

//   // Error states
//   String? _error;

//   DashboardProvider({
//     required AssignmentService assignmentService,
//     required QuizService quizService,
//   })  : _assignmentService = assignmentService,
//         _quizService = quizService;

//   // Getters
//   List<AssignmentModel> get allAssignments => _allAssignments;
//   List<QuizModel> get allQuizzes => _allQuizzes;
//   bool get isLoading =>
//       _isLoadingAssignments || _isLoadingQuizzes || _isLoadingSubmissions;
//   String? get error => _error;

//   // ==================== ASSIGNMENT PROGRESS ====================

//   /// Get submitted assignments (assignments where student has submitted)
//   List<AssignmentModel> getSubmittedAssignments() {
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission != null;
//     }).toList();
//   }

//   /// Get pending assignments (open assignments without submission)
//   List<AssignmentModel> getPendingAssignments() {
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission == null && assignment.isOpen;
//     }).toList();
//   }

//   /// Get late submissions
//   List<AssignmentModel> getLateAssignments() {
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission != null && submission.isLate;
//     }).toList();
//   }

//   /// Get graded assignments
//   List<AssignmentModel> getGradedAssignments() {
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission != null && submission.isGraded;
//     }).toList();
//   }

//   /// Get ungraded assignments (submitted but not graded)
//   List<AssignmentModel> getUngradedAssignments() {
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission != null && !submission.isGraded;
//     }).toList();
//   }

//   /// Get submission for an assignment
//   AssignmentSubmissionModel? getSubmission(String assignmentId) {
//     return _latestSubmissions[assignmentId];
//   }

//   /// Get average assignment grade
//   double? getAverageAssignmentGrade() {
//     final gradedSubmissions = _latestSubmissions.values
//         .where((s) => s != null && s.isGraded)
//         .toList();

//     if (gradedSubmissions.isEmpty) return null;

//     final total = gradedSubmissions.fold<double>(
//       0,
//       (sum, submission) => sum + (submission?.grade ?? 0),
//     );

//     return total / gradedSubmissions.length;
//   }

//   // ==================== QUIZ PROGRESS ====================

//   /// Get completed quizzes (quizzes where student has at least one submission)
//   List<QuizModel> getCompletedQuizzes() {
//     return _allQuizzes.where((quiz) {
//       final submissions = _quizSubmissions[quiz.id] ?? [];
//       return submissions.isNotEmpty;
//     }).toList();
//   }

//   /// Get pending quizzes (available quizzes without submission)
//   List<QuizModel> getPendingQuizzes() {
//     return _allQuizzes.where((quiz) {
//       final submissions = _quizSubmissions[quiz.id] ?? [];
//       return submissions.isEmpty && quiz.isAvailable;
//     }).toList();
//   }

//   /// Get quiz submissions for a quiz
//   List<QuizSubmissionModel> getQuizSubmissions(String quizId) {
//     return _quizSubmissions[quizId] ?? [];
//   }

//   /// Get best quiz score
//   QuizSubmissionModel? getBestQuizSubmission(String quizId) {
//     final submissions = _quizSubmissions[quizId] ?? [];
//     if (submissions.isEmpty) return null;

//     submissions.sort((a, b) => b.score.compareTo(a.score));
//     return submissions.first;
//   }

//   /// Get average quiz score
//   double? getAverageQuizScore() {
//     final allBestScores = <double>[];

//     for (final quiz in _allQuizzes) {
//       final bestSubmission = getBestQuizSubmission(quiz.id);
//       if (bestSubmission != null) {
//         allBestScores.add(bestSubmission.score);
//       }
//     }

//     if (allBestScores.isEmpty) return null;

//     return allBestScores.reduce((a, b) => a + b) / allBestScores.length;
//   }

//   // ==================== QUIZ DEADLINE TRACKING ====================

//   /// Get quizzes due today
//   List<QuizModel> getQuizzesDueToday() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final tomorrow = today.add(const Duration(days: 1));

//     return _allQuizzes.where((quiz) {
//       return quiz.closeDate.isAfter(today) && quiz.closeDate.isBefore(tomorrow);
//     }).toList();
//   }

//   /// Get quizzes due this week
//   List<QuizModel> getQuizzesDueThisWeek() {
//     final now = DateTime.now();
//     final weekFromNow = now.add(const Duration(days: 7));

//     return _allQuizzes.where((quiz) {
//       return quiz.closeDate.isAfter(now) &&
//           quiz.closeDate.isBefore(weekFromNow);
//     }).toList();
//   }

//   /// Get upcoming quizzes (sorted by close date) - only incomplete
//   List<QuizModel> getUpcomingQuizzes({int limit = 10}) {
//     final now = DateTime.now();
//     print(
//         '📊 getUpcomingQuizzes: Total quizzes = ${_allQuizzes.length}, Now = $now');

//     final upcoming = _allQuizzes.where((quiz) {
//       // Check if quiz is upcoming (deadline in the future)
//       if (!quiz.closeDate.isAfter(now)) {
//         print(
//             '  ❌ "${quiz.title}" filtered: closeDate ${quiz.closeDate} is not after now');
//         return false;
//       }

//       // Filter out completed quizzes
//       final submissions = _quizSubmissions[quiz.id] ?? [];
//       if (submissions.isNotEmpty) {
//         print(
//             '  ❌ "${quiz.title}" filtered: has ${submissions.length} submissions');
//         return false;
//       }

//       print('  ✅ "${quiz.title}" included: closeDate ${quiz.closeDate}');
//       return true;
//     }).toList();

//     print('📊 Upcoming quizzes result: ${upcoming.length} quizzes');
//     upcoming.sort((a, b) => a.closeDate.compareTo(b.closeDate));

//     return limit > 0 ? upcoming.take(limit).toList() : upcoming;
//   }

//   /// Get overdue quizzes (close date passed, not submitted)
//   List<QuizModel> getOverdueQuizzes() {
//     final now = DateTime.now();
//     return _allQuizzes.where((quiz) {
//       final submissions = _quizSubmissions[quiz.id] ?? [];
//       return submissions.isEmpty && quiz.closeDate.isBefore(now);
//     }).toList();
//   }

//   // ==================== DEADLINE TRACKING ====================

//   /// Get assignments due today
//   List<AssignmentModel> getAssignmentsDueToday() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final tomorrow = today.add(const Duration(days: 1));

//     return _allAssignments.where((assignment) {
//       return assignment.deadline.isAfter(today) &&
//           assignment.deadline.isBefore(tomorrow) &&
//           assignment.isOpen;
//     }).toList();
//   }

//   /// Get assignments due this week
//   List<AssignmentModel> getAssignmentsDueThisWeek() {
//     final now = DateTime.now();
//     final weekFromNow = now.add(const Duration(days: 7));

//     return _allAssignments.where((assignment) {
//       return assignment.deadline.isAfter(now) &&
//           assignment.deadline.isBefore(weekFromNow) &&
//           assignment.isOpen;
//     }).toList();
//   }

//   /// Get upcoming assignments (sorted by deadline) - only unsubmitted
//   List<AssignmentModel> getUpcomingAssignments({int limit = 10}) {
//     final now = DateTime.now();
//     final upcoming = _allAssignments.where((assignment) {
//       // Check if assignment is upcoming and open
//       if (!assignment.deadline.isAfter(now) || !assignment.isOpen) return false;

//       // Filter out submitted assignments
//       final submission = _latestSubmissions[assignment.id];
//       return submission == null;
//     }).toList();

//     upcoming.sort((a, b) => a.deadline.compareTo(b.deadline));

//     return limit > 0 ? upcoming.take(limit).toList() : upcoming;
//   }

//   /// Get overdue assignments (deadline passed, not submitted)
//   List<AssignmentModel> getOverdueAssignments() {
//     final now = DateTime.now();
//     return _allAssignments.where((assignment) {
//       final submission = _latestSubmissions[assignment.id];
//       return submission == null &&
//           assignment.deadline.isBefore(now) &&
//           !assignment.allowLateSubmission;
//     }).toList();
//   }

//   // ==================== DATA LOADING ====================

//   /// Load all dashboard data for a student
//   Future<void> loadDashboardData({
//     required String studentId,
//     required List<String> courseIds,
//     required List<String> studentGroupIds,
//   }) async {
//     _error = null;
//     notifyListeners();

//     try {
//       // Load assignments and quizzes concurrently
//       await Future.wait([
//         _loadAssignments(studentId, courseIds, studentGroupIds),
//         _loadQuizzes(studentId, courseIds, studentGroupIds),
//       ]);
//     } catch (e) {
//       _error = e.toString();
//       print('Error loading dashboard data: $e');
//       notifyListeners();
//     }
//   }

//   /// Load assignments for student
//   Future<void> _loadAssignments(
//     String studentId,
//     List<String> courseIds,
//     List<String> studentGroupIds,
//   ) async {
//     _isLoadingAssignments = true;
//     notifyListeners();

//     try {
//       final List<AssignmentModel> allAssignments = [];
//       final Map<String, AssignmentSubmissionModel?> latestSubmissions = {};

//       // Load assignments for each course
//       for (final courseId in courseIds) {
//         final assignments = await _assignmentService.getAssignmentsForStudent(
//           courseId: courseId,
//           studentId: studentId,
//           studentGroupIds: studentGroupIds,
//         );
//         allAssignments.addAll(assignments);

//         // Load latest submission for each assignment
//         for (final assignment in assignments) {
//           final submission = await _assignmentService.getLatestSubmission(
//             assignmentId: assignment.id,
//             studentId: studentId,
//           );
//           latestSubmissions[assignment.id] = submission;
//         }
//       }

//       _allAssignments = allAssignments;
//       _latestSubmissions = latestSubmissions;
//     } catch (e) {
//       print('Error loading assignments: $e');
//       rethrow;
//     } finally {
//       _isLoadingAssignments = false;
//       notifyListeners();
//     }
//   }

//   /// Load quizzes for student
//   Future<void> _loadQuizzes(
//     String studentId,
//     List<String> courseIds,
//     List<String> studentGroupIds,
//   ) async {
//     _isLoadingQuizzes = true;
//     notifyListeners();

//     try {
//       final List<QuizModel> allQuizzes = [];
//       final Map<String, List<QuizSubmissionModel>> quizSubmissions = {};

//       // Load quizzes for each course
//       for (final courseId in courseIds) {
//         final quizzes = await _quizService.getQuizzesForStudent(
//           courseId: courseId,
//           studentGroupIds: studentGroupIds,
//         );
//         allQuizzes.addAll(quizzes);

//         // Load submissions for each quiz
//         for (final quiz in quizzes) {
//           final submissions = await _quizService.getStudentSubmissions(
//             quizId: quiz.id,
//             studentId: studentId,
//           );
//           quizSubmissions[quiz.id] = submissions;
//         }
//       }

//       _allQuizzes = allQuizzes;
//       _quizSubmissions = quizSubmissions;
//     } catch (e) {
//       print('Error loading quizzes: $e');
//       rethrow;
//     } finally {
//       _isLoadingQuizzes = false;
//       notifyListeners();
//     }
//   }

//   /// Refresh dashboard data
//   Future<void> refresh({
//     required String studentId,
//     required List<String> courseIds,
//     required List<String> studentGroupIds,
//   }) async {
//     await loadDashboardData(
//       studentId: studentId,
//       courseIds: courseIds,
//       studentGroupIds: studentGroupIds,
//     );
//   }

//   /// Clear all dashboard data
//   void clearData() {
//     _allAssignments = [];
//     _latestSubmissions = {};
//     _allQuizzes = [];
//     _quizSubmissions = {};
//     _error = null;
//     notifyListeners();
//   }

//   // ==================== STATISTICS ====================

//   /// Get overall progress statistics
//   Map<String, dynamic> getProgressStats() {
//     final totalAssignments = _allAssignments.length;
//     final submittedAssignments = getSubmittedAssignments().length;
//     final pendingAssignments = getPendingAssignments().length;
//     final lateAssignments = getLateAssignments().length;
//     final gradedAssignments = getGradedAssignments().length;

//     final totalQuizzes = _allQuizzes.length;
//     final completedQuizzes = getCompletedQuizzes().length;
//     final pendingQuizzes = getPendingQuizzes().length;

//     final avgAssignmentGrade = getAverageAssignmentGrade();
//     final avgQuizScore = getAverageQuizScore();

//     return {
//       'totalAssignments': totalAssignments,
//       'submittedAssignments': submittedAssignments,
//       'pendingAssignments': pendingAssignments,
//       'lateAssignments': lateAssignments,
//       'gradedAssignments': gradedAssignments,
//       'ungradedAssignments': submittedAssignments - gradedAssignments,
//       'overdueAssignments': getOverdueAssignments().length,
//       'totalQuizzes': totalQuizzes,
//       'completedQuizzes': completedQuizzes,
//       'pendingQuizzes': pendingQuizzes,
//       'overdueQuizzes': getOverdueQuizzes().length,
//       'averageAssignmentGrade': avgAssignmentGrade,
//       'averageQuizScore': avgQuizScore,
//       'assignmentCompletionRate': totalAssignments > 0
//           ? (submittedAssignments / totalAssignments) * 100
//           : 0.0,
//       'quizCompletionRate':
//           totalQuizzes > 0 ? (completedQuizzes / totalQuizzes) * 100 : 0.0,
//     };
//   }
// }
