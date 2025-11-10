import 'package:equatable/equatable.dart';

class GroupEntity extends Equatable {
  final String id;
  final String name; // e.g., "Group 1", "Group 2", "Group 3"
  final String courseId;
  final String semesterId; // Denormalized for easier querying
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/additional properties
  final String? courseName;
  final String? courseCode;
  final int? studentCount; // Number of students in this group
  final List<String>? studentIds; // IDs of students in this group

  const GroupEntity({
    required this.id,
    required this.name,
    required this.courseId,
    required this.semesterId,
    required this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
    this.studentCount,
    this.studentIds,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    String? courseId,
    String? semesterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? courseName,
    String? courseCode,
    int? studentCount,
    List<String>? studentIds,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      studentCount: studentCount ?? this.studentCount,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        courseId,
        semesterId,
        createdAt,
        updatedAt,
        courseName,
        courseCode,
        studentCount,
        studentIds,
      ];
}
