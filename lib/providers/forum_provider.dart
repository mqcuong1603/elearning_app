// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
// import '../models/forum_topic_model.dart';
// import '../models/forum_reply_model.dart';
// import '../services/forum_service.dart';

// /// Forum Provider
// /// Manages forum state and handles forum operations
// class ForumProvider extends ChangeNotifier {
//   final ForumService _forumService;

//   ForumProvider({required ForumService forumService})
//       : _forumService = forumService;

//   // State - Topics
//   List<ForumTopicModel> _topics = [];
//   List<ForumTopicModel> _filteredTopics = [];
//   ForumTopicModel? _selectedTopic;
//   bool _isLoadingTopics = false;
//   String? _topicsError;
//   String _searchQuery = '';
//   String? _selectedCourseId;

//   // State - Replies
//   List<ForumReplyModel> _replies = [];
//   bool _isLoadingReplies = false;
//   String? _repliesError;

//   // Getters - Topics
//   List<ForumTopicModel> get topics => _filteredTopics;
//   ForumTopicModel? get selectedTopic => _selectedTopic;
//   bool get isLoadingTopics => _isLoadingTopics;
//   String? get topicsError => _topicsError;
//   String get searchQuery => _searchQuery;
//   String? get selectedCourseId => _selectedCourseId;
//   int get topicsCount => _topics.length;

//   // Getters - Replies
//   List<ForumReplyModel> get replies => _replies;
//   bool get isLoadingReplies => _isLoadingReplies;
//   String? get repliesError => _repliesError;
//   int get repliesCount => _replies.length;

//   // Combined loading state
//   bool get isLoading => _isLoadingTopics || _isLoadingReplies;
//   String? get error => _topicsError ?? _repliesError;

//   /// Load topics by course
//   Future<void> loadTopicsByCourse(String courseId) async {
//     try {
//       _setLoadingTopics(true);
//       _topicsError = null;
//       _selectedCourseId = courseId;

//       _topics = await _forumService.getTopicsByCourse(courseId);
//       _applyFilters();

//       _setLoadingTopics(false);
//     } catch (e) {
//       _topicsError = e.toString();
//       _setLoadingTopics(false);
//       notifyListeners();
//     }
//   }

//   /// Load topic by ID
//   Future<void> loadTopicById(String topicId) async {
//     try {
//       _selectedTopic = await _forumService.getTopicById(topicId);
//       notifyListeners();
//     } catch (e) {
//       _topicsError = e.toString();
//       notifyListeners();
//     }
//   }

//   /// Create new topic
//   Future<ForumTopicModel?> createTopic({
//     required String courseId,
//     required String title,
//     required String content,
//     required String authorId,
//     required String authorName,
//     required String authorRole,
//     List<PlatformFile>? attachmentFiles,
//   }) async {
//     try {
//       _topicsError = null;

//       final topic = await _forumService.createTopic(
//         courseId: courseId,
//         title: title,
//         content: content,
//         authorId: authorId,
//         authorName: authorName,
//         authorRole: authorRole,
//         attachmentFiles: attachmentFiles,
//       );

//       // Reload topics
//       await loadTopicsByCourse(courseId);

//       return topic;
//     } catch (e) {
//       _topicsError = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update topic
//   Future<bool> updateTopic(ForumTopicModel topic) async {
//     try {
//       _topicsError = null;

//       await _forumService.updateTopic(topic);

//       // Reload topics
//       if (_selectedCourseId != null) {
//         await loadTopicsByCourse(_selectedCourseId!);
//       }

//       return true;
//     } catch (e) {
//       _topicsError = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Pin/Unpin topic
//   Future<bool> togglePinTopic(String topicId, bool isPinned) async {
//     try {
//       _topicsError = null;

//       await _forumService.togglePinTopic(topicId, isPinned);

//       // Reload topics
//       if (_selectedCourseId != null) {
//         await loadTopicsByCourse(_selectedCourseId!);
//       }

//       return true;
//     } catch (e) {
//       _topicsError = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete topic
//   Future<bool> deleteTopic(String topicId) async {
//     try {
//       _topicsError = null;

//       await _forumService.deleteTopic(topicId);

//       // Reload topics
//       if (_selectedCourseId != null) {
//         await loadTopicsByCourse(_selectedCourseId!);
//       }

//       // Clear selected topic if it was deleted
//       if (_selectedTopic?.id == topicId) {
//         _selectedTopic = null;
//         _replies = [];
//       }

