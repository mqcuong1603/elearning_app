import 'package:hive/hive.dart';
import '../config/app_constants.dart';

part 'user_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdUser)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String role; // 'instructor' or 'student'

  @HiveField(5)
  final String? avatarUrl;

  @HiveField(6)
  final String? studentId; // Only for students

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final Map<String, dynamic>? additionalInfo; // For flexible extra fields

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.studentId,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
  });

  // Check if user is instructor
  bool get isInstructor => role == AppConstants.roleInstructor;

  // Check if user is student
  bool get isStudent => role == AppConstants.roleStudent;

  // Get display name (fullName or username)
  String get displayName => fullName.isNotEmpty ? fullName : username;

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'studentId': studentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'additionalInfo': additionalInfo,
    };
  }

  // Create from JSON (from Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      studentId: json['studentId'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime),
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
    String? avatarUrl,
    String? studentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
