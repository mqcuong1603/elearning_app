import 'package:equatable/equatable.dart';

class MaterialEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String createdBy; // Instructor ID
  final List<String> fileUrls; // One or more files
  final List<String> linkUrls; // One or more links
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Note: Materials are automatically visible to ALL students in a course
  // No group scoping unlike announcements/assignments

  // Computed/tracking properties
  final String? courseName;
  final String? courseCode;
  final String? instructorName;
  final int? viewCount; // Number of students who viewed
  final int? downloadCount; // Number of file downloads
  final List<String>? viewedByStudentIds; // Track who viewed
  final List<String>? downloadedByStudentIds; // Track who downloaded

  const MaterialEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.createdBy,
    required this.fileUrls,
    required this.linkUrls,
    required this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
    this.instructorName,
    this.viewCount,
    this.downloadCount,
    this.viewedByStudentIds,
    this.downloadedByStudentIds,
  });

  bool get hasFiles => fileUrls.isNotEmpty;
  bool get hasLinks => linkUrls.isNotEmpty;
  int get totalResources => fileUrls.length + linkUrls.length;

  MaterialEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? createdBy,
    List<String>? fileUrls,
    List<String>? linkUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? courseName,
    String? courseCode,
    String? instructorName,
    int? viewCount,
    int? downloadCount,
    List<String>? viewedByStudentIds,
    List<String>? downloadedByStudentIds,
  }) {
    return MaterialEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy ?? this.createdBy,
      fileUrls: fileUrls ?? this.fileUrls,
      linkUrls: linkUrls ?? this.linkUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructorName: instructorName ?? this.instructorName,
      viewCount: viewCount ?? this.viewCount,
      downloadCount: downloadCount ?? this.downloadCount,
      viewedByStudentIds: viewedByStudentIds ?? this.viewedByStudentIds,
      downloadedByStudentIds: downloadedByStudentIds ?? this.downloadedByStudentIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        courseId,
        createdBy,
        fileUrls,
        linkUrls,
        createdAt,
        updatedAt,
        courseName,
        courseCode,
        instructorName,
        viewCount,
        downloadCount,
        viewedByStudentIds,
        downloadedByStudentIds,
      ];
}
