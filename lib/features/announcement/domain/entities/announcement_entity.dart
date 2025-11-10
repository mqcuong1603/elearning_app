import 'package:equatable/equatable.dart';

class AnnouncementEntity extends Equatable {
  final String id;
  final String title;
  final String content; // Rich text content
  final String courseId;
  final String createdBy; // Instructor ID
  final List<String> attachmentUrls; // File URLs
  final List<String> targetGroupIds; // One, multiple, or all groups
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/tracking properties
  final String? courseName;
  final String? courseCode;
  final String? instructorName;
  final int? viewCount; // Number of students who viewed
  final int? downloadCount; // Number of file downloads
  final List<String>? viewedByStudentIds; // Track who viewed
  final int? commentCount;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.courseId,
    required this.createdBy,
    required this.attachmentUrls,
    required this.targetGroupIds,
    required this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
    this.instructorName,
    this.viewCount,
    this.downloadCount,
    this.viewedByStudentIds,
    this.commentCount,
  });

  bool isTargetedToGroup(String groupId) {
    return targetGroupIds.contains(groupId);
  }

  bool isTargetedToAllGroups(List<String> allGroupIds) {
    return targetGroupIds.length == allGroupIds.length &&
        targetGroupIds.every((id) => allGroupIds.contains(id));
  }

  AnnouncementEntity copyWith({
    String? id,
    String? title,
    String? content,
    String? courseId,
    String? createdBy,
    List<String>? attachmentUrls,
    List<String>? targetGroupIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? courseName,
    String? courseCode,
    String? instructorName,
    int? viewCount,
    int? downloadCount,
    List<String>? viewedByStudentIds,
    int? commentCount,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy ?? this.createdBy,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructorName: instructorName ?? this.instructorName,
      viewCount: viewCount ?? this.viewCount,
      downloadCount: downloadCount ?? this.downloadCount,
      viewedByStudentIds: viewedByStudentIds ?? this.viewedByStudentIds,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        courseId,
        createdBy,
        attachmentUrls,
        targetGroupIds,
        createdAt,
        updatedAt,
        courseName,
        courseCode,
        instructorName,
        viewCount,
        downloadCount,
        viewedByStudentIds,
        commentCount,
      ];
}
