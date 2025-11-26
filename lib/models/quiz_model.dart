// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';

// part 'quiz_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdQuiz)
// class QuizModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String courseId;

//   @HiveField(2)
//   final String title;

//   @HiveField(3)
//   final String description;

//   @HiveField(4)
//   final DateTime openDate;

//   @HiveField(5)
//   final DateTime closeDate;

//   @HiveField(6)
//   final int durationMinutes; // Quiz duration in minutes

//   @HiveField(7)
//   final int maxAttempts;

//   @HiveField(8)
//   final Map<String, int>
//       questionStructure; // e.g., {'easy': 5, 'medium': 3, 'hard': 2}

//   @HiveField(9)
//   final List<String> groupIds; // Scope: which groups can take this

//   @HiveField(10)
//   final String instructorId;

//   @HiveField(11)
//   final String instructorName;

//   @HiveField(12)
//   final DateTime createdAt;

//   @HiveField(13)
//   final DateTime updatedAt;

//   QuizModel({
//     required this.id,
//     required this.courseId,
//     required this.title,
//     required this.description,
//     required this.openDate,
//     required this.closeDate,
//     required this.durationMinutes,
//     required this.maxAttempts,
//     required this.questionStructure,
//     required this.groupIds,
//     required this.instructorId,
//     required this.instructorName,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // Check if quiz is currently available
//   bool get isAvailable {
//     final now = DateTime.now();
//     return now.isAfter(openDate) && now.isBefore(closeDate);
//   }

//   // Check if quiz is closed
//   bool get isClosed {
//     return DateTime.now().isAfter(closeDate);
//   }

//   // Check if quiz hasn't opened yet
//   bool get isUpcoming {
//     return DateTime.now().isBefore(openDate);
//   }

//   // Check if quiz is for all groups
//   bool get isForAllGroups => groupIds.isEmpty;

//   // Get total number of questions
//   int get totalQuestions {
//     return questionStructure.values.fold(0, (sum, count) => sum + count);
//   }

//   // Get question count by difficulty
//   int getQuestionCountByDifficulty(String difficulty) {
//     return questionStructure[difficulty] ?? 0;
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'title': title,
//       'description': description,
//       'openDate': openDate.toIso8601String(),
//       'closeDate': closeDate.toIso8601String(),
//       'durationMinutes': durationMinutes,
//       'maxAttempts': maxAttempts,
//       'questionStructure': questionStructure,
//       'groupIds': groupIds,
//       'instructorId': instructorId,
//       'instructorName': instructorName,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory QuizModel.fromJson(Map<String, dynamic> json) {
//     return QuizModel(
//       id: json['id'] as String,
//       courseId: json['courseId'] as String,
//       title: json['title'] as String,
//       description: json['description'] as String,
//       openDate: json['openDate'] is String
//           ? DateTime.parse(json['openDate'])
//           : (json['openDate'] as DateTime),
//       closeDate: json['closeDate'] is String
//           ? DateTime.parse(json['closeDate'])
//           : (json['closeDate'] as DateTime),
//       durationMinutes: json['durationMinutes'] as int? ?? AppConstants.defaultQuizDurationMinutes,
//       maxAttempts: json['maxAttempts'] as int? ?? AppConstants.defaultMaxQuizAttempts,
//       questionStructure: (json['questionStructure'] as Map<String, dynamic>?)
//               ?.map((key, value) => MapEntry(key, value as int)) ??
//           {},
//       groupIds: (json['groupIds'] as List<dynamic>?)
//               ?.map((e) => e as String)
//               .toList() ??
//           [],
//       instructorId: json['instructorId'] as String,
//       instructorName: json['instructorName'] as String,
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       updatedAt: json['updatedAt'] is String
//           ? DateTime.parse(json['updatedAt'])
//           : (json['updatedAt'] as DateTime),
//     );
//   }

//   // Create a copy with updated fields
//   QuizModel copyWith({
//     String? id,
//     String? courseId,
//     String? title,
//     String? description,
//     DateTime? openDate,
//     DateTime? closeDate,
//     int? durationMinutes,
//     int? maxAttempts,
//     Map<String, int>? questionStructure,
//     List<String>? groupIds,
//     String? instructorId,
//     String? instructorName,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return QuizModel(
//       id: id ?? this.id,
//       courseId: courseId ?? this.courseId,
//       title: title ?? this.title,
//       description: description ?? this.description,
//       openDate: openDate ?? this.openDate,
//       closeDate: closeDate ?? this.closeDate,
//       durationMinutes: durationMinutes ?? this.durationMinutes,
//       maxAttempts: maxAttempts ?? this.maxAttempts,
//       questionStructure: questionStructure ?? this.questionStructure,
//       groupIds: groupIds ?? this.groupIds,
//       instructorId: instructorId ?? this.instructorId,
//       instructorName: instructorName ?? this.instructorName,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   @override
//   String toString() {
//     return 'QuizModel(id: $id, title: $title, courseId: $courseId)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is QuizModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
