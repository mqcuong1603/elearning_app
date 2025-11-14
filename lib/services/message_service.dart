import 'package:file_picker/file_picker.dart';
import '../models/message_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'storage_service.dart';

/// Message Service
/// Handles all direct messaging operations (student-instructor only)
class MessageService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final StorageService _storageService;

  MessageService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _storageService = storageService;

  // ============================================
  // MESSAGES
  // ============================================

  /// Get all messages for a user (as sender or receiver)
  Future<List<MessageModel>> getMessagesForUser(String userId) async {
    try {
      // Get messages where user is sender
      final sentData = await _firestoreService.query(
        collection: AppConstants.collectionMessages,
        filters: [
          QueryFilter(field: 'senderId', isEqualTo: userId),
        ],
      );

      // Get messages where user is receiver
      final receivedData = await _firestoreService.query(
        collection: AppConstants.collectionMessages,
        filters: [
          QueryFilter(field: 'receiverId', isEqualTo: userId),
        ],
      );

      // Combine and convert to models
      final allData = [...sentData, ...receivedData];
      final messages =
          allData.map((json) => MessageModel.fromJson(json)).toList();

      // Sort by createdAt descending (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return messages;
    } catch (e) {
      print('Get messages for user error: $e');
      return [];
    }
  }

  /// Get conversation between two users
  Future<List<MessageModel>> getConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Get all messages for user1
      final user1Messages = await getMessagesForUser(userId1);

      // Filter messages between user1 and user2
      final conversation = user1Messages.where((message) {
        return (message.senderId == userId1 && message.receiverId == userId2) ||
            (message.senderId == userId2 && message.receiverId == userId1);
      }).toList();

      // Sort by createdAt ascending (oldest first for chat display)
      conversation.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return conversation;
    } catch (e) {
      print('Get conversation error: $e');
      return [];
    }
  }

  /// Get list of conversations (unique users) for a user
  Future<List<Map<String, dynamic>>> getConversationsList(
    String userId,
  ) async {
    try {
      final messages = await getMessagesForUser(userId);

      // Group messages by conversation partner
      final conversationsMap = <String, Map<String, dynamic>>{};

      for (final message in messages) {
        // Determine conversation partner
        final partnerId = message.senderId == userId
            ? message.receiverId
            : message.senderId;
        final partnerName = message.senderId == userId
            ? message.receiverName
            : message.senderName;
        final partnerRole = message.senderId == userId
            ? message.receiverRole
            : message.senderRole;

        // Check if conversation exists or if this message is more recent
        if (!conversationsMap.containsKey(partnerId) ||
            message.createdAt.isAfter(
              conversationsMap[partnerId]!['lastMessageTime'] as DateTime,
            )) {
          conversationsMap[partnerId] = {
            'userId': partnerId,
            'userName': partnerName,
            'userRole': partnerRole,
            'lastMessage': message.content,
            'lastMessageTime': message.createdAt,
            'isRead': message.isToUser(userId) ? message.isRead : true,
            'unreadCount': 0, // Will be calculated below
          };
        }
      }

      // Calculate unread count for each conversation
      for (final partnerId in conversationsMap.keys) {
        final unreadCount = messages.where((msg) {
          return msg.senderId == partnerId &&
              msg.receiverId == userId &&
              !msg.isRead;
        }).length;
        conversationsMap[partnerId]!['unreadCount'] = unreadCount;
      }

      // Convert to list and sort by last message time
      final conversationsList = conversationsMap.values.toList();
      conversationsList.sort((a, b) {
        final timeA = a['lastMessageTime'] as DateTime;
        final timeB = b['lastMessageTime'] as DateTime;
        return timeB.compareTo(timeA); // Newest first
      });

      return conversationsList;
    } catch (e) {
      print('Get conversations list error: $e');
      return [];
    }
  }

  /// Get message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionMessages,
        documentId: messageId,
      );

      if (data == null) return null;

      return MessageModel.fromJson(data);
    } catch (e) {
      print('Get message by ID error: $e');
      return null;
    }
  }

  /// Send a new message
  Future<MessageModel> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String content,
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      final now = DateTime.now();

      // Validate roles: only student-instructor messaging allowed
      if (!_isValidMessagingPair(senderRole, receiverRole)) {
        throw Exception(
          'Direct messaging is only allowed between students and instructors',
        );
      }

      // Create message first without attachments
      final message = MessageModel(
        id: '', // Will be set by Firestore
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverRole: receiverRole,
        content: content,
        attachments: [],
        isRead: false,
        createdAt: now,
        readAt: null,
      );

      // Create message in Firestore to get ID
      final id = await _firestoreService.create(
        collection: AppConstants.collectionMessages,
        data: message.toJson(),
      );

      // Upload attachments if any
      List<AttachmentModel> attachments = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        print('Uploading ${attachmentFiles.length} attachments for message $id');
        attachments = await _uploadMessageAttachments(
          files: attachmentFiles,
          conversationId: message.getConversationId(),
          messageId: id,
        );
        print('Successfully uploaded ${attachments.length} attachments');

        // Update message with attachments
        if (attachments.isNotEmpty) {
          await _firestoreService.update(
            collection: AppConstants.collectionMessages,
            documentId: id,
            data: {'attachments': attachments.map((a) => a.toJson()).toList()},
          );
        }
      }

      return message.copyWith(
        id: id,
        attachments: attachments,
      );
    } catch (e) {
      print('Send message error: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final message = await getMessageById(messageId);
      if (message == null || message.isRead) return;

      await _firestoreService.update(
        collection: AppConstants.collectionMessages,
        documentId: messageId,
        data: {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Mark as read error: $e');
      // Don't throw - this is not critical
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String userId, String partnerId) async {
    try {
      final conversation = await getConversation(userId, partnerId);
      final unreadMessages = conversation.where(
        (msg) => msg.receiverId == userId && !msg.isRead,
      );

      for (final message in unreadMessages) {
        await markAsRead(message.id);
      }
    } catch (e) {
      print('Mark conversation as read error: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      // Get message to delete its attachments
      final message = await getMessageById(messageId);
      if (message == null) {
        throw Exception('Message not found');
      }

      // Delete attachments from storage
      for (final attachment in message.attachments) {
        try {
          await _storageService.deleteFile(attachment.url);
        } catch (e) {
          print('Failed to delete attachment ${attachment.filename}: $e');
        }
      }

      // Delete the message
      await _firestoreService.delete(
        collection: AppConstants.collectionMessages,
        documentId: messageId,
      );
    } catch (e) {
      print('Delete message error: $e');
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final messages = await getMessagesForUser(userId);
      return messages.where(
        (msg) => msg.receiverId == userId && !msg.isRead,
      ).length;
    } catch (e) {
      print('Get unread count error: $e');
      return 0;
    }
  }

  /// Stream conversation (real-time updates)
  Stream<List<MessageModel>> streamConversation(
    String userId1,
    String userId2,
  ) async* {
    // Stream messages where user1 is sender and user2 is receiver
    final stream1 = _firestoreService.streamQuery(
      collection: AppConstants.collectionMessages,
      filters: [
        QueryFilter(field: 'senderId', isEqualTo: userId1),
        QueryFilter(field: 'receiverId', isEqualTo: userId2),
      ],
    );

    // Stream messages where user2 is sender and user1 is receiver
    final stream2 = _firestoreService.streamQuery(
      collection: AppConstants.collectionMessages,
      filters: [
        QueryFilter(field: 'senderId', isEqualTo: userId2),
        QueryFilter(field: 'receiverId', isEqualTo: userId1),
      ],
    );

    // Combine streams (simplified - in production, use StreamGroup or similar)
    await for (final data1 in stream1) {
      // This is a simplified version - for production, properly combine streams
      final messages =
          data1.map((json) => MessageModel.fromJson(json)).toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      yield messages;
    }
  }

  /// Search messages by content
  Future<List<MessageModel>> searchMessages(
    String userId,
    String query,
  ) async {
    try {
      final messages = await getMessagesForUser(userId);
      final searchQuery = query.toLowerCase();

      return messages.where((message) {
        return message.content.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Search messages error: $e');
      return [];
    }
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  /// Validate that messaging is between student and instructor
  bool _isValidMessagingPair(String role1, String role2) {
    final isOneInstructor = role1 == AppConstants.roleInstructor ||
        role2 == AppConstants.roleInstructor;
    final isOneStudent =
        role1 == AppConstants.roleStudent || role2 == AppConstants.roleStudent;

    return isOneInstructor && isOneStudent;
  }

  /// Upload message attachments to storage
  Future<List<AttachmentModel>> _uploadMessageAttachments({
    required List<PlatformFile> files,
    required String conversationId,
    required String messageId,
  }) async {
    final attachments = <AttachmentModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage
        final storagePath = 'messages/$conversationId/$messageId';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: storagePath,
        );

        // Create attachment model
        final attachment = AttachmentModel(
          id: '${messageId}_attachment_$i',
          url: downloadUrl,
          filename: filename,
          size: file.size,
          type: extension,
        );

        attachments.add(attachment);
        print('Successfully added attachment: $filename');
      } catch (e) {
        print('ERROR: Failed to upload attachment $filename: $e');
      }
    }

    return attachments;
  }
}
