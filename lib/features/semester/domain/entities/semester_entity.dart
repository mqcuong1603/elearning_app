import 'package:equatable/equatable.dart';

class SemesterEntity extends Equatable {
  final String id;
  final String code; // e.g., "2025-1", "2025-2"
  final String name; // e.g., "Semester 1 - Academic Year 2025-2026"
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent; // Is this the current/active semester?
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional computed properties
  final int? courseCount; // Number of courses in this semester
  final int? studentCount; // Number of students enrolled

  const SemesterEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.createdAt,
    this.updatedAt,
    this.courseCount,
    this.studentCount,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isPast => DateTime.now().isAfter(endDate);
  bool get isFuture => DateTime.now().isBefore(startDate);

  SemesterEntity copyWith({
    String? id,
    String? code,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? courseCount,
    int? studentCount,
  }) {
    return SemesterEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseCount: courseCount ?? this.courseCount,
      studentCount: studentCount ?? this.studentCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        startDate,
        endDate,
        isCurrent,
        createdAt,
        updatedAt,
        courseCount,
        studentCount,
      ];
}
