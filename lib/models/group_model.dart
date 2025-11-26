// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';

// part 'group_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdGroup)
// class GroupModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String name; // e.g., "Group 1", "Group A"

//   @HiveField(2)
//   final String courseId; // Reference to course

//   @HiveField(3)
//   final List<String> studentIds; // List of student IDs in this group

//   @HiveField(4)
//   final DateTime createdAt;

//   @HiveField(5)
//   final DateTime updatedAt;

//   GroupModel({
//     required this.id,
//     required this.name,
//     required this.courseId,
//     required this.studentIds,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // Get student count
//   int get studentCount => studentIds.length;

//   // Check if group has students
//   bool get hasStudents => studentIds.isNotEmpty;

//   // Check if student is in this group
//   bool hasStudent(String studentId) => studentIds.contains(studentId);

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'courseId': courseId,
//       'studentIds': studentIds,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory GroupModel.fromJson(Map<String, dynamic> json) {
//     return GroupModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       courseId: json['courseId'] as String,
//       studentIds: (json['studentIds'] as List<dynamic>?)
//               ?.map((e) => e as String)
//               .toList() ??
//           [],
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       updatedAt: json['updatedAt'] is String
//           ? DateTime.parse(json['updatedAt'])
//           : (json['updatedAt'] as DateTime),
//     );
//   }

//   // Create a copy with updated fields
//   GroupModel copyWith({
//     String? id,
//     String? name,
//     String? courseId,
//     List<String>? studentIds,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return GroupModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       courseId: courseId ?? this.courseId,
//       studentIds: studentIds ?? this.studentIds,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   @override
//   String toString() {
//     return 'GroupModel(id: $id, name: $name, courseId: $courseId, studentCount: $studentCount)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is GroupModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
