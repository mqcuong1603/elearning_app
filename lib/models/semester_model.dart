import 'package:hive/hive.dart';
import '../config/app_constants.dart';

part 'semester_model.g.dart';

@HiveType(typeId: AppConstants.hiveTypeIdSemester)
class SemesterModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code; // e.g., "2024-1", "2024-2"

  @HiveField(2)
  final String name; // e.g., "Fall 2024", "Spring 2025"

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final bool isCurrent; // Is this the current semester?

  SemesterModel({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.isCurrent,
  });

  // Get display text
  String get displayText => '$name ($code)';

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }

  // Create from JSON (from Firestore)
  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  // Create a copy with updated fields
  SemesterModel copyWith({
    String? id,
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCurrent,
  }) {
    return SemesterModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  String toString() {
    return 'SemesterModel(id: $id, code: $code, name: $name, isCurrent: $isCurrent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SemesterModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
