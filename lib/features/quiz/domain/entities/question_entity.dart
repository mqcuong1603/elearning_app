import 'package:equatable/equatable.dart';

enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

class QuestionEntity extends Equatable {
  final String id;
  final String courseId; // Course-specific question bank
  final String questionText;
  final List<String> choices; // Multiple choice options
  final int correctAnswerIndex; // Index of correct answer in choices
  final QuestionDifficulty difficulty;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? explanation; // Optional explanation for the correct answer

  const QuestionEntity({
    required this.id,
    required this.courseId,
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.createdAt,
    this.updatedAt,
    this.explanation,
  });

  String get correctAnswer {
    if (correctAnswerIndex >= 0 && correctAnswerIndex < choices.length) {
      return choices[correctAnswerIndex];
    }
    return '';
  }

  bool isCorrectAnswer(int selectedIndex) {
    return selectedIndex == correctAnswerIndex;
  }

  QuestionEntity copyWith({
    String? id,
    String? courseId,
    String? questionText,
    List<String>? choices,
    int? correctAnswerIndex,
    QuestionDifficulty? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? explanation,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      questionText: questionText ?? this.questionText,
      choices: choices ?? this.choices,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        questionText,
        choices,
        correctAnswerIndex,
        difficulty,
        createdAt,
        updatedAt,
        explanation,
      ];
}
