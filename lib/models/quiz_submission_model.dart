// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';

// part 'quiz_submission_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdQuizSubmission)
// class QuizSubmissionModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String quizId;

//   @HiveField(2)
//   final String studentId;

//   @HiveField(3)
//   final String studentName;

//   @HiveField(4)
//   final List<QuizAnswerModel> answers; // Student's answers

//   @HiveField(5)
//   final double score; // Percentage (0-100)

//   @HiveField(6)
//   final DateTime submittedAt;

//   @HiveField(7)
//   final int attemptNumber; // 1, 2, 3, etc.

//   @HiveField(8)
//   final DateTime startedAt; // When the quiz was started

//   @HiveField(9)
//   final int durationSeconds; // How long it took to complete

//   QuizSubmissionModel({
//     required this.id,
//     required this.quizId,
//     required this.studentId,
//     required this.studentName,
//     required this.answers,
//     required this.score,
//     required this.submittedAt,
//     required this.attemptNumber,
//     required this.startedAt,
//     required this.durationSeconds,
//   });

//   // Get formatted score
//   String get formattedScore => '${score.toStringAsFixed(1)}%';

//   // Get number of correct answers
//   int get correctAnswersCount {
//     return answers.where((answer) => answer.isCorrect).length;
//   }

//   // Get number of total questions
//   int get totalQuestions => answers.length;

//   // Get formatted duration
//   String get formattedDuration {
//     final minutes = durationSeconds ~/ 60;
//     final seconds = durationSeconds % 60;
//     return '$minutes:${seconds.toString().padLeft(2, '0')}';
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'quizId': quizId,
//       'studentId': studentId,
//       'studentName': studentName,
//       'answers': answers.map((a) => a.toJson()).toList(),
//       'score': score,
//       'submittedAt': submittedAt.toIso8601String(),
//       'attemptNumber': attemptNumber,
//       'startedAt': startedAt.toIso8601String(),
//       'durationSeconds': durationSeconds,
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory QuizSubmissionModel.fromJson(Map<String, dynamic> json) {
//     return QuizSubmissionModel(
//       id: json['id'] as String,
//       quizId: json['quizId'] as String,
//       studentId: json['studentId'] as String,
//       studentName: json['studentName'] as String,
//       answers: (json['answers'] as List<dynamic>?)
//               ?.map((e) => QuizAnswerModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       score: (json['score'] as num).toDouble(),
//       submittedAt: json['submittedAt'] is String
//           ? DateTime.parse(json['submittedAt'])
//           : (json['submittedAt'] as DateTime),
//       attemptNumber: json['attemptNumber'] as int,
//       startedAt: json['startedAt'] is String
//           ? DateTime.parse(json['startedAt'])
//           : (json['startedAt'] as DateTime),
//       durationSeconds: json['durationSeconds'] as int,
//     );
//   }

//   // Create a copy with updated fields
//   QuizSubmissionModel copyWith({
//     String? id,
//     String? quizId,
//     String? studentId,
//     String? studentName,
//     List<QuizAnswerModel>? answers,
//     double? score,
//     DateTime? submittedAt,
//     int? attemptNumber,
//     DateTime? startedAt,
//     int? durationSeconds,
//   }) {
//     return QuizSubmissionModel(
//       id: id ?? this.id,
//       quizId: quizId ?? this.quizId,
//       studentId: studentId ?? this.studentId,
//       studentName: studentName ?? this.studentName,
//       answers: answers ?? this.answers,
//       score: score ?? this.score,
//       submittedAt: submittedAt ?? this.submittedAt,
//       attemptNumber: attemptNumber ?? this.attemptNumber,
//       startedAt: startedAt ?? this.startedAt,
//       durationSeconds: durationSeconds ?? this.durationSeconds,
//     );
//   }

//   @override
//   String toString() {
//     return 'QuizSubmissionModel(id: $id, quizId: $quizId, studentId: $studentId, score: $score)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is QuizSubmissionModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }

// // Quiz Answer Model
// @HiveType(typeId: 102) // Using 102 for nested model
// class QuizAnswerModel {
//   @HiveField(0)
//   final String questionId;

//   @HiveField(1)
//   final String selectedChoiceId; // The choice student selected

//   @HiveField(2)
//   final bool isCorrect; // Whether the answer was correct

//   QuizAnswerModel({
//     required this.questionId,
//     required this.selectedChoiceId,
//     required this.isCorrect,
//   });

//   // Convert to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'questionId': questionId,
//       'selectedChoiceId': selectedChoiceId,
//       'isCorrect': isCorrect,
//     };
//   }

//   // Create from JSON
//   factory QuizAnswerModel.fromJson(Map<String, dynamic> json) {
//     return QuizAnswerModel(
//       questionId: json['questionId'] as String,
//       selectedChoiceId: json['selectedChoiceId'] as String,
//       isCorrect: json['isCorrect'] as bool,
//     );
//   }

//   QuizAnswerModel copyWith({
//     String? questionId,
//     String? selectedChoiceId,
//     bool? isCorrect,
//   }) {
//     return QuizAnswerModel(
//       questionId: questionId ?? this.questionId,
//       selectedChoiceId: selectedChoiceId ?? this.selectedChoiceId,
//       isCorrect: isCorrect ?? this.isCorrect,
//     );
//   }
// }