//       return true;
//     } catch (e) {
//       _topicsError = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Load replies for a topic
//   Future<void> loadRepliesByTopic(String topicId) async {
//     try {
//       _setLoadingReplies(true);
//       _repliesError = null;

//       _replies = await _forumService.getRepliesByTopic(topicId);

//       _setLoadingReplies(false);
//     } catch (e) {
//       _repliesError = e.toString();
//       _setLoadingReplies(false);
//       notifyListeners();
//     }
//   }

//   /// Create new reply
//   Future<ForumReplyModel?> createReply({
//     required String topicId,
//     required String content,
//     required String authorId,
//     required String authorName,
//     required String authorRole,
//     String? parentReplyId,
//     List<PlatformFile>? attachmentFiles,
//   }) async {
//     try {
//       _repliesError = null;

//       final reply = await _forumService.createReply(
//         topicId: topicId,
//         content: content,
//         authorId: authorId,
//         authorName: authorName,
//         authorRole: authorRole,
//         parentReplyId: parentReplyId,
//         attachmentFiles: attachmentFiles,
//       );

//       // Reload replies
//       await loadRepliesByTopic(topicId);

//       // Reload topic to update reply count
//       await loadTopicById(topicId);

//       // Also reload topics list to update reply count in list
//       if (_selectedCourseId != null) {
//         await loadTopicsByCourse(_selectedCourseId!);
//       }

//       return reply;
//     } catch (e) {
//       _repliesError = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update reply
//   Future<bool> updateReply(ForumReplyModel reply) async {
//     try {
//       _repliesError = null;

//       await _forumService.updateReply(reply);

//       // Reload replies
//       await loadRepliesByTopic(reply.topicId);

//       return true;
//     } catch (e) {
//       _repliesError = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete reply
//   Future<bool> deleteReply(ForumReplyModel reply) async {
//     try {
//       _repliesError = null;

//       await _forumService.deleteReply(reply.id);

//       // Reload replies
//       await loadRepliesByTopic(reply.topicId);

//       // Reload topic to update reply count
//       await loadTopicById(reply.topicId);

//       // Also reload topics list to update reply count in list
//       if (_selectedCourseId != null) {
//         await loadTopicsByCourse(_selectedCourseId!);
//       }

//       return true;
//     } catch (e) {
//       _repliesError = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Search topics
//   void searchTopics(String query) {
//     _searchQuery = query;
//     _applyFilters();
//   }

//   /// Clear search
//   void clearSearch() {
//     _searchQuery = '';
//     _applyFilters();
//   }

//   /// Get threaded replies (organize replies by parent)
//   Map<String?, List<ForumReplyModel>> getThreadedReplies() {
//     final Map<String?, List<ForumReplyModel>> threaded = {};

//     for (final reply in _replies) {
//       final parentId = reply.parentReplyId;
//       if (!threaded.containsKey(parentId)) {
//         threaded[parentId] = [];
//       }
//       threaded[parentId]!.add(reply);
//     }

//     return threaded;
//   }

//   /// Get top-level replies (replies without parent)
//   List<ForumReplyModel> getTopLevelReplies() {
//     return _replies.where((reply) => reply.parentReplyId == null).toList();
//   }

//   /// Get nested replies for a parent reply
//   List<ForumReplyModel> getNestedReplies(String parentReplyId) {
//     return _replies.where((reply) => reply.parentReplyId == parentReplyId).toList();
//   }

//   /// Clear selected topic and replies
//   void clearSelectedTopic() {
//     _selectedTopic = null;
//     _replies = [];
//     notifyListeners();
//   }

//   /// Clear all state
//   void clearAll() {
//     _topics = [];
//     _filteredTopics = [];
//     _selectedTopic = null;
//     _replies = [];
//     _searchQuery = '';
//     _selectedCourseId = null;
//     _topicsError = null;
//     _repliesError = null;
//     notifyListeners();
//   }

//   // Private methods

//   void _setLoadingTopics(bool loading) {
//     _isLoadingTopics = loading;
//     notifyListeners();
//   }

//   void _setLoadingReplies(bool loading) {
//     _isLoadingReplies = loading;
//     notifyListeners();
//   }

//   void _applyFilters() {
//     _filteredTopics = _topics;

//     // Apply search filter
//     if (_searchQuery.isNotEmpty) {
//       final query = _searchQuery.toLowerCase();
//       _filteredTopics = _filteredTopics.where((topic) {
//         return topic.title.toLowerCase().contains(query) ||
//             topic.content.toLowerCase().contains(query);
//       }).toList();
//     }

//     notifyListeners();
//   }
// }
