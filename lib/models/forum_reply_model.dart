import 'package:hive/hive.dart';
import '../config/app_constants.dart';
import 'announcement_model.dart'; // For AttachmentModel

part 'forum_reply_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdForumReply)
class ForumReplyModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String topicId;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String authorId;

  @HiveField(4)
  final String authorName;

  @HiveField(5)
  final String authorRole; // 'instructor' or 'student'

  @HiveField(6)
  final List<AttachmentModel> attachments;

  @HiveField(7)
  final String? parentReplyId; // For threaded replies (null if top-level reply)

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  ForumReplyModel({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.attachments,
    this.parentReplyId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if author is instructor
  bool get isAuthorInstructor => authorRole == AppConstants.roleInstructor;

  // Check if this is a nested reply (reply to a reply)
  bool get isNestedReply => parentReplyId != null;

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'parentReplyId': parentReplyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (from Firestore)
  factory ForumReplyModel.fromJson(Map<String, dynamic> json) {
    return ForumReplyModel(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorRole: json['authorRole'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      parentReplyId: json['parentReplyId'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime),
    );
  }

  // Create a copy with updated fields
  ForumReplyModel copyWith({
    String? id,
    String? topicId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorRole,
    List<AttachmentModel>? attachments,
    String? parentReplyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForumReplyModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      attachments: attachments ?? this.attachments,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ForumReplyModel(id: $id, topicId: $topicId, authorName: $authorName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ForumReplyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
