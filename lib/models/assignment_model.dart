// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';
// import 'announcement_model.dart'; // For AttachmentModel

// part 'assignment_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdAssignment)
// class AssignmentModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String courseId;

//   @HiveField(2)
//   final String title;

//   @HiveField(3)
//   final String description;

//   @HiveField(4)
//   final List<AttachmentModel> attachments;

//   @HiveField(5)
//   final DateTime startDate;

//   @HiveField(6)
//   final DateTime deadline;

//   @HiveField(7)
//   final bool allowLateSubmission;

//   @HiveField(8)
//   final DateTime? lateDeadline;

//   @HiveField(9)
//   final int maxAttempts;

//   @HiveField(10)
//   final List<String> allowedFileFormats; // e.g., ['pdf', 'doc', 'docx']

//   @HiveField(11)
//   final int maxFileSize; // in bytes

//   @HiveField(12)
//   final List<String> groupIds; // Scope: which groups can see this

//   @HiveField(13)
//   final String instructorId;

//   @HiveField(14)
//   final String instructorName;

//   @HiveField(15)
//   final DateTime createdAt;

//   @HiveField(16)
//   final DateTime updatedAt;

//   AssignmentModel({
//     required this.id,
//     required this.courseId,
//     required this.title,
//     required this.description,
//     required this.attachments,
//     required this.startDate,
//     required this.deadline,
//     required this.allowLateSubmission,
//     this.lateDeadline,
//     required this.maxAttempts,
//     required this.allowedFileFormats,
//     required this.maxFileSize,
//     required this.groupIds,
//     required this.instructorId,
//     required this.instructorName,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // Check if assignment is currently open
//   bool get isOpen {
//     final now = DateTime.now();
//     return now.isAfter(startDate) && now.isBefore(deadline);
//   }

//   // Check if assignment is closed
//   bool get isClosed {
//     final now = DateTime.now();
//     if (allowLateSubmission && lateDeadline != null) {
//       return now.isAfter(lateDeadline!);
//     }
//     return now.isAfter(deadline);
//   }

//   // Check if assignment is in late submission period
//   bool get isInLatePeriod {
//     if (!allowLateSubmission || lateDeadline == null) return false;
//     final now = DateTime.now();
//     return now.isAfter(deadline) && now.isBefore(lateDeadline!);
//   }

//   // Check if assignment hasn't started yet
//   bool get isUpcoming {
//     return DateTime.now().isBefore(startDate);
//   }

//   // Check if assignment is for all groups
//   bool get isForAllGroups => groupIds.isEmpty;

//   // Get formatted max file size
//   String get formattedMaxFileSize => AppConstants.formatFileSize(maxFileSize);

//   // Validate file format
//   bool isValidFileFormat(String filename) {
//     final extension = AppConstants.getFileExtension(filename);
//     return allowedFileFormats.contains(extension);
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'title': title,
//       'description': description,
//       'attachments': attachments.map((a) => a.toJson()).toList(),
//       'startDate': startDate.toIso8601String(),
//       'deadline': deadline.toIso8601String(),
//       'allowLateSubmission': allowLateSubmission,
//       'lateDeadline': lateDeadline?.toIso8601String(),
//       'maxAttempts': maxAttempts,
//       'allowedFileFormats': allowedFileFormats,
//       'maxFileSize': maxFileSize,
//       'groupIds': groupIds,
//       'instructorId': instructorId,
//       'instructorName': instructorName,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory AssignmentModel.fromJson(Map<String, dynamic> json) {
//     return AssignmentModel(
//       id: json['id'] as String,
//       courseId: json['courseId'] as String,
//       title: json['title'] as String,
//       description: json['description'] as String,
//       attachments: (json['attachments'] as List<dynamic>?)
//               ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       startDate: json['startDate'] is String
//           ? DateTime.parse(json['startDate'])
//           : (json['startDate'] as DateTime),
//       deadline: json['deadline'] is String
//           ? DateTime.parse(json['deadline'])
//           : (json['deadline'] as DateTime),
//       allowLateSubmission: json['allowLateSubmission'] as bool? ?? false,
//       lateDeadline: json['lateDeadline'] != null
//           ? (json['lateDeadline'] is String
//               ? DateTime.parse(json['lateDeadline'])
//               : (json['lateDeadline'] as DateTime))
//           : null,
//       maxAttempts: json['maxAttempts'] as int? ?? AppConstants.defaultMaxAttempts,
//       allowedFileFormats: (json['allowedFileFormats'] as List<dynamic>?)
//               ?.map((e) => e as String)
//               .toList() ??
//           [],
//       maxFileSize: json['maxFileSize'] as int? ?? AppConstants.maxFileSizeBytes,
//       groupIds: (json['groupIds'] as List<dynamic>?)
//               ?.map((e) => e as String)
//               .toList() ??
//           [],
//       instructorId: json['instructorId'] as String,
//       instructorName: json['instructorName'] as String,
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       updatedAt: json['updatedAt'] is String
//           ? DateTime.parse(json['updatedAt'])
//           : (json['updatedAt'] as DateTime),
//     );
//   }

//   // Create a copy with updated fields
//   AssignmentModel copyWith({
//     String? id,
//     String? courseId,
//     String? title,
//     String? description,
//     List<AttachmentModel>? attachments,
//     DateTime? startDate,
//     DateTime? deadline,
//     bool? allowLateSubmission,
//     DateTime? lateDeadline,
//     int? maxAttempts,
//     List<String>? allowedFileFormats,
//     int? maxFileSize,
//     List<String>? groupIds,
//     String? instructorId,
//     String? instructorName,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return AssignmentModel(
//       id: id ?? this.id,
//       courseId: courseId ?? this.courseId,
//       title: title ?? this.title,
//       description: description ?? this.description,
//       attachments: attachments ?? this.attachments,
//       startDate: startDate ?? this.startDate,
//       deadline: deadline ?? this.deadline,
//       allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
//       lateDeadline: lateDeadline ?? this.lateDeadline,
//       maxAttempts: maxAttempts ?? this.maxAttempts,
//       allowedFileFormats: allowedFileFormats ?? this.allowedFileFormats,
//       maxFileSize: maxFileSize ?? this.maxFileSize,
//       groupIds: groupIds ?? this.groupIds,
//       instructorId: instructorId ?? this.instructorId,
//       instructorName: instructorName ?? this.instructorName,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   @override
//   String toString() {
//     return 'AssignmentModel(id: $id, title: $title, courseId: $courseId)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is AssignmentModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
