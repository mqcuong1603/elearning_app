// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';
// import 'announcement_model.dart'; // For AttachmentModel

// part 'forum_topic_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdForumTopic)
// class ForumTopicModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String courseId;

//   @HiveField(2)
//   final String title;

//   @HiveField(3)
//   final String content;

//   @HiveField(4)
//   final String authorId;

//   @HiveField(5)
//   final String authorName;

//   @HiveField(6)
//   final String authorRole; // 'instructor' or 'student'

//   @HiveField(7)
//   final List<AttachmentModel> attachments;

//   @HiveField(8)
//   final DateTime createdAt;

//   @HiveField(9)
//   final DateTime updatedAt;

//   @HiveField(10)
//   final int replyCount;

//   @HiveField(11)
//   final bool isPinned; // For important topics

//   ForumTopicModel({
//     required this.id,
//     required this.courseId,
//     required this.title,
//     required this.content,
//     required this.authorId,
//     required this.authorName,
//     required this.authorRole,
//     required this.attachments,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.replyCount,
//     required this.isPinned,
//   });

//   // Check if author is instructor
//   bool get isAuthorInstructor => authorRole == AppConstants.roleInstructor;

//   // Check if topic has replies
//   bool get hasReplies => replyCount > 0;

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'title': title,
//       'content': content,
//       'authorId': authorId,
//       'authorName': authorName,
//       'authorRole': authorRole,
//       'attachments': attachments.map((a) => a.toJson()).toList(),
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//       'replyCount': replyCount,
//       'isPinned': isPinned,
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
//     return ForumTopicModel(
//       id: json['id'] as String,
//       courseId: json['courseId'] as String,
//       title: json['title'] as String,
//       content: json['content'] as String,
//       authorId: json['authorId'] as String,
//       authorName: json['authorName'] as String,
//       authorRole: json['authorRole'] as String,
//       attachments: (json['attachments'] as List<dynamic>?)
//               ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       updatedAt: json['updatedAt'] is String
//           ? DateTime.parse(json['updatedAt'])
//           : (json['updatedAt'] as DateTime),
//       replyCount: json['replyCount'] as int? ?? 0,
//       isPinned: json['isPinned'] as bool? ?? false,
//     );
//   }

//   // Create a copy with updated fields
//   ForumTopicModel copyWith({
//     String? id,
//     String? courseId,
//     String? title,
//     String? content,
//     String? authorId,
//     String? authorName,
//     String? authorRole,
//     List<AttachmentModel>? attachments,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     int? replyCount,
//     bool? isPinned,
//   }) {
//     return ForumTopicModel(
//       id: id ?? this.id,
//       courseId: courseId ?? this.courseId,
//       title: title ?? this.title,
//       content: content ?? this.content,
//       authorId: authorId ?? this.authorId,
//       authorName: authorName ?? this.authorName,
//       authorRole: authorRole ?? this.authorRole,
//       attachments: attachments ?? this.attachments,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       replyCount: replyCount ?? this.replyCount,
//       isPinned: isPinned ?? this.isPinned,
//     );
//   }

//   @override
//   String toString() {
//     return 'ForumTopicModel(id: $id, title: $title, replyCount: $replyCount)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is ForumTopicModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
