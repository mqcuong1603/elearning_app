import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  student,
}

class UserEntity extends Equatable {
  final String id;
  final String username; // For admin: "admin", For students: real names
  final String displayName; // Real name (cannot be modified in profile)
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Additional profile fields
  final String? phoneNumber;
  final String? studentId; // Only for students
  final String? bio;

  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    this.studentId,
    this.bio,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  UserEntity copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? phoneNumber,
    String? studentId,
    String? bio,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      studentId: studentId ?? this.studentId,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        email,
        avatarUrl,
        role,
        createdAt,
        lastLoginAt,
        phoneNumber,
        studentId,
        bio,
      ];
}
