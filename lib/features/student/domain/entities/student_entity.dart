import 'package:equatable/equatable.dart';

/// Represents a student's enrollment in a group for a specific course
class StudentEnrollmentEntity extends Equatable {
  final String id;
  final String studentId; // References UserEntity with role=student
  final String groupId;
  final String courseId;
  final String semesterId;
  final DateTime enrolledAt;
  final DateTime? updatedAt;

  // Computed/additional properties (from joins)
  final String? studentName;
  final String? studentEmail;
  final String? studentAvatarUrl;
  final String? groupName;
  final String? courseName;
  final String? courseCode;

  const StudentEnrollmentEntity({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.courseId,
    required this.semesterId,
    required this.enrolledAt,
    this.updatedAt,
    this.studentName,
    this.studentEmail,
    this.studentAvatarUrl,
    this.groupName,
    this.courseName,
    this.courseCode,
  });

  StudentEnrollmentEntity copyWith({
    String? id,
    String? studentId,
    String? groupId,
    String? courseId,
    String? semesterId,
    DateTime? enrolledAt,
    DateTime? updatedAt,
    String? studentName,
    String? studentEmail,
    String? studentAvatarUrl,
    String? groupName,
    String? courseName,
    String? courseCode,
  }) {
    return StudentEnrollmentEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      courseId: courseId ?? this.courseId,
      semesterId: semesterId ?? this.semesterId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentAvatarUrl: studentAvatarUrl ?? this.studentAvatarUrl,
      groupName: groupName ?? this.groupName,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        groupId,
        courseId,
        semesterId,
        enrolledAt,
        updatedAt,
        studentName,
        studentEmail,
        studentAvatarUrl,
        groupName,
        courseName,
        courseCode,
      ];
}
