import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String code; // e.g., "IT101", "CS201"
  final String name; // e.g., "Web Programming & Applications", "Database Systems"
  final String description;
  final String semesterId;
  final String instructorId; // Always the admin user
  final String? coverImageUrl;
  final int sessions; // 10 or 15 sessions
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/additional properties (populated from joins)
  final String? semesterName;
  final String? instructorName;
  final int? groupCount; // Number of groups in this course
  final int? studentCount; // Total students enrolled
  final int? assignmentCount;
  final int? quizCount;
  final int? materialCount;
  final int? announcementCount;

  const CourseEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.semesterId,
    required this.instructorId,
    this.coverImageUrl,
    required this.sessions,
    required this.createdAt,
    this.updatedAt,
    this.semesterName,
    this.instructorName,
    this.groupCount,
    this.studentCount,
    this.assignmentCount,
    this.quizCount,
    this.materialCount,
    this.announcementCount,
  });

  CourseEntity copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? semesterId,
    String? instructorId,
    String? coverImageUrl,
    int? sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? semesterName,
    String? instructorName,
    int? groupCount,
    int? studentCount,
    int? assignmentCount,
    int? quizCount,
    int? materialCount,
    int? announcementCount,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      semesterId: semesterId ?? this.semesterId,
      instructorId: instructorId ?? this.instructorId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      sessions: sessions ?? this.sessions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      semesterName: semesterName ?? this.semesterName,
      instructorName: instructorName ?? this.instructorName,
      groupCount: groupCount ?? this.groupCount,
      studentCount: studentCount ?? this.studentCount,
      assignmentCount: assignmentCount ?? this.assignmentCount,
      quizCount: quizCount ?? this.quizCount,
      materialCount: materialCount ?? this.materialCount,
      announcementCount: announcementCount ?? this.announcementCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        semesterId,
        instructorId,
        coverImageUrl,
        sessions,
        createdAt,
        updatedAt,
        semesterName,
        instructorName,
        groupCount,
        studentCount,
        assignmentCount,
        quizCount,
        materialCount,
        announcementCount,
      ];
}
