import 'package:hive/hive.dart';
import '../config/app_constants.dart';

part 'announcement_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdAnnouncement)
class AnnouncementModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String courseId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String content; // Rich text content

  @HiveField(4)
  final List<AttachmentModel> attachments;

  @HiveField(5)
  final List<String> groupIds; // Scope: which groups can see this

  @HiveField(6)
  final String instructorId;

  @HiveField(7)
  final String instructorName;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final List<String> viewedBy; // User IDs who viewed this

  @HiveField(11)
  final Map<String, List<String>>
      downloadedBy; // {attachmentId: [userId1, userId2]}

  AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.attachments,
    required this.groupIds,
    required this.instructorId,
    required this.instructorName,
    required this.createdAt,
    required this.updatedAt,
    required this.viewedBy,
    required this.downloadedBy,
  });

  // Check if announcement is for all groups
  bool get isForAllGroups => groupIds.isEmpty;

  // Check if user has viewed
  bool hasViewedBy(String userId) => viewedBy.contains(userId);

  // Get view count
  int get viewCount => viewedBy.length;

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'groupIds': groupIds,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewedBy': viewedBy,
      'downloadedBy': downloadedBy,
    };
  }

  // Create from JSON (from Firestore)
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      groupIds: (json['groupIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      instructorId: json['instructorId'] as String,
      instructorName: json['instructorName'] as String,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime),
      viewedBy: (json['viewedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      downloadedBy: (json['downloadedBy'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          {},
    );
  }

  // Create a copy with updated fields
  AnnouncementModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? content,
    List<AttachmentModel>? attachments,
    List<String>? groupIds,
    String? instructorId,
    String? instructorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? viewedBy,
    Map<String, List<String>>? downloadedBy,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      groupIds: groupIds ?? this.groupIds,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewedBy: viewedBy ?? this.viewedBy,
      downloadedBy: downloadedBy ?? this.downloadedBy,
    );
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title, courseId: $courseId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnouncementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Attachment Model for reusability
@HiveType(typeId: 100) // Using 100+ for nested models
class AttachmentModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String filename;

  @HiveField(3)
  final int size; // in bytes

  @HiveField(4)
  final String type; // e.g., 'pdf', 'jpg', 'doc'

  AttachmentModel({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.type,
  });

  // Get formatted size
  String get formattedSize => AppConstants.formatFileSize(size);

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'size': size,
      'type': type,
    };
  }

  // Create from JSON
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      size: json['size'] as int,
      type: json['type'] as String,
    );
  }

  AttachmentModel copyWith({
    String? id,
    String? url,
    String? filename,
    int? size,
    String? type,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }
}
