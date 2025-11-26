// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';
// import 'announcement_model.dart'; // For AttachmentModel

// part 'assignment_submission_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdAssignmentSubmission)
// class AssignmentSubmissionModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String assignmentId;

//   @HiveField(2)
//   final String studentId;

//   @HiveField(3)
//   final String studentName;

//   @HiveField(4)
//   final List<AttachmentModel> files;

//   @HiveField(5)
//   final int attemptNumber; // 1, 2, 3, etc.

//   @HiveField(6)
//   final DateTime submittedAt;

//   @HiveField(7)
//   final bool isLate;

//   @HiveField(8)
//   final double? grade; // null if not graded yet

//   @HiveField(9)
//   final String? feedback;

//   @HiveField(10)
//   final DateTime? gradedAt;

//   @HiveField(11)
//   final String? gradedBy; // Instructor ID

//   AssignmentSubmissionModel({
//     required this.id,
//     required this.assignmentId,
//     required this.studentId,
//     required this.studentName,
//     required this.files,
//     required this.attemptNumber,
//     required this.submittedAt,
//     required this.isLate,
//     this.grade,
//     this.feedback,
//     this.gradedAt,
//     this.gradedBy,
//   });

//   // Check if submission is graded
//   bool get isGraded => grade != null;

//   // Get status
//   String get status {
//     if (isGraded) return AppConstants.assignmentStatusGraded;
//     if (isLate) return AppConstants.assignmentStatusLate;
//     return AppConstants.assignmentStatusSubmitted;
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'assignmentId': assignmentId,
//       'studentId': studentId,
//       'studentName': studentName,
//       'files': files.map((f) => f.toJson()).toList(),
//       'attemptNumber': attemptNumber,
//       'submittedAt': submittedAt.toIso8601String(),
//       'isLate': isLate,
//       'grade': grade,
//       'feedback': feedback,
//       'gradedAt': gradedAt?.toIso8601String(),
//       'gradedBy': gradedBy,
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
//     return AssignmentSubmissionModel(
//       id: json['id'] as String,
//       assignmentId: json['assignmentId'] as String,
//       studentId: json['studentId'] as String,
//       studentName: json['studentName'] as String,
//       files: (json['files'] as List<dynamic>?)
//               ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       attemptNumber: json['attemptNumber'] as int,
//       submittedAt: json['submittedAt'] is String
//           ? DateTime.parse(json['submittedAt'])
//           : (json['submittedAt'] as DateTime),
//       isLate: json['isLate'] as bool? ?? false,
//       grade: (json['grade'] as num?)?.toDouble(),
//       feedback: json['feedback'] as String?,
//       gradedAt: json['gradedAt'] != null
//           ? (json['gradedAt'] is String
//               ? DateTime.parse(json['gradedAt'])
//               : (json['gradedAt'] as DateTime))
//           : null,
//       gradedBy: json['gradedBy'] as String?,
//     );
//   }

//   // Create a copy with updated fields
//   AssignmentSubmissionModel copyWith({
//     String? id,
//     String? assignmentId,
//     String? studentId,
//     String? studentName,
//     List<AttachmentModel>? files,
//     int? attemptNumber,
//     DateTime? submittedAt,
//     bool? isLate,
//     double? grade,
//     String? feedback,
//     DateTime? gradedAt,
//     String? gradedBy,
//   }) {
//     return AssignmentSubmissionModel(
//       id: id ?? this.id,
//       assignmentId: assignmentId ?? this.assignmentId,
//       studentId: studentId ?? this.studentId,
//       studentName: studentName ?? this.studentName,
//       files: files ?? this.files,
//       attemptNumber: attemptNumber ?? this.attemptNumber,
//       submittedAt: submittedAt ?? this.submittedAt,
//       isLate: isLate ?? this.isLate,
//       grade: grade ?? this.grade,
//       feedback: feedback ?? this.feedback,
//       gradedAt: gradedAt ?? this.gradedAt,
//       gradedBy: gradedBy ?? this.gradedBy,
//     );
//   }

//   @override
//   String toString() {
//     return 'AssignmentSubmissionModel(id: $id, assignmentId: $assignmentId, studentId: $studentId, attemptNumber: $attemptNumber)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is AssignmentSubmissionModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
