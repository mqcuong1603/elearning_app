// import 'package:hive/hive.dart';
// import '../config/app_constants.dart';
// import 'announcement_model.dart'; // For AttachmentModel

// part 'message_model.g.dart';

// @HiveType(typeId: AppConstants.hiveTypeIdMessage)
// class MessageModel extends HiveObject {
//   @HiveField(0)
//   final String id;

//   @HiveField(1)
//   final String senderId;

//   @HiveField(2)
//   final String senderName;

//   @HiveField(3)
//   final String senderRole; // 'instructor' or 'student'

//   @HiveField(4)
//   final String receiverId;

//   @HiveField(5)
//   final String receiverName;

//   @HiveField(6)
//   final String receiverRole; // 'instructor' or 'student'

//   @HiveField(7)
//   final String content;

//   @HiveField(8)
//   final List<AttachmentModel> attachments;

//   @HiveField(9)
//   final bool isRead;

//   @HiveField(10)
//   final DateTime createdAt;

//   @HiveField(11)
//   final DateTime? readAt;

//   MessageModel({
//     required this.id,
//     required this.senderId,
//     required this.senderName,
//     required this.senderRole,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverRole,
//     required this.content,
//     required this.attachments,
//     required this.isRead,
//     required this.createdAt,
//     this.readAt,
//   });

//   // Check if sender is instructor
//   bool get isSenderInstructor => senderRole == AppConstants.roleInstructor;

//   // Check if receiver is instructor
//   bool get isReceiverInstructor => receiverRole == AppConstants.roleInstructor;

//   // Check if message is from current user
//   bool isFromUser(String userId) => senderId == userId;

//   // Check if message is to current user
//   bool isToUser(String userId) => receiverId == userId;

//   // Get conversation ID (for grouping messages between two users)
//   String getConversationId() {
//     final ids = [senderId, receiverId]..sort();
//     return ids.join('_');
//   }

//   // Convert to JSON (for Firestore)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'senderId': senderId,
//       'senderName': senderName,
//       'senderRole': senderRole,
//       'receiverId': receiverId,
//       'receiverName': receiverName,
//       'receiverRole': receiverRole,
//       'content': content,
//       'attachments': attachments.map((a) => a.toJson()).toList(),
//       'isRead': isRead,
//       'createdAt': createdAt.toIso8601String(),
//       'readAt': readAt?.toIso8601String(),
//     };
//   }

//   // Create from JSON (from Firestore)
//   factory MessageModel.fromJson(Map<String, dynamic> json) {
//     return MessageModel(
//       id: json['id'] as String,
//       senderId: json['senderId'] as String,
//       senderName: json['senderName'] as String,
//       senderRole: json['senderRole'] as String,
//       receiverId: json['receiverId'] as String,
//       receiverName: json['receiverName'] as String,
//       receiverRole: json['receiverRole'] as String,
//       content: json['content'] as String,
//       attachments: (json['attachments'] as List<dynamic>?)
//               ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
//               .toList() ??
//           [],
//       isRead: json['isRead'] as bool? ?? false,
//       createdAt: json['createdAt'] is String
//           ? DateTime.parse(json['createdAt'])
//           : (json['createdAt'] as DateTime),
//       readAt: json['readAt'] != null
//           ? (json['readAt'] is String
//               ? DateTime.parse(json['readAt'])
//               : (json['readAt'] as DateTime))
//           : null,
//     );
//   }

//   // Create a copy with updated fields
//   MessageModel copyWith({
//     String? id,
//     String? senderId,
//     String? senderName,
//     String? senderRole,
//     String? receiverId,
//     String? receiverName,
//     String? receiverRole,
//     String? content,
//     List<AttachmentModel>? attachments,
//     bool? isRead,
//     DateTime? createdAt,
//     DateTime? readAt,
//   }) {
//     return MessageModel(
//       id: id ?? this.id,
//       senderId: senderId ?? this.senderId,
//       senderName: senderName ?? this.senderName,
//       senderRole: senderRole ?? this.senderRole,
//       receiverId: receiverId ?? this.receiverId,
//       receiverName: receiverName ?? this.receiverName,
//       receiverRole: receiverRole ?? this.receiverRole,
//       content: content ?? this.content,
//       attachments: attachments ?? this.attachments,
//       isRead: isRead ?? this.isRead,
//       createdAt: createdAt ?? this.createdAt,
//       readAt: readAt ?? this.readAt,
//     );
//   }

//   @override
//   String toString() {
//     return 'MessageModel(id: $id, from: $senderName, to: $receiverName, isRead: $isRead)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is MessageModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }
