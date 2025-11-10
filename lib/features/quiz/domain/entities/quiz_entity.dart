import 'package:equatable/equatable.dart';

class QuizEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String createdBy; // Instructor ID
  final List<String> targetGroupIds; // Scoped to specific groups

  // Quiz settings
  final DateTime openTime; // When quiz becomes available
  final DateTime closeTime; // When quiz closes
  final int maxAttempts; // Number of attempts allowed
  final int durationMinutes; // Duration in minutes

  // Random question selection structure
  final int easyQuestionsCount; // x easy questions
  final int mediumQuestionsCount; // y medium questions
  final int hardQuestionsCount; // z hard questions

  // Can be randomly selected from question bank or fixed questions
  final List<String>? fixedQuestionIds; // If null, randomly select from bank

  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/tracking properties
  final String? courseName;
  final String? courseCode;
  final String? instructorName;
  final int? totalStudents; // Total students who should take the quiz
  final int? completedCount; // Number of students who completed
  final int? pendingCount; // Not yet taken
  final double? averageScore; // Average score across all attempts

  const QuizEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.createdBy,
    required this.targetGroupIds,
    required this.openTime,
    required this.closeTime,
    required this.maxAttempts,
    required this.durationMinutes,
    required this.easyQuestionsCount,
    required this.mediumQuestionsCount,
    required this.hardQuestionsCount,
    this.fixedQuestionIds,
    required this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
    this.instructorName,
    this.totalStudents,
    this.completedCount,
    this.pendingCount,
    this.averageScore,
  });

  int get totalQuestions => easyQuestionsCount + mediumQuestionsCount + hardQuestionsCount;

  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(openTime) && now.isBefore(closeTime);
  }

  bool get isClosed => DateTime.now().isAfter(closeTime);

  bool get isUpcoming => DateTime.now().isBefore(openTime);

  QuizEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? createdBy,
    List<String>? targetGroupIds,
    DateTime? openTime,
    DateTime? closeTime,
    int? maxAttempts,
    int? durationMinutes,
    int? easyQuestionsCount,
    int? mediumQuestionsCount,
    int? hardQuestionsCount,
    List<String>? fixedQuestionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? courseName,
    String? courseCode,
    String? instructorName,
    int? totalStudents,
    int? completedCount,
    int? pendingCount,
    double? averageScore,
  }) {
    return QuizEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy ?? this.createdBy,
      targetGroupIds: targetGroupIds ?? this.targetGroupIds,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      easyQuestionsCount: easyQuestionsCount ?? this.easyQuestionsCount,
      mediumQuestionsCount: mediumQuestionsCount ?? this.mediumQuestionsCount,
      hardQuestionsCount: hardQuestionsCount ?? this.hardQuestionsCount,
      fixedQuestionIds: fixedQuestionIds ?? this.fixedQuestionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructorName: instructorName ?? this.instructorName,
      totalStudents: totalStudents ?? this.totalStudents,
      completedCount: completedCount ?? this.completedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      averageScore: averageScore ?? this.averageScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        courseId,
        createdBy,
        targetGroupIds,
        openTime,
        closeTime,
        maxAttempts,
        durationMinutes,
        easyQuestionsCount,
        mediumQuestionsCount,
        hardQuestionsCount,
        fixedQuestionIds,
        createdAt,
        updatedAt,
        courseName,
        courseCode,
        instructorName,
        totalStudents,
        completedCount,
        pendingCount,
        averageScore,
      ];
}
