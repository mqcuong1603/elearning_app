import 'package:equatable/equatable.dart';

class AssignmentEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String createdBy; // Instructor ID
  final List<String> attachmentUrls; // Multiple files/images
  final List<String> targetGroupIds; // Scoped to specific groups

  // Deadline and submission settings
  final DateTime startDate;
  final DateTime deadline;
  final bool allowLateSubmission;
  final DateTime? lateDeadline; // If late submissions allowed
  final int maxSubmissionAttempts; // e.g., 1, 2, 3
  final List<String> allowedFileFormats; // e.g., ["pdf", "docx", "zip"]
  final int maxFileSizeMB; // Max file size in MB

  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/tracking properties
  final String? courseName;
  final String? courseCode;
  final String? instructorName;
  final int? totalStudents; // Total students who should submit
  final int? submittedCount; // Number of students who submitted
  final int? pendingCount; // Not yet submitted
  final int? lateSubmissionCount; // Submitted after deadline
  final int? gradedCount; // Number of submissions graded

  const AssignmentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.createdBy,
    required this.attachmentUrls,
    required this.targetGroupIds,
    required this.startDate,
    required this.deadline,
    required this.allowLateSubmission,
    this.lateDeadline,
    required this.maxSubmissionAttempts,
    required this.allowedFileFormats,
    required this.maxFileSizeMB,
    required this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
    this.instructorName,
    this.totalStudents,
    this.submittedCount,
    this.pendingCount,
    this.lateSubmissionCount,
    this.gradedCount,
  });

  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(deadline);
  }

  bool get isClosed {
    if (allowLateSubmission && lateDeadline != null) {
      return DateTime.now().isAfter(lateDeadline!);
    }
    return DateTime.now().isAfter(deadline);
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isLateSubmissionPeriod {
    if (!allowLateSubmission || lateDeadline == null) return false;
    final now = DateTime.now();
    return now.isAfter(deadline) && now.isBefore(lateDeadline!);
  }

  bool isFileFormatAllowed(String fileExtension) {
    return allowedFileFormats.contains(fileExtension.toLowerCase());
  }

  AssignmentEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? createdBy,
    List<String>? attachmentUrls,
    List<String>? targetGroupIds,
    DateTime? startDate,
    DateTime? deadline,
    bool? allowLateSubmission,
    DateTime? lateDeadline,
    int? maxSubmissionAttempts,
    List<String>? allowedFileFormats,
    int? maxFileSizeMB,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? courseName,
    String? courseCode,
    String? instructorName,
    int? totalStudents,
    int? submittedCount,
    int? pendingCount,
    int? lateSubmissionCount,
    int? gradedCount,
  }) {
    return AssignmentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy ?? this.createdBy,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      lateDeadline: lateDeadline ?? this.lateDeadline,
      maxSubmissionAttempts: maxSubmissionAttempts ?? this.maxSubmissionAttempts,
      allowedFileFormats: allowedFileFormats ?? this.allowedFileFormats,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructorName: instructorName ?? this.instructorName,
      totalStudents: totalStudents ?? this.totalStudents,
      submittedCount: submittedCount ?? this.submittedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      lateSubmissionCount: lateSubmissionCount ?? this.lateSubmissionCount,
      gradedCount: gradedCount ?? this.gradedCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        courseId,
        createdBy,
        attachmentUrls,
        targetGroupIds,
        startDate,
        deadline,
        allowLateSubmission,
        lateDeadline,
        maxSubmissionAttempts,
        allowedFileFormats,
        maxFileSizeMB,
        createdAt,
        updatedAt,
        courseName,
        courseCode,
        instructorName,
        totalStudents,
        submittedCount,
        pendingCount,
        lateSubmissionCount,
        gradedCount,
      ];
}
