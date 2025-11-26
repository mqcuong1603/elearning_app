// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';

// part 'question_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdQuestion)
// class QuestionModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String courseId;

//   @HiveField(2)
//   final String questionText;

//   @HiveField(3)
//   final List<ChoiceModel> choices; // Multiple choice options

//   @HiveField(4)
//   final String difficulty; // 'easy', 'medium', 'hard'

//   @HiveField(5)
//   final DateTime createdAt;

//   @HiveField(6)
//   final DateTime updatedAt;

//   QuestionModel({
//     required this.id,
//     required this.courseId,
//     required this.questionText,
//     required this.choices,
//     required this.difficulty,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // Get correct choice
//   ChoiceModel? get correctChoice {
//     try {
//       return choices.firstWhere((choice) => choice.isCorrect);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Validate that question has exactly one correct answer
//   bool get isValid {
//     final correctCount = choices.where((choice) => choice.isCorrect).length;
//     return correctCount == 1 && choices.length >= 2;
//   }

//   // Check if a choice is correct
//   bool isChoiceCorrect(String choiceId) {
//     final choice = choices.where((c) => c.id == choiceId).firstOrNull;
//     return choice?.isCorrect ?? false;
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'questionText': questionText,
//       'choices': choices.map((c) => c.toJson()).toList(),
//       'difficulty': difficulty,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory QuestionModel.fromJson(Map<String, dynamic> json) {
//     return QuestionModel(
//       id: json['id'] as String,
//       courseId: json['courseId'] as String,
//       questionText: json['questionText'] as String,
//       choices: (json['choices'] as List<dynamic>?)
//               ?.map((e) => ChoiceModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       difficulty: json['difficulty'] as String? ?? AppConstants.difficultyMedium,
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       updatedAt: json['updatedAt'] is String
//           ? DateTime.parse(json['updatedAt'])
//           : (json['updatedAt'] as DateTime),
//     );
//   }

//   // Create a copy with updated fields
//   QuestionModel copyWith({
//     String? id,
//     String? courseId,
//     String? questionText,
//     List<ChoiceModel>? choices,
//     String? difficulty,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return QuestionModel(
//       id: id ?? this.id,
//       courseId: courseId ?? this.courseId,
//       questionText: questionText ?? this.questionText,
//       choices: choices ?? this.choices,
//       difficulty: difficulty ?? this.difficulty,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   @override
//   String toString() {
//     return 'QuestionModel(id: $id, questionText: $questionText, difficulty: $difficulty)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is QuestionModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }

// // Choice Model for quiz questions
// @HiveType(typeId: 101) // Using 101 for nested model
// class ChoiceModel {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String text;

//   @HiveField(2)
//   final bool isCorrect;

//   ChoiceModel({
//     required this.id,
//     required this.text,
//     required this.isCorrect,
//   });

//   // Convert to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'text': text,
//       'isCorrect': isCorrect,
//     };
//   }

//   // Create from JSON
//   factory ChoiceModel.fromJson(Map<String, dynamic> json) {
//     return ChoiceModel(
//       id: json['id'] as String,
//       text: json['text'] as String,
//       isCorrect: json['isCorrect'] as bool,
//     );
//   }

//   ChoiceModel copyWith({
//     String? id,
//     String? text,
//     bool? isCorrect,
//   }) {
//     return ChoiceModel(
//       id: id ?? this.id,
//       text: text ?? this.text,
//       isCorrect: isCorrect ?? this.isCorrect,
//     );
//   }
// }
