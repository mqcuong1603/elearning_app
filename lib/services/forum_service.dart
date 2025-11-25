import 'package:file_picker/file_picker.dart';
import '../models/forum_topic_model.dart';
import '../models/forum_reply_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'storage_service.dart';

/// Forum Service
/// Handles all forum-related operations including topics, replies, and file uploads
class ForumService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final StorageService _storageService;

  ForumService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _storageService = storageService;

  // ============================================
  // FORUM TOPICS
  // ============================================

  /// Get all forum topics for a course
  Future<List<ForumTopicModel>> getTopicsByCourse(String courseId) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionForumTopics,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
        orderBy: 'createdAt',
        descending: true,
      );

      return data.map((json) => ForumTopicModel.fromJson(json)).toList();
    } catch (e) {
      print('Get topics by course error: $e');

      // Fallback: Try without orderBy if index is missing
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          print('Attempting query without orderBy and sorting in memory...');
          final data = await _firestoreService.query(
            collection: AppConstants.collectionForumTopics,
            filters: [
              QueryFilter(field: 'courseId', isEqualTo: courseId),
            ],
          );

          final topics =
              data.map((json) => ForumTopicModel.fromJson(json)).toList();

          // Sort in memory: pinned first, then by createdAt descending
          topics.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1; // Pinned topics first
            }
            return b.createdAt.compareTo(a.createdAt);
          });

          return topics;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get topic by ID
  Future<ForumTopicModel?> getTopicById(String topicId) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionForumTopics,
        documentId: topicId,
      );

      if (data == null) return null;

      return ForumTopicModel.fromJson(data);
    } catch (e) {
      print('Get topic by ID error: $e');
      return null;
    }
  }

  /// Create new forum topic
  Future<ForumTopicModel> createTopic({
    required String courseId,
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required String authorRole,
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      final now = DateTime.now();

      // Create topic first without attachments
      final topic = ForumTopicModel(
        id: '', // Will be set by Firestore
        courseId: courseId,
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        authorRole: authorRole,
        attachments: [],
        createdAt: now,
        updatedAt: now,
        replyCount: 0,
        isPinned: false,
      );

      // Create topic in Firestore to get ID
      final id = await _firestoreService.create(
        collection: AppConstants.collectionForumTopics,
        data: topic.toJson(),
      );

      // Upload attachments if any
      List<AttachmentModel> attachments = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        print('Uploading ${attachmentFiles.length} attachments for topic $id');
        attachments = await _uploadTopicAttachments(
          files: attachmentFiles,
          courseId: courseId,
          topicId: id,
        );
        print('Successfully uploaded ${attachments.length} attachments');

        // Update topic with attachments
        if (attachments.isNotEmpty) {
          await _firestoreService.update(
            collection: AppConstants.collectionForumTopics,
            documentId: id,
            data: {'attachments': attachments.map((a) => a.toJson()).toList()},
          );
        }
      }

      return topic.copyWith(
        id: id,
        attachments: attachments,
      );
    } catch (e) {
      print('Create topic error: $e');
      throw Exception('Failed to create topic: ${e.toString()}');
    }
  }

  /// Update forum topic
  Future<void> updateTopic(ForumTopicModel topic) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionForumTopics,
        documentId: topic.id,
        data: topic.copyWith(updatedAt: DateTime.now()).toJson(),
      );
    } catch (e) {
      print('Update topic error: $e');
      throw Exception('Failed to update topic: ${e.toString()}');
    }
  }

  /// Pin/Unpin topic (instructor only)
  Future<void> togglePinTopic(String topicId, bool isPinned) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionForumTopics,
        documentId: topicId,
        data: {
          'isPinned': isPinned,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Toggle pin topic error: $e');
      throw Exception('Failed to pin/unpin topic: ${e.toString()}');
    }
  }

  /// Delete forum topic
  Future<void> deleteTopic(String topicId) async {
    try {
      // Get topic to delete its attachments
      final topic = await getTopicById(topicId);
      if (topic == null) {
        throw Exception('Topic not found');
      }

      // Delete attachments from storage
      for (final attachment in topic.attachments) {
        try {
          await _storageService.deleteFile(attachment.url);
        } catch (e) {
          print('Failed to delete attachment ${attachment.filename}: $e');
        }
      }

      // Delete all replies for this topic
      final replies = await getRepliesByTopic(topicId);
      for (final reply in replies) {
        await deleteReply(reply.id);
      }

      // Delete the topic
      await _firestoreService.delete(
        collection: AppConstants.collectionForumTopics,
        documentId: topicId,
      );
    } catch (e) {
      print('Delete topic error: $e');
      throw Exception('Failed to delete topic: ${e.toString()}');
    }
  }

  /// Search topics by title or content
  Future<List<ForumTopicModel>> searchTopics(
    String courseId,
    String query,
  ) async {
    try {
      // Get all topics for the course
      final allTopics = await getTopicsByCourse(courseId);

      // Filter by search query (case-insensitive)
      final searchQuery = query.toLowerCase();
      return allTopics.where((topic) {
        return topic.title.toLowerCase().contains(searchQuery) ||
            topic.content.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Search topics error: $e');
      return [];
    }
  }

  /// Increment reply count for a topic
  Future<void> incrementReplyCount(String topicId) async {
    try {
      final topic = await getTopicById(topicId);
      if (topic == null) return;

      await _firestoreService.update(
        collection: AppConstants.collectionForumTopics,
        documentId: topicId,
        data: {
          'replyCount': topic.replyCount + 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Increment reply count error: $e');
    }
  }

  /// Decrement reply count for a topic
  Future<void> decrementReplyCount(String topicId) async {
    try {
      final topic = await getTopicById(topicId);
      if (topic == null) return;

      final newCount = topic.replyCount > 0 ? topic.replyCount - 1 : 0;

      await _firestoreService.update(
        collection: AppConstants.collectionForumTopics,
        documentId: topicId,
        data: {
          'replyCount': newCount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Decrement reply count error: $e');
    }
  }

  /// Stream topics by course (real-time updates)
  Stream<List<ForumTopicModel>> streamTopicsByCourse(String courseId) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionForumTopics,
      filters: [
        QueryFilter(field: 'courseId', isEqualTo: courseId),
      ],
      orderBy: 'createdAt',
      descending: true,
    )
        .map((data) {
      final topics =
          data.map((json) => ForumTopicModel.fromJson(json)).toList();

      // Sort: pinned first, then by createdAt
      topics.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return topics;
    });
  }

  // ============================================
  // FORUM REPLIES
  // ============================================

  /// Get all replies for a topic
  Future<List<ForumReplyModel>> getRepliesByTopic(String topicId) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionForumReplies,
        filters: [
          QueryFilter(field: 'topicId', isEqualTo: topicId),
        ],
        orderBy: 'createdAt',
        descending: false, // Oldest first for thread display
      );

      return data.map((json) => ForumReplyModel.fromJson(json)).toList();
    } catch (e) {
      print('Get replies by topic error: $e');

      // Fallback without orderBy
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          final data = await _firestoreService.query(
            collection: AppConstants.collectionForumReplies,
            filters: [
              QueryFilter(field: 'topicId', isEqualTo: topicId),
            ],
          );

          final replies =
              data.map((json) => ForumReplyModel.fromJson(json)).toList();
          replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return replies;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get reply by ID
  Future<ForumReplyModel?> getReplyById(String replyId) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionForumReplies,
        documentId: replyId,
      );

      if (data == null) return null;

      return ForumReplyModel.fromJson(data);
    } catch (e) {
      print('Get reply by ID error: $e');
      return null;
    }
  }

  /// Create new reply
  Future<ForumReplyModel> createReply({
    required String topicId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorRole,
    String? parentReplyId, // For threaded replies
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      final now = DateTime.now();

      // Create reply first without attachments
      final reply = ForumReplyModel(
        id: '', // Will be set by Firestore
        topicId: topicId,
        content: content,
        authorId: authorId,
        authorName: authorName,
        authorRole: authorRole,
        attachments: [],
        parentReplyId: parentReplyId,
        createdAt: now,
        updatedAt: now,
      );

      // Create reply in Firestore to get ID
      final id = await _firestoreService.create(
        collection: AppConstants.collectionForumReplies,
        data: reply.toJson(),
      );

      // Upload attachments if any
      List<AttachmentModel> attachments = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        print('Uploading ${attachmentFiles.length} attachments for reply $id');
        // Extract courseId from topic
        final topic = await getTopicById(topicId);
        if (topic != null) {
          attachments = await _uploadReplyAttachments(
            files: attachmentFiles,
            courseId: topic.courseId,
            topicId: topicId,
            replyId: id,
          );
          print('Successfully uploaded ${attachments.length} attachments');

          // Update reply with attachments
          if (attachments.isNotEmpty) {
            await _firestoreService.update(
              collection: AppConstants.collectionForumReplies,
              documentId: id,
              data: {'attachments': attachments.map((a) => a.toJson()).toList()},
            );
          }
        }
      }

      // Increment topic reply count
      await incrementReplyCount(topicId);

      return reply.copyWith(
        id: id,
        attachments: attachments,
      );
    } catch (e) {
      print('Create reply error: $e');
      throw Exception('Failed to create reply: ${e.toString()}');
    }
  }

  /// Update reply
  Future<void> updateReply(ForumReplyModel reply) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionForumReplies,
        documentId: reply.id,
        data: reply.copyWith(updatedAt: DateTime.now()).toJson(),
      );
    } catch (e) {
      print('Update reply error: $e');
      throw Exception('Failed to update reply: ${e.toString()}');
    }
  }

  /// Delete reply
  Future<void> deleteReply(String replyId) async {
    try {
      // Get reply to delete its attachments
      final reply = await getReplyById(replyId);
      if (reply == null) {
        throw Exception('Reply not found');
      }

      // Delete attachments from storage
      for (final attachment in reply.attachments) {
        try {
          await _storageService.deleteFile(attachment.url);
        } catch (e) {
          print('Failed to delete attachment ${attachment.filename}: $e');
        }
      }

      // Delete nested replies (replies to this reply)
      final allReplies = await getRepliesByTopic(reply.topicId);
      final nestedReplies = allReplies.where(
        (r) => r.parentReplyId == replyId,
      ).toList();

      for (final nested in nestedReplies) {
        await deleteReply(nested.id);
      }

      // Delete the reply
      await _firestoreService.delete(
        collection: AppConstants.collectionForumReplies,
        documentId: replyId,
      );

      // Decrement topic reply count
      await decrementReplyCount(reply.topicId);
    } catch (e) {
      print('Delete reply error: $e');
      throw Exception('Failed to delete reply: ${e.toString()}');
    }
  }

  /// Stream replies by topic (real-time updates)
  Stream<List<ForumReplyModel>> streamRepliesByTopic(String topicId) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionForumReplies,
      filters: [
        QueryFilter(field: 'topicId', isEqualTo: topicId),
      ],
      orderBy: 'createdAt',
      descending: false,
    )
        .map((data) {
      return data.map((json) => ForumReplyModel.fromJson(json)).toList();
    });
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  /// Upload topic attachments to storage
  Future<List<AttachmentModel>> _uploadTopicAttachments({
    required List<PlatformFile> files,
    required String courseId,
    required String topicId,
  }) async {
    final attachments = <AttachmentModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage
        final storagePath = 'forums/$courseId/$topicId';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: storagePath,
        );

        // Create attachment model
        final attachment = AttachmentModel(
          id: '${topicId}_attachment_$i',
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

  /// Upload reply attachments to storage
  Future<List<AttachmentModel>> _uploadReplyAttachments({
    required List<PlatformFile> files,
    required String courseId,
    required String topicId,
    required String replyId,
  }) async {
    final attachments = <AttachmentModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage
        final storagePath = 'forums/$courseId/$topicId/$replyId';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: storagePath,
        );

        // Create attachment model
        final attachment = AttachmentModel(
          id: '${replyId}_attachment_$i',
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
