import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';

/// Service for managing notifications (Firestore + Hive caching)
/// Handles CRUD operations for in-app notifications for students
class NotificationService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;

  NotificationService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService;

  // ==================== CREATE ====================

  /// Create a single notification for a specific user
  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _firestoreService.generateId(),
        userId: userId,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
        relatedType: relatedType,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      // Save to Firestore
      await _firestoreService.setDocument(
        collectionPath: AppConstants.collectionNotifications,
        documentId: notification.id,
        data: notification.toJson(),
      );

      // Cache to Hive for offline access
      await _hiveService.saveNotification(notification);

      return notification.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Create notifications for multiple users (batch operation)
  /// Useful for announcements, assignments, quizzes sent to groups
  Future<List<String>> createNotificationsForUsers({
    required List<String> userIds,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final List<String> notificationIds = [];
      final batch = FirebaseFirestore.instance.batch();
      final notifications = <NotificationModel>[];

      for (final userId in userIds) {
        final notification = NotificationModel(
          id: _firestoreService.generateId(),
          userId: userId,
          type: type,
          title: title,
          message: message,
          relatedId: relatedId,
          relatedType: relatedType,
          isRead: false,
          createdAt: DateTime.now(),
          data: data,
        );

        // Add to batch
        final docRef = FirebaseFirestore.instance
            .collection(AppConstants.collectionNotifications)
            .doc(notification.id);
        batch.set(docRef, notification.toJson());

        notificationIds.add(notification.id);
        notifications.add(notification);
      }

      // Execute batch write to Firestore
      await batch.commit();

      // Cache all notifications to Hive
      for (final notification in notifications) {
        await _hiveService.saveNotification(notification);
      }

      return notificationIds;
    } catch (e) {
      throw Exception('Failed to create notifications for users: $e');
    }
  }

  // ==================== READ ====================

  /// Get all notifications for a specific user
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int? limit,
    bool unreadOnly = false,
  }) async {
    try {
      // Try to get from cache first
      final cachedNotifications =
          await _hiveService.getNotifications(userId: userId);
      if (cachedNotifications.isNotEmpty) {
        var filtered = cachedNotifications;
        if (unreadOnly) {
          filtered = filtered.where((n) => !n.isRead).toList();
        }
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return limit != null ? filtered.take(limit).toList() : filtered;
      }

      // If cache is empty, fetch from Firestore
      Query query = FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Cache the fetched notifications
      for (final notification in notifications) {
        await _hiveService.saveNotification(notification);
      }

      return notifications;
    } catch (e) {
      // If Firestore fails, return cached data
      final cachedNotifications =
          await _hiveService.getNotifications(userId: userId);
      var filtered = cachedNotifications;
      if (unreadOnly) {
        filtered = filtered.where((n) => !n.isRead).toList();
      }
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return limit != null ? filtered.take(limit).toList() : filtered;
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      // Try cache first for better performance
      final cachedNotifications =
          await _hiveService.getNotifications(userId: userId);
      if (cachedNotifications.isNotEmpty) {
        return cachedNotifications.where((n) => !n.isRead).length;
      }

      // Otherwise, query Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // Fallback to cache
      final cachedNotifications =
          await _hiveService.getNotifications(userId: userId);
      return cachedNotifications.where((n) => !n.isRead).length;
    }
  }

  /// Stream notifications for a user (real-time updates)
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) =>
              NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Update cache in background
      for (final notification in notifications) {
        _hiveService.saveNotification(notification);
      }

      return notifications;
    });
  }

  /// Stream unread count for a user (real-time badge updates)
  Stream<int> streamUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== UPDATE ====================

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      final now = DateTime.now();

      // Update in Firestore
      await _firestoreService.updateDocument(
        collectionPath: AppConstants.collectionNotifications,
        documentId: notificationId,
        data: {
          'isRead': true,
          'readAt': now.toIso8601String(),
        },
      );

      // Update in Hive cache
      final notification = await _hiveService.getNotificationById(notificationId);
      if (notification != null) {
        final updatedNotification = notification.copyWith(
          isRead: true,
          readAt: now,
        );
        await _hiveService.saveNotification(updatedNotification);
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      // Get all unread notifications
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': now.toIso8601String(),
        });
      }

      await batch.commit();

      // Update cache
      final cachedNotifications =
          await _hiveService.getNotifications(userId: userId);
      for (final notification in cachedNotifications) {
        if (!notification.isRead) {
          final updated = notification.copyWith(isRead: true, readAt: now);
          await _hiveService.saveNotification(updated);
        }
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // ==================== DELETE ====================

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Delete from Firestore
      await _firestoreService.deleteDocument(
        collectionPath: AppConstants.collectionNotifications,
        documentId: notificationId,
      );

      // Delete from Hive cache
      await _hiveService.deleteNotification(notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear from cache
      await _hiveService.clearNotifications(userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Delete old read notifications (cleanup - e.g., older than 30 days)
  Future<void> deleteOldNotifications(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        await _hiveService.deleteNotification(doc.id);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }
}
