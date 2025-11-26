// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';

// part 'notification_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdNotification)
// class NotificationModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String userId; // Who receives this notification

//   @HiveField(2)
//   final String type; // 'announcement', 'assignment', 'quiz', 'material', 'message', 'forum', 'grade', 'deadline'

//   @HiveField(3)
//   final String title;

//   @HiveField(4)
//   final String message;

//   @HiveField(5)
//   final String?
//       relatedId; // ID of related entity (courseId, assignmentId, quizId, etc.)

//   @HiveField(6)
//   final String? relatedType; // Type of related entity ('course', 'assignment', etc.)

//   @HiveField(7)
//   final bool isRead;

//   @HiveField(8)
//   final DateTime createdAt;

//   @HiveField(9)
//   final DateTime? readAt;

//   @HiveField(10)
//   final Map<String, dynamic>? data; // Additional data for the notification

//   NotificationModel({
//     required this.id,
//     required this.userId,
//     required this.type,
//     required this.title,
//     required this.message,
//     this.relatedId,
//     this.relatedType,
//     required this.isRead,
//     required this.createdAt,
//     this.readAt,
//     this.data,
//   });

//   // Get icon based on notification type
//   String get icon {
//     switch (type) {
//       case AppConstants.notificationTypeAnnouncement:
//         return '📢';
//       case AppConstants.notificationTypeAssignment:
//         return '📝';
//       case AppConstants.notificationTypeQuiz:
//         return '📊';
//       case AppConstants.notificationTypeMaterial:
//         return '📚';
//       case AppConstants.notificationTypeMessage:
//         return '💬';
//       case AppConstants.notificationTypeForum:
//         return '💭';
//       case AppConstants.notificationTypeGrade:
//         return '⭐';
//       case AppConstants.notificationTypeDeadline:
//         return '⏰';
//       default:
//         return '🔔';
//     }
//   }

//   // Check if notification is recent (within 24 hours)
//   bool get isRecent {
//     final now = DateTime.now();
//     final difference = now.difference(createdAt);
//     return difference.inHours < 24;
//   }

//   // Get relative time string (e.g., "2 hours ago", "1 day ago")
//   String get relativeTime {
//     final now = DateTime.now();
//     final difference = now.difference(createdAt);

//     if (difference.inMinutes < 1) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
//     } else if (difference.inDays < 30) {
//       final weeks = (difference.inDays / 7).floor();
//       return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
//     } else {
//       final months = (difference.inDays / 30).floor();
//       return '$months ${months == 1 ? 'month' : 'months'} ago';
//     }
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'userId': userId,
//       'type': type,
//       'title': title,
//       'message': message,
//       'relatedId': relatedId,
//       'relatedType': relatedType,
//       'isRead': isRead,
//       'createdAt': createdAt.toIso8601String(),
//       'readAt': readAt?.toIso8601String(),
//       'data': data,
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory NotificationModel.fromJson(Map<String, dynamic> json) {
//     return NotificationModel(
//       id: json['id'] as String,
//       userId: json['userId'] as String,
//       type: json['type'] as String,
//       title: json['title'] as String,
//       message: json['message'] as String,
//       relatedId: json['relatedId'] as String?,
//       relatedType: json['relatedType'] as String?,
//       isRead: json['isRead'] as bool? ?? false,
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       readAt: json['readAt'] != null
//           ? (json['readAt'] is String
//               ? DateTime.parse(json['readAt'])
//               : (json['readAt'] as DateTime))
//           : null,
//       data: json['data'] as Map<String, dynamic>?,
//     );
//   }

//   // Create a copy with updated fields
//   NotificationModel copyWith({
//     String? id,
//     String? userId,
//     String? type,
//     String? title,
//     String? message,
//     String? relatedId,
//     String? relatedType,
//     bool? isRead,
//     DateTime? createdAt,
//     DateTime? readAt,
//     Map<String, dynamic>? data,
//   }) {
//     return NotificationModel(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       type: type ?? this.type,
//       title: title ?? this.title,
//       message: message ?? this.message,
//       relatedId: relatedId ?? this.relatedId,
//       relatedType: relatedType ?? this.relatedType,
//       isRead: isRead ?? this.isRead,
//       createdAt: createdAt ?? this.createdAt,
//       readAt: readAt ?? this.readAt,
//       data: data ?? this.data,
//     );
//   }

//   @override
//   String toString() {
//     return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is NotificationModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
