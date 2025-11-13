import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import '../models/assignment_submission_model.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../services/assignment_service.dart';

/// Assignment Provider
/// Manages assignment state and handles assignment operations
class AssignmentProvider extends ChangeNotifier {
  final AssignmentService _assignmentService;

  AssignmentProvider({required AssignmentService assignmentService})
      : _assignmentService = assignmentService;

  // State
  List<AssignmentModel> _assignments = [];
  List<AssignmentModel> _filteredAssignments = [];
  List<AssignmentSubmissionModel> _submissions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCourseId;
  Map<String, dynamic>? _submissionStats;
  List<Map<String, dynamic>> _studentSubmissionStatus = [];

  // Getters
  List<AssignmentModel> get assignments => _filteredAssignments;
  List<AssignmentSubmissionModel> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCourseId => _selectedCourseId;
  int get assignmentsCount => _assignments.length;
  Map<String, dynamic>? get submissionStats => _submissionStats;
  List<Map<String, dynamic>> get studentSubmissionStatus =>
      _studentSubmissionStatus;

  /// Load all assignments
  Future<void> loadAssignments() async {
    try {
      _setLoading(true);
      _error = null;

      _assignments = await _assignmentService.getAllAssignments();
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load assignments by course
  Future<void> loadAssignmentsByCourse(String courseId) async {
    try {
      _setLoading(true);
      _error = null;
      _selectedCourseId = courseId;

      _assignments = await _assignmentService.getAssignmentsByCourse(courseId);
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load assignments for a specific student (filtered by group membership)
  Future<void> loadAssignmentsForStudent({
    required String courseId,
    required String studentId,
    required List<String> studentGroupIds,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      _selectedCourseId = courseId;

      _assignments = await _assignmentService.getAssignmentsForStudent(
        courseId: courseId,
        studentId: studentId,
        studentGroupIds: studentGroupIds,
      );
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get assignment by ID
  Future<AssignmentModel?> getAssignmentById(String id) async {
    try {
      return await _assignmentService.getAssignmentById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create new assignment
  Future<AssignmentModel?> createAssignment({
    required String courseId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime deadline,
    required bool allowLateSubmission,
    DateTime? lateDeadline,
    required int maxAttempts,
    required List<String> allowedFileFormats,
    required int maxFileSize,
    required List<String> groupIds,
    required String instructorId,
    required String instructorName,
    List<File>? attachmentFiles,
  }) async {
    try {
      _error = null;

      final assignment = await _assignmentService.createAssignment(
        courseId: courseId,
        title: title,
        description: description,
        startDate: startDate,
        deadline: deadline,
        allowLateSubmission: allowLateSubmission,
        lateDeadline: lateDeadline,
        maxAttempts: maxAttempts,
        allowedFileFormats: allowedFileFormats,
        maxFileSize: maxFileSize,
        groupIds: groupIds,
        instructorId: instructorId,
        instructorName: instructorName,
        attachmentFiles: attachmentFiles,
      );

      // Reload assignments
      if (_selectedCourseId != null) {
        await loadAssignmentsByCourse(_selectedCourseId!);
      } else {
        await loadAssignments();
      }

      return assignment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Upload attachments for editing an assignment
  Future<List<AttachmentModel>> uploadAttachmentsForEdit({
    required List<File> files,
    required String courseId,
    required String assignmentId,
  }) async {
    try {
      return await _assignmentService.uploadAttachmentsForAssignment(
        files: files,
        courseId: courseId,
        assignmentId: assignmentId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update assignment
  Future<bool> updateAssignment(AssignmentModel assignment) async {
    try {
      _error = null;

      await _assignmentService.updateAssignment(assignment);

      // Reload assignments
      if (_selectedCourseId != null) {
        await loadAssignmentsByCourse(_selectedCourseId!);
      } else {
        await loadAssignments();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete assignment
  Future<bool> deleteAssignment(String id) async {
    try {
      _error = null;

      await _assignmentService.deleteAssignment(id);

      // Reload assignments
      if (_selectedCourseId != null) {
        await loadAssignmentsByCourse(_selectedCourseId!);
      } else {
        await loadAssignments();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // SUBMISSION OPERATIONS
  // ============================================================

  /// Load submissions for an assignment
  Future<void> loadSubmissionsByAssignment(String assignmentId) async {
    try {
      _setLoading(true);
      _error = null;

      _submissions =
          await _assignmentService.getSubmissionsByAssignment(assignmentId);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load submissions for a student
  Future<void> loadSubmissionsByStudent({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _submissions = await _assignmentService.getSubmissionsByStudent(
        assignmentId: assignmentId,
        studentId: studentId,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get latest submission for a student
  Future<AssignmentSubmissionModel?> getLatestSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      return await _assignmentService.getLatestSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Submit assignment
  Future<AssignmentSubmissionModel?> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required List<File> files,
    required bool isLate,
  }) async {
    try {
      _error = null;

      final submission = await _assignmentService.submitAssignment(
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: studentName,
        files: files,
        isLate: isLate,
      );

      // Reload submissions
      await loadSubmissionsByStudent(
        assignmentId: assignmentId,
        studentId: studentId,
      );

      return submission;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Grade submission
  Future<bool> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
    required String instructorId,
  }) async {
    try {
      _error = null;

      await _assignmentService.gradeSubmission(
        submissionId: submissionId,
        grade: grade,
        feedback: feedback,
        instructorId: instructorId,
      );

      // Reload current submissions if we have them
      if (_submissions.isNotEmpty) {
        final assignmentId = _submissions.first.assignmentId;
        await loadSubmissionsByAssignment(assignmentId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // TRACKING AND ANALYTICS
  // ============================================================

  /// Load submission statistics for an assignment
  Future<void> loadSubmissionStats({
    required String assignmentId,
    required List<UserModel> students,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _submissionStats = await _assignmentService.getSubmissionStats(
        assignmentId: assignmentId,
        students: students,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load detailed student submission status
  Future<void> loadStudentSubmissionStatus({
    required String assignmentId,
    required List<UserModel> students,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      _studentSubmissionStatus =
          await _assignmentService.getStudentSubmissionStatus(
        assignmentId: assignmentId,
        students: students,
      );

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // CSV EXPORT
  // ============================================================

  /// Export assignment grades to CSV
  Future<String?> exportGradesToCSV({
    required String assignmentId,
    required String assignmentTitle,
    required List<UserModel> students,
  }) async {
    try {
      _error = null;

      final csvString = await _assignmentService.exportGradesToCSV(
        assignmentId: assignmentId,
        assignmentTitle: assignmentTitle,
        students: students,
      );

      return csvString;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Export all assignments in a course to CSV
  Future<String?> exportCourseAssignmentsToCSV({
    required String courseId,
    required List<UserModel> students,
  }) async {
    try {
      _error = null;

      final csvString = await _assignmentService.exportCourseAssignmentsToCSV(
        courseId: courseId,
        students: students,
      );

      return csvString;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // SEARCH AND FILTERING
  // ============================================================

  /// Search assignments
  void searchAssignments(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Apply filters to assignments
  void _applyFilters() {
    _filteredAssignments = _assignments.where((assignment) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return assignment.title.toLowerCase().contains(query) ||
            assignment.description.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  /// Sort assignments by deadline
  void sortByDeadline({bool ascending = true}) {
    _filteredAssignments.sort((a, b) {
      return ascending
          ? a.deadline.compareTo(b.deadline)
          : b.deadline.compareTo(a.deadline);
    });
    notifyListeners();
  }

  /// Sort assignments by title
  void sortByTitle({bool ascending = true}) {
    _filteredAssignments.sort((a, b) {
      return ascending
          ? a.title.compareTo(b.title)
          : b.title.compareTo(a.title);
    });
    notifyListeners();
  }

  /// Sort assignments by created date
  void sortByCreatedDate({bool ascending = true}) {
    _filteredAssignments.sort((a, b) {
      return ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });
    notifyListeners();
  }

  /// Filter assignments by status (open, closed, upcoming, late period)
  void filterByStatus(String status) {
    if (status == 'all') {
      _filteredAssignments = List.from(_assignments);
    } else if (status == 'open') {
      _filteredAssignments =
          _assignments.where((a) => a.isOpen).toList();
    } else if (status == 'closed') {
      _filteredAssignments =
          _assignments.where((a) => a.isClosed).toList();
    } else if (status == 'upcoming') {
      _filteredAssignments =
          _assignments.where((a) => a.isUpcoming).toList();
    } else if (status == 'late_period') {
      _filteredAssignments =
          _assignments.where((a) => a.isInLatePeriod).toList();
    }
    notifyListeners();
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _assignments = [];
    _filteredAssignments = [];
    _submissions = [];
    _submissionStats = null;
    _studentSubmissionStatus = [];
    _error = null;
    _searchQuery = '';
    _selectedCourseId = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Get count of assignments by course
  Future<int> getAssignmentCountByCourse(String courseId) async {
    try {
      return await _assignmentService.getAssignmentCountByCourse(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }
}
