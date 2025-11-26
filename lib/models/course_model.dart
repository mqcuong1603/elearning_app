import 'package:hive/hive.dart';
import '../config/app_constants.dart';

part 'course_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdCourse)
class CourseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code; // e.g., "CS101", "IT202"

  @HiveField(2)
  final String name; // e.g., "Introduction to Programming"

  @HiveField(3)
  final String semesterId; // Reference to semester

  @HiveField(4)
  final int sessions; // 10 or 15

  @HiveField(5)
  final String? coverImageUrl;

  @HiveField(6)
  final String? description;

  @HiveField(7)
  final String instructorId;

  @HiveField(8)
  final String instructorName;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.semesterId,
    required this.sessions,
    this.coverImageUrl,
    this.description,
    required this.instructorId,
    required this.instructorName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get display text
  String get displayText => '$code - $name';

  // Get full display text with instructor
  String get fullDisplayText => '$code - $name (Instructor: $instructorName)';

  // Validate sessions count
  bool get hasValidSessions =>
      AppConstants.allowedCourseSessions.contains(sessions);

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'semesterId': semesterId,
      'sessions': sessions,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (from Firestore)
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      semesterId: json['semesterId'] as String,
      sessions: json['sessions'] as int? ?? AppConstants.defaultCourseSessions,
      coverImageUrl: json['coverImageUrl'] as String?,
      description: json['description'] as String?,
      instructorId: json['instructorId'] as String,
      instructorName: json['instructorName'] as String,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime),
    );
  }

  // Create a copy with updated fields
  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    String? semesterId,
    int? sessions,
    String? coverImageUrl,
    String? description,
    String? instructorId,
    String? instructorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      semesterId: semesterId ?? this.semesterId,
      sessions: sessions ?? this.sessions,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CourseModel(id: $id, code: $code, name: $name, sessions: $sessions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
