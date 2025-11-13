import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/assignment_model.dart';
import '../models/assignment_submission_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../models/user_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'storage_service.dart';

/// Assignment Service
/// Handles all assignment-related operations including CRUD, submissions, grading, and tracking
class AssignmentService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final StorageService _storageService;

  AssignmentService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _storageService = storageService;

  // ============================================================
  // ASSIGNMENT CRUD OPERATIONS
  // ============================================================

  /// Get all assignments
  Future<List<AssignmentModel>> getAllAssignments() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAssignments,
        orderBy: 'createdAt',
        descending: true,
      );

      final assignments =
          data.map((json) => AssignmentModel.fromJson(json)).toList();

      // Cache assignments
      await _cacheAssignments(assignments);

      return assignments;
    } catch (e) {
      print('Get all assignments error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedAssignments();
    }
  }

  /// Get assignments by course
  Future<List<AssignmentModel>> getAssignmentsByCourse(
    String courseId,
  ) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAssignments,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
        orderBy: 'deadline',
        descending: false,
      );

      return data.map((json) => AssignmentModel.fromJson(json)).toList();
    } catch (e) {
      print('Get assignments by course error: $e');

      // Fallback: Try without orderBy if index is missing
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          print('Attempting query without orderBy and sorting in memory...');
          final data = await _firestoreService.query(
            collection: AppConstants.collectionAssignments,
            filters: [
              QueryFilter(field: 'courseId', isEqualTo: courseId),
            ],
          );

          final assignments =
              data.map((json) => AssignmentModel.fromJson(json)).toList();

          // Sort in memory by deadline ascending
          assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

          return assignments;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get assignments visible to a specific student (based on group membership)
  Future<List<AssignmentModel>> getAssignmentsForStudent({
    required String courseId,
    required String studentId,
    required List<String> studentGroupIds,
  }) async {
    try {
      // Get all assignments for the course
      final allAssignments = await getAssignmentsByCourse(courseId);

      // Filter assignments that are:
      // 1. For all groups (empty groupIds)
      // 2. For groups that the student belongs to
      final visibleAssignments = allAssignments.where((assignment) {
        if (assignment.isForAllGroups) {
          return true; // Visible to all students in course
        }
        // Check if any of the assignment's groups match student's groups
        return assignment.groupIds
            .any((groupId) => studentGroupIds.contains(groupId));
      }).toList();

      return visibleAssignments;
    } catch (e) {
      print('Get assignments for student error: $e');
      return [];
    }
  }

  /// Get assignment by ID
  Future<AssignmentModel?> getAssignmentById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionAssignments,
        documentId: id,
      );

      if (data == null) return null;

      return AssignmentModel.fromJson(data);
    } catch (e) {
      print('Get assignment by ID error: $e');
      return null;
    }
  }

  /// Create new assignment
  Future<AssignmentModel> createAssignment({
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
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      final now = DateTime.now();

      // Upload attachments if any
      List<AttachmentModel> attachments = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        attachments = await _uploadAttachments(
          files: attachmentFiles,
          courseId: courseId,
          assignmentId: '', // Will be updated after creation
        );
      }

      final assignment = AssignmentModel(
        id: '', // Will be set by Firestore
        courseId: courseId,
        title: title,
        description: description,
        attachments: attachments,
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
        createdAt: now,
        updatedAt: now,
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionAssignments,
        data: assignment.toJson(),
      );

      final createdAssignment = assignment.copyWith(id: id);

      // Clear cache to force refresh
      await _clearAssignmentsCache();

      return createdAssignment;
    } catch (e) {
      print('Create assignment error: $e');
      throw Exception('Failed to create assignment: ${e.toString()}');
    }
  }

  /// Update assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionAssignments,
        documentId: assignment.id,
        data: assignment.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearAssignmentsCache();
    } catch (e) {
      print('Update assignment error: $e');
      throw Exception('Failed to update assignment: ${e.toString()}');
    }
  }

  /// Upload attachments for an existing assignment (public wrapper)
  Future<List<AttachmentModel>> uploadAttachmentsForAssignment({
    required List<PlatformFile> files,
    required String courseId,
    required String assignmentId,
  }) async {
    return await _uploadAttachments(
      files: files,
      courseId: courseId,
      assignmentId: assignmentId,
    );
  }

  /// Delete assignment
  Future<void> deleteAssignment(String id) async {
    try {
      // Get assignment to delete its attachments
      final assignment = await getAssignmentById(id);
      if (assignment == null) {
        throw Exception('Assignment not found');
      }

      // Delete all submissions for this assignment
      final submissions = await getSubmissionsByAssignment(id);
      for (final submission in submissions) {
        await deleteSubmission(submission.id);
      }

      // Delete attachments from storage
      for (final attachment in assignment.attachments) {
        try {
          await _storageService.deleteFile(attachment.url);
        } catch (e) {
          print('Failed to delete attachment ${attachment.filename}: $e');
          // Continue even if deletion fails
        }
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionAssignments,
        documentId: id,
      );

      // Clear cache to force refresh
      await _clearAssignmentsCache();
    } catch (e) {
      print('Delete assignment error: $e');
      throw Exception('Failed to delete assignment: ${e.toString()}');
    }
  }

  /// Stream assignments by course (real-time updates)
  Stream<List<AssignmentModel>> streamAssignmentsByCourse(
    String courseId,
  ) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionAssignments,
      filters: [
        QueryFilter(field: 'courseId', isEqualTo: courseId),
      ],
      orderBy: 'deadline',
      descending: false,
    )
        .map((data) {
      return data.map((json) => AssignmentModel.fromJson(json)).toList();
    });
  }

  /// Get assignment count by course
  Future<int> getAssignmentCountByCourse(String courseId) async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionAssignments,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
      );
    } catch (e) {
      print('Get assignment count by course error: $e');
      return 0;
    }
  }

  // ============================================================
  // SUBMISSION OPERATIONS
  // ============================================================

  /// Get all submissions for an assignment
  Future<List<AssignmentSubmissionModel>> getSubmissionsByAssignment(
    String assignmentId,
  ) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAssignmentSubmissions,
        filters: [
          QueryFilter(field: 'assignmentId', isEqualTo: assignmentId),
        ],
        orderBy: 'submittedAt',
        descending: true,
      );

      return data
          .map((json) => AssignmentSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get submissions by assignment error: $e');

      // Fallback without orderBy
      try {
        final data = await _firestoreService.query(
          collection: AppConstants.collectionAssignmentSubmissions,
          filters: [
            QueryFilter(field: 'assignmentId', isEqualTo: assignmentId),
          ],
        );

        final submissions = data
            .map((json) => AssignmentSubmissionModel.fromJson(json))
            .toList();

        // Sort in memory
        submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        return submissions;
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get submissions by student for a specific assignment
  Future<List<AssignmentSubmissionModel>> getSubmissionsByStudent({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAssignmentSubmissions,
        filters: [
          QueryFilter(field: 'assignmentId', isEqualTo: assignmentId),
          QueryFilter(field: 'studentId', isEqualTo: studentId),
        ],
        orderBy: 'attemptNumber',
        descending: false,
      );

      return data
          .map((json) => AssignmentSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Get submissions by student error: $e');

      // Fallback without orderBy
      try {
        final data = await _firestoreService.query(
          collection: AppConstants.collectionAssignmentSubmissions,
          filters: [
            QueryFilter(field: 'assignmentId', isEqualTo: assignmentId),
            QueryFilter(field: 'studentId', isEqualTo: studentId),
          ],
        );

        final submissions = data
            .map((json) => AssignmentSubmissionModel.fromJson(json))
            .toList();

        // Sort in memory by attempt number
        submissions.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));

        return submissions;
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get latest submission for a student
  Future<AssignmentSubmissionModel?> getLatestSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final submissions = await getSubmissionsByStudent(
        assignmentId: assignmentId,
        studentId: studentId,
      );

      if (submissions.isEmpty) return null;

      // Return the latest submission (highest attempt number)
      submissions.sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
      return submissions.first;
    } catch (e) {
      print('Get latest submission error: $e');
      return null;
    }
  }

  /// Submit assignment
  Future<AssignmentSubmissionModel> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required List<PlatformFile> files,
    required bool isLate,
  }) async {
    try {
      // Get assignment to validate
      final assignment = await getAssignmentById(assignmentId);
      if (assignment == null) {
        throw Exception('Assignment not found');
      }

      // Check if assignment is closed
      if (assignment.isClosed) {
        throw Exception('Assignment deadline has passed');
      }

      // Get existing submissions to determine attempt number
      final existingSubmissions = await getSubmissionsByStudent(
        assignmentId: assignmentId,
        studentId: studentId,
      );

      final attemptNumber = existingSubmissions.length + 1;

      // Check max attempts
      if (assignment.maxAttempts > 0 &&
          attemptNumber > assignment.maxAttempts) {
        throw Exception(
            'Maximum number of attempts (${assignment.maxAttempts}) exceeded');
      }

      // Validate files
      for (final file in files) {
        final filename = file.name;
        if (!assignment.isValidFileFormat(filename)) {
          throw Exception(
              'Invalid file format: $filename. Allowed formats: ${assignment.allowedFileFormats.join(", ")}');
        }

        final fileSize = file.size;
        if (fileSize > assignment.maxFileSize) {
          throw Exception(
              'File size exceeds maximum allowed size: ${assignment.formattedMaxFileSize}');
        }
      }

      // Upload submission files
      final uploadedFiles = await _uploadSubmissionFiles(
        files: files,
        assignmentId: assignmentId,
        studentId: studentId,
        attemptNumber: attemptNumber,
      );

      // Create submission
      final submission = AssignmentSubmissionModel(
        id: '', // Will be set by Firestore
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: studentName,
        files: uploadedFiles,
        attemptNumber: attemptNumber,
        submittedAt: DateTime.now(),
        isLate: isLate,
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionAssignmentSubmissions,
        data: submission.toJson(),
      );

      return submission.copyWith(id: id);
    } catch (e) {
      print('Submit assignment error: $e');
      throw Exception('Failed to submit assignment: ${e.toString()}');
    }
  }

  /// Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
    required String instructorId,
  }) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionAssignmentSubmissions,
        documentId: submissionId,
      );

      if (data == null) {
        throw Exception('Submission not found');
      }

      final submission = AssignmentSubmissionModel.fromJson(data);

      final updatedSubmission = submission.copyWith(
        grade: grade,
        feedback: feedback,
        gradedAt: DateTime.now(),
        gradedBy: instructorId,
      );

      await _firestoreService.update(
        collection: AppConstants.collectionAssignmentSubmissions,
        documentId: submissionId,
        data: updatedSubmission.toJson(),
      );
    } catch (e) {
      print('Grade submission error: $e');
      throw Exception('Failed to grade submission: ${e.toString()}');
    }
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      // Get submission to delete its files
      final data = await _firestoreService.read(
        collection: AppConstants.collectionAssignmentSubmissions,
        documentId: submissionId,
      );

      if (data != null) {
        final submission = AssignmentSubmissionModel.fromJson(data);

        // Delete files from storage
        for (final file in submission.files) {
          try {
            await _storageService.deleteFile(file.url);
          } catch (e) {
            print('Failed to delete file ${file.filename}: $e');
            // Continue even if deletion fails
          }
        }
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionAssignmentSubmissions,
        documentId: submissionId,
      );
    } catch (e) {
      print('Delete submission error: $e');
      throw Exception('Failed to delete submission: ${e.toString()}');
    }
  }

  // ============================================================
  // TRACKING AND ANALYTICS
  // ============================================================

  /// Get submission statistics for an assignment
  Future<Map<String, dynamic>> getSubmissionStats({
    required String assignmentId,
    required List<UserModel> students,
  }) async {
    try {
      final submissions = await getSubmissionsByAssignment(assignmentId);

      // Group submissions by student ID
      final submissionsByStudent = <String, List<AssignmentSubmissionModel>>{};
      for (final submission in submissions) {
        submissionsByStudent.putIfAbsent(
          submission.studentId,
          () => [],
        ).add(submission);
      }

      // Count statistics
      final totalStudents = students.length;
      final submittedStudents = submissionsByStudent.length;
      final notSubmitted = totalStudents - submittedStudents;

      // Count late submissions (latest submission is late)
      int lateSubmissions = 0;
      for (final studentSubmissions in submissionsByStudent.values) {
        studentSubmissions
            .sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
        if (studentSubmissions.first.isLate) {
          lateSubmissions++;
        }
      }

      // Count graded submissions
      int gradedCount = 0;
      double totalGrade = 0;
      for (final studentSubmissions in submissionsByStudent.values) {
        // Get latest submission
        studentSubmissions
            .sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
        final latest = studentSubmissions.first;
        if (latest.isGraded) {
          gradedCount++;
          totalGrade += latest.grade!;
        }
      }

      // Calculate average grade
      final averageGrade = gradedCount > 0 ? totalGrade / gradedCount : null;

      // Count multiple attempts
      int multipleAttemptsCount = 0;
      for (final studentSubmissions in submissionsByStudent.values) {
        if (studentSubmissions.length > 1) {
          multipleAttemptsCount++;
        }
      }

      return {
        'totalStudents': totalStudents,
        'submitted': submittedStudents,
        'notSubmitted': notSubmitted,
        'lateSubmissions': lateSubmissions,
        'graded': gradedCount,
        'notGraded': submittedStudents - gradedCount,
        'averageGrade': averageGrade,
        'multipleAttempts': multipleAttemptsCount,
      };
    } catch (e) {
      print('Get submission stats error: $e');
      return {
        'totalStudents': 0,
        'submitted': 0,
        'notSubmitted': 0,
        'lateSubmissions': 0,
        'graded': 0,
        'notGraded': 0,
        'averageGrade': null,
        'multipleAttempts': 0,
      };
    }
  }

  /// Get detailed submission status for all students
  Future<List<Map<String, dynamic>>> getStudentSubmissionStatus({
    required String assignmentId,
    required List<UserModel> students,
  }) async {
    try {
      final submissions = await getSubmissionsByAssignment(assignmentId);

      // Group submissions by student ID
      final submissionsByStudent = <String, List<AssignmentSubmissionModel>>{};
      for (final submission in submissions) {
        submissionsByStudent.putIfAbsent(
          submission.studentId,
          () => [],
        ).add(submission);
      }

      // Build status list for each student
      final statusList = <Map<String, dynamic>>[];
      for (final student in students) {
        final studentSubmissions = submissionsByStudent[student.id] ?? [];

        // Sort by attempt number descending to get latest
        studentSubmissions
            .sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));

        final latestSubmission =
            studentSubmissions.isNotEmpty ? studentSubmissions.first : null;

        statusList.add({
          'studentId': student.id,
          'studentName': student.fullName,
          'studentEmail': student.email,
          'hasSubmitted': latestSubmission != null,
          'attemptCount': studentSubmissions.length,
          'latestSubmission': latestSubmission,
          'isLate': latestSubmission?.isLate ?? false,
          'grade': latestSubmission?.grade,
          'status': latestSubmission?.status ?? 'not_submitted',
          'submittedAt': latestSubmission?.submittedAt,
        });
      }

      return statusList;
    } catch (e) {
      print('Get student submission status error: $e');
      return [];
    }
  }

  // ============================================================
  // CSV EXPORT
  // ============================================================

  /// Export assignment grades to CSV
  Future<String> exportGradesToCSV({
    required String assignmentId,
    required String assignmentTitle,
    required List<UserModel> students,
  }) async {
    try {
      final statusList = await getStudentSubmissionStatus(
        assignmentId: assignmentId,
        students: students,
      );

      // Create CSV data
      final List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Student ID',
        'Student Name',
        'Email',
        'Submitted',
        'Attempt Count',
        'Grade',
        'Status',
        'Submitted At',
        'Is Late',
      ]);

      // Data rows
      for (final status in statusList) {
        rows.add([
          status['studentId'],
          status['studentName'],
          status['studentEmail'],
          status['hasSubmitted'] ? 'Yes' : 'No',
          status['attemptCount'],
          status['grade']?.toString() ?? 'N/A',
          status['status'],
          status['submittedAt'] != null
              ? (status['submittedAt'] as DateTime)
                  .toLocal()
                  .toString()
                  .split('.')[0]
              : 'N/A',
          status['isLate'] ? 'Yes' : 'No',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      return csvString;
    } catch (e) {
      print('Export grades to CSV error: $e');
      throw Exception('Failed to export grades: ${e.toString()}');
    }
  }

  /// Export all assignments in a course to CSV
  Future<String> exportCourseAssignmentsToCSV({
    required String courseId,
    required List<UserModel> students,
  }) async {
    try {
      final assignments = await getAssignmentsByCourse(courseId);

      final List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Assignment',
        'Student ID',
        'Student Name',
        'Email',
        'Submitted',
        'Attempt Count',
        'Grade',
        'Status',
        'Submitted At',
        'Is Late',
      ]);

      // Data rows for each assignment
      for (final assignment in assignments) {
        final statusList = await getStudentSubmissionStatus(
          assignmentId: assignment.id,
          students: students,
        );

        for (final status in statusList) {
          rows.add([
            assignment.title,
            status['studentId'],
            status['studentName'],
            status['studentEmail'],
            status['hasSubmitted'] ? 'Yes' : 'No',
            status['attemptCount'],
            status['grade']?.toString() ?? 'N/A',
            status['status'],
            status['submittedAt'] != null
                ? (status['submittedAt'] as DateTime)
                    .toLocal()
                    .toString()
                    .split('.')[0]
                : 'N/A',
            status['isLate'] ? 'Yes' : 'No',
          ]);
        }
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      return csvString;
    } catch (e) {
      print('Export course assignments to CSV error: $e');
      throw Exception('Failed to export course assignments: ${e.toString()}');
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Upload assignment attachments to storage
  Future<List<AttachmentModel>> _uploadAttachments({
    required List<PlatformFile> files,
    required String courseId,
    required String assignmentId,
  }) async {
    final attachments = <AttachmentModel>[];
    final failedFiles = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage - use directory path only
        final storagePath = 'assignments/$courseId/$assignmentId';
        final timestampedFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: '$storagePath/$timestampedFilename',
        );

        // Get file size
        final fileSize = file.size;

        // Create attachment model
        final attachment = AttachmentModel(
          id: '${assignmentId}_attachment_$i',
          url: downloadUrl,
          filename: filename,
          size: fileSize,
          type: extension,
        );

        attachments.add(attachment);
      } catch (e) {
        print('Failed to upload attachment $filename: $e');
        failedFiles.add(filename);
      }
    }

    // Log warning if some files failed
    if (failedFiles.isNotEmpty) {
      print('Warning: Some attachment files failed to upload: ${failedFiles.join(", ")}');
    }

    return attachments;
  }

  /// Upload submission files to storage
  Future<List<AttachmentModel>> _uploadSubmissionFiles({
    required List<PlatformFile> files,
    required String assignmentId,
    required String studentId,
    required int attemptNumber,
  }) async {
    final submissionFiles = <AttachmentModel>[];
    final failedFiles = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage - use directory path only
        final storagePath =
            'submissions/$assignmentId/$studentId/attempt_$attemptNumber';
        final timestampedFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: '$storagePath/$timestampedFilename',
        );

        // Get file size
        final fileSize = file.size;

        // Create file model
        final submissionFile = AttachmentModel(
          id: '${assignmentId}_${studentId}_file_$i',
          url: downloadUrl,
          filename: filename,
          size: fileSize,
          type: extension,
        );

        submissionFiles.add(submissionFile);
      } catch (e) {
        print('Failed to upload submission file $filename: $e');
        failedFiles.add(filename);
      }
    }

    // If all files failed to upload, throw an error
    if (submissionFiles.isEmpty) {
      throw Exception(
        'All files failed to upload. Please check your internet connection and try again.',
      );
    }

    // If some files failed, log a warning
    if (failedFiles.isNotEmpty) {
      print('Warning: Some files failed to upload: ${failedFiles.join(", ")}');
    }

    return submissionFiles;
  }

  /// Private: Cache assignments
  Future<void> _cacheAssignments(List<AssignmentModel> assignments) async {
    try {
      final assignmentsJson = assignments.map((a) => a.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxAssignments,
        key: 'all_assignments',
        value: assignmentsJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache assignments error: $e');
    }
  }

  /// Private: Get cached assignments
  List<AssignmentModel> _getCachedAssignments() {
    try {
      final cached = _hiveService.getCached(key: 'all_assignments');
      if (cached != null && cached is List) {
        return cached
            .map(
                (json) => AssignmentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached assignments error: $e');
      return [];
    }
  }

  /// Private: Clear assignments cache
  Future<void> _clearAssignmentsCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_assignments',
      );
    } catch (e) {
      print('Clear assignments cache error: $e');
    }
  }
}
