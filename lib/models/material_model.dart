import 'package:hive/hive.dart';
import '../config/app_constants.dart';
import 'announcement_model.dart'; // For AttachmentModel

part 'material_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdMaterial)
class MaterialModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String courseId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final List<AttachmentModel> files; // Uploaded files

  @HiveField(5)
  final List<LinkModel> links; // External links

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
      downloadedBy; // {fileId: [userId1, userId2]}

  MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.files,
    required this.links,
    required this.instructorId,
    required this.instructorName,
    required this.createdAt,
    required this.updatedAt,
    required this.viewedBy,
    required this.downloadedBy,
  });

  // Check if user has viewed
  bool hasViewedBy(String userId) => viewedBy.contains(userId);

  // Get view count
  int get viewCount => viewedBy.length;

  // Check if material has files
  bool get hasFiles => files.isNotEmpty;

  // Check if material has links
  bool get hasLinks => links.isNotEmpty;

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'files': files.map((f) => f.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
      'instructorId': instructorId,
      'instructorName': instructorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewedBy': viewedBy,
      'downloadedBy': downloadedBy,
    };
  }

  // Create from JSON (from Firestore)
  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => LinkModel.fromJson(e as Map<String, dynamic>))
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
  MaterialModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    List<AttachmentModel>? files,
    List<LinkModel>? links,
    String? instructorId,
    String? instructorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? viewedBy,
    Map<String, List<String>>? downloadedBy,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      files: files ?? this.files,
      links: links ?? this.links,
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
    return 'MaterialModel(id: $id, title: $title, courseId: $courseId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MaterialModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Link Model
@HiveType(typeId: 103) // Using 103 for nested model
class LinkModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String title;

  LinkModel({
    required this.id,
    required this.url,
    required this.title,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
    };
  }

  // Create from JSON
  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
    );
  }

  LinkModel copyWith({
    String? id,
    String? url,
    String? title,
  }) {
    return LinkModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
    );
  }
}
