import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_constants.dart';
import '../models/assignment_model.dart';
import '../models/quiz_model.dart';
import 'notification_service.dart';
import 'email_service.dart';

/// Deadline Monitoring Service
/// Monitors assignments and quizzes for approaching deadlines
/// and sends notifications/emails to students
class DeadlineMonitoringService {
  final NotificationService _notificationService;
  final EmailService _emailService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Timers for periodic checks
  Timer? _monitoringTimer;

  // Configuration
  static const Duration checkInterval = Duration(hours: 1); // Check every hour
  static const List<int> notificationHours = [24, 12, 6, 3]; // Send notifications at these hours before deadline

  DeadlineMonitoringService({
    required NotificationService notificationService,
    required EmailService emailService,
  })  : _notificationService = notificationService,
        _emailService = emailService;

  /// Start monitoring deadlines
  void startMonitoring() {
    print('Starting deadline monitoring service...');

    // Run initial check
    _checkDeadlines();

    // Schedule periodic checks
    _monitoringTimer = Timer.periodic(checkInterval, (_) {
      _checkDeadlines();
    });
  }

  /// Stop monitoring deadlines
  void stopMonitoring() {
    print('Stopping deadline monitoring service...');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Check all upcoming deadlines
  Future<void> _checkDeadlines() async {
    print('Checking deadlines at ${DateTime.now()}...');
    try {
      await Future.wait([
        _checkAssignmentDeadlines(),
        _checkQuizDeadlines(),
      ]);
    } catch (e) {
      print('Error checking deadlines: $e');
    }
  }

  /// Check assignment deadlines
  Future<void> _checkAssignmentDeadlines() async {
    try {
      final now = DateTime.now();
      final maxDeadline = now.add(const Duration(hours: 24));

      // Query assignments with deadlines in the next 24 hours
      final snapshot = await _firestore
          .collection(AppConstants.collectionAssignments)
          .where('deadline', isGreaterThan: now.toIso8601String())
          .where('deadline', isLessThan: maxDeadline.toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        final assignment = AssignmentModel.fromJson(doc.data());
        await _processAssignmentDeadline(assignment);
      }
    } catch (e) {
      print('Error checking assignment deadlines: $e');
    }
  }

  /// Check quiz deadlines
  Future<void> _checkQuizDeadlines() async {
    try {
      final now = DateTime.now();
      final maxDeadline = now.add(const Duration(hours: 24));

      // Query quizzes with close dates in the next 24 hours
      final snapshot = await _firestore
          .collection(AppConstants.collectionQuizzes)
          .where('closeDate', isGreaterThan: now.toIso8601String())
          .where('closeDate', isLessThan: maxDeadline.toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        final quiz = QuizModel.fromJson(doc.data());
        await _processQuizDeadline(quiz);
      }
    } catch (e) {
      print('Error checking quiz deadlines: $e');
    }
  }

  /// Process assignment deadline and send notifications
  Future<void> _processAssignmentDeadline(AssignmentModel assignment) async {
    try {
      final now = DateTime.now();
      final hoursRemaining = assignment.deadline.difference(now).inHours;

      // Check if we should send notification for this time frame
      if (!_shouldSendNotification(hoursRemaining)) {
        return;
      }

      // Get students who haven't submitted
      final studentsToNotify = await _getStudentsWithoutSubmission(
        assignment.id,
        assignment.groupIds,
      );

      if (studentsToNotify.isEmpty) {
        return;
      }

      print('Sending deadline notifications for assignment "${assignment.title}" to ${studentsToNotify.length} students');

      // Send in-app notifications
      final studentIds = studentsToNotify.map((s) => s['userId'] as String).toList();
      await _notificationService.createNotificationsForUsers(
        userIds: studentIds,
        type: AppConstants.notificationTypeDeadline,
        title: 'Assignment Deadline Approaching',
        message: 'Assignment "${assignment.title}" is due in $hoursRemaining hours!',
        relatedId: assignment.id,
        relatedType: 'assignment',
        data: {
          'assignmentTitle': assignment.title,
          'deadline': assignment.deadline.toIso8601String(),
          'hoursRemaining': hoursRemaining,
        },
      );

      // Send emails if email service is configured
      if (_emailService.isConfigured) {
        for (final student in studentsToNotify) {
          final studentEmail = student['email'] as String?;
          final studentName = student['name'] as String?;

          if (studentEmail != null && studentName != null) {
            _emailService.sendAssignmentDeadlineEmail(
              recipientEmail: studentEmail,
              recipientName: studentName,
              courseName: 'Your Course', // TODO: Get course name from courseId
              assignmentTitle: assignment.title,
              deadline: assignment.deadline,
              hoursRemaining: hoursRemaining,
            ).catchError((error) {
              print('Error sending deadline email to $studentEmail: $error');
              return false;
            });
          }
        }
      }
    } catch (e) {
      print('Error processing assignment deadline: $e');
    }
  }

  /// Process quiz deadline and send notifications
  Future<void> _processQuizDeadline(QuizModel quiz) async {
    try {
      final now = DateTime.now();
      final hoursRemaining = quiz.closeDate.difference(now).inHours;

      // Check if we should send notification for this time frame
      if (!_shouldSendNotification(hoursRemaining)) {
        return;
      }

      // Get students who haven't completed the quiz
      final studentsToNotify = await _getStudentsWithoutQuizSubmission(
        quiz.id,
        quiz.groupIds,
        quiz.maxAttempts,
      );

      if (studentsToNotify.isEmpty) {
        return;
      }

      print('Sending deadline notifications for quiz "${quiz.title}" to ${studentsToNotify.length} students');

      // Send in-app notifications
      final studentIds = studentsToNotify.map((s) => s['userId'] as String).toList();
      await _notificationService.createNotificationsForUsers(
        userIds: studentIds,
        type: AppConstants.notificationTypeDeadline,
        title: 'Quiz Deadline Approaching',
        message: 'Quiz "${quiz.title}" closes in $hoursRemaining hours!',
        relatedId: quiz.id,
        relatedType: 'quiz',
        data: {
          'quizTitle': quiz.title,
          'closeDate': quiz.closeDate.toIso8601String(),
          'hoursRemaining': hoursRemaining,
        },
      );

      // Send emails if email service is configured
      if (_emailService.isConfigured) {
        for (final student in studentsToNotify) {
          final studentEmail = student['email'] as String?;
          final studentName = student['name'] as String?;

          if (studentEmail != null && studentName != null) {
            _emailService.sendQuizDeadlineEmail(
              recipientEmail: studentEmail,
              recipientName: studentName,
              courseName: 'Your Course', // TODO: Get course name
              quizTitle: quiz.title,
              deadline: quiz.closeDate,
              hoursRemaining: hoursRemaining,
            ).catchError((error) {
              print('Error sending deadline email to $studentEmail: $error');
              return false;
            });
          }
        }
      }
    } catch (e) {
      print('Error processing quiz deadline: $e');
    }
  }

  /// Check if notification should be sent based on hours remaining
  bool _shouldSendNotification(int hoursRemaining) {
    // Send notification if hours remaining matches one of our configured thresholds
    // Allow a 1-hour window to account for check intervals
    for (final threshold in notificationHours) {
      if (hoursRemaining <= threshold && hoursRemaining > (threshold - 1)) {
        return true;
      }
    }
    return false;
  }

  /// Get students without submission for an assignment
  Future<List<Map<String, dynamic>>> _getStudentsWithoutSubmission(
    String assignmentId,
    List<String> groupIds,
  ) async {
    try {
      // Get all students in the groups
      final allStudents = await _getStudentsInGroups(groupIds);

      // Get students who have submitted
      final submissions = await _firestore
          .collection(AppConstants.collectionAssignmentSubmissions)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final submittedStudentIds = submissions.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toSet();

      // Filter out students who have already submitted
      return allStudents
          .where((student) => !submittedStudentIds.contains(student['userId']))
          .toList();
    } catch (e) {
      print('Error getting students without submission: $e');
      return [];
    }
  }

  /// Get students without quiz submission
  Future<List<Map<String, dynamic>>> _getStudentsWithoutQuizSubmission(
    String quizId,
    List<String> groupIds,
    int maxAttempts,
  ) async {
    try {
      // Get all students in the groups
      final allStudents = await _getStudentsInGroups(groupIds);

      // Get quiz submissions
      final submissions = await _firestore
          .collection(AppConstants.collectionQuizSubmissions)
          .where('quizId', isEqualTo: quizId)
          .get();

      // Count attempts per student
      final attemptCounts = <String, int>{};
      for (final doc in submissions.docs) {
        final studentId = doc.data()['studentId'] as String;
        attemptCounts[studentId] = (attemptCounts[studentId] ?? 0) + 1;
      }

      // Filter students who haven't reached max attempts
      return allStudents.where((student) {
        final userId = student['userId'] as String;
        final attempts = attemptCounts[userId] ?? 0;
        return attempts < maxAttempts;
      }).toList();
    } catch (e) {
      print('Error getting students without quiz submission: $e');
      return [];
    }
  }

  /// Get all students in specified groups
  Future<List<Map<String, dynamic>>> _getStudentsInGroups(
    List<String> groupIds,
  ) async {
    try {
      final List<Map<String, dynamic>> students = [];
      final Set<String> addedStudentIds = {};

      for (final groupId in groupIds) {
        final groupDoc = await _firestore
            .collection(AppConstants.collectionGroups)
            .doc(groupId)
            .get();

        if (groupDoc.exists) {
          final groupData = groupDoc.data() as Map<String, dynamic>;
          final List<dynamic> studentIds = groupData['studentIds'] ?? [];

          // Get student details
          for (final studentId in studentIds) {
            if (!addedStudentIds.contains(studentId)) {
              final studentDoc = await _firestore
                  .collection(AppConstants.collectionUsers)
                  .doc(studentId)
                  .get();

              if (studentDoc.exists) {
                final studentData = studentDoc.data() as Map<String, dynamic>;
                students.add({
                  'userId': studentId,
                  'name': studentData['fullName'] ?? 'Student',
                  'email': studentData['email'],
                });
                addedStudentIds.add(studentId as String);
              }
            }
          }
        }
      }

      return students;
    } catch (e) {
      print('Error getting students in groups: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
