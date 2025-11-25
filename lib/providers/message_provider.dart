// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
// import '../models/message_model.dart';
// import '../services/message_service.dart';

// /// Message Provider
// /// Manages messaging state and handles message operations
// class MessageProvider extends ChangeNotifier {
//   final MessageService _messageService;

//   MessageProvider({required MessageService messageService})
//       : _messageService = messageService;

//   // State - Messages
//   List<MessageModel> _messages = [];
//   List<MessageModel> _conversation = [];
//   List<Map<String, dynamic>> _conversationsList = [];
//   bool _isLoadingMessages = false;
//   bool _isLoadingConversations = false;
//   String? _error;
//   String? _currentUserId;
//   String? _currentPartnerId;
//   int _unreadCount = 0;

//   // Getters
//   List<MessageModel> get messages => _messages;
//   List<MessageModel> get conversation => _conversation;
//   List<Map<String, dynamic>> get conversationsList => _conversationsList;
//   bool get isLoadingMessages => _isLoadingMessages;
//   bool get isLoadingConversations => _isLoadingConversations;
//   bool get isLoading => _isLoadingMessages || _isLoadingConversations;
//   String? get error => _error;
//   String? get currentUserId => _currentUserId;
//   String? get currentPartnerId => _currentPartnerId;
//   int get unreadCount => _unreadCount;
//   int get messagesCount => _messages.length;
//   int get conversationsCount => _conversationsList.length;

//   /// Load all messages for a user
//   Future<void> loadMessagesForUser(String userId) async {
//     try {
//       _setLoadingMessages(true);
//       _error = null;
//       _currentUserId = userId;

//       _messages = await _messageService.getMessagesForUser(userId);

//       _setLoadingMessages(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoadingMessages(false);
//       notifyListeners();
//     }
//   }

//   /// Load conversations list for a user
//   Future<void> loadConversationsList(String userId) async {
//     try {
//       _setLoadingConversations(true);
//       _error = null;
//       _currentUserId = userId;

//       _conversationsList = await _messageService.getConversationsList(userId);

//       // Calculate total unread count
//       _unreadCount = _conversationsList.fold<int>(
//         0,
//         (sum, conversation) => sum + (conversation['unreadCount'] as int),
//       );

//       _setLoadingConversations(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoadingConversations(false);
//       notifyListeners();
//     }
//   }

//   /// Load conversation between two users
//   Future<void> loadConversation(String userId1, String userId2) async {
//     try {
//       _setLoadingMessages(true);
//       _error = null;
//       _currentUserId = userId1;
//       _currentPartnerId = userId2;

//       _conversation = await _messageService.getConversation(userId1, userId2);

//       _setLoadingMessages(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoadingMessages(false);
//       notifyListeners();
//     }
//   }

//   /// Send a message
//   Future<MessageModel?> sendMessage({
//     required String senderId,
//     required String senderName,
//     required String senderRole,
//     required String receiverId,
//     required String receiverName,
//     required String receiverRole,
//     required String content,
//     List<PlatformFile>? attachmentFiles,
//   }) async {
//     try {
//       _error = null;

//       final message = await _messageService.sendMessage(
//         senderId: senderId,
//         senderName: senderName,
//         senderRole: senderRole,
//         receiverId: receiverId,
//         receiverName: receiverName,
//         receiverRole: receiverRole,
//         content: content,
//         attachmentFiles: attachmentFiles,
//       );

//       // Reload conversation
//       await loadConversation(senderId, receiverId);

//       // Reload conversations list to update last message
//       await loadConversationsList(senderId);

//       return message;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Mark message as read
//   Future<void> markAsRead(String messageId) async {
//     try {
//       await _messageService.markAsRead(messageId);

//       // Update local state
//       final index = _conversation.indexWhere((msg) => msg.id == messageId);
//       if (index != -1) {
//         _conversation[index] = _conversation[index].copyWith(
//           isRead: true,
//           readAt: DateTime.now(),
//         );
//         notifyListeners();
//       }

//       // Reload unread count
//       if (_currentUserId != null) {
//         _unreadCount = await _messageService.getUnreadCount(_currentUserId!);
//         notifyListeners();
//       }
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//     }
//   }

//   /// Mark all messages in a conversation as read
//   Future<void> markConversationAsRead(String userId, String partnerId) async {
//     try {
//       await _messageService.markConversationAsRead(userId, partnerId);

//       // Reload conversation
//       await loadConversation(userId, partnerId);

//       // Reload conversations list to update unread counts
//       await loadConversationsList(userId);
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//     }
//   }

//   /// Delete message
//   Future<bool> deleteMessage(String messageId, String topicId) async {
//     try {
//       _error = null;

//       await _messageService.deleteMessage(messageId);

//       // Reload conversation
//       if (_currentUserId != null && _currentPartnerId != null) {
//         await loadConversation(_currentUserId!, _currentPartnerId!);
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Get unread message count
//   Future<void> loadUnreadCount(String userId) async {
//     try {
//       _unreadCount = await _messageService.getUnreadCount(userId);
//       notifyListeners();
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//     }
//   }

//   /// Search messages
//   Future<void> searchMessages(String userId, String query) async {
//     try {
//       _setLoadingMessages(true);
//       _error = null;

//       _messages = await _messageService.searchMessages(userId, query);

//       _setLoadingMessages(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoadingMessages(false);
//       notifyListeners();
//     }
//   }

//   /// Clear conversation
//   void clearConversation() {
//     _conversation = [];
//     _currentPartnerId = null;
//     notifyListeners();
//   }

//   /// Clear all state
//   void clearAll() {
//     _messages = [];
//     _conversation = [];
//     _conversationsList = [];
//     _currentUserId = null;
//     _currentPartnerId = null;
//     _unreadCount = 0;
//     _error = null;
//     notifyListeners();
//   }

//   // Private methods

//   void _setLoadingMessages(bool loading) {
//     _isLoadingMessages = loading;
//     notifyListeners();
//   }

//   void _setLoadingConversations(bool loading) {
//     _isLoadingConversations = loading;
//     notifyListeners();
//   }
// }
