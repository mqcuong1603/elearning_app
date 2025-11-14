import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Provider for managing notification state
/// Handles real-time notification updates and unread count
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  // State
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<NotificationModel>>? _notificationStreamSubscription;
  StreamSubscription<int>? _unreadCountStreamSubscription;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get unread notifications only
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Get read notifications only
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // ==================== INITIALIZATION ====================

  /// Initialize real-time listener for notifications
  Future<void> initializeRealTimeListener(String userId) async {
    try {
      // Cancel existing subscriptions
      await _cancelSubscriptions();

      // Stream notifications
      _notificationStreamSubscription =
          _notificationService.streamUserNotifications(userId).listen(
        (notifications) {
          _notifications = notifications;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          print('Error streaming notifications: $error');
          notifyListeners();
        },
      );

      // Stream unread count
      _unreadCountStreamSubscription =
          _notificationService.streamUnreadCount(userId).listen(
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
        onError: (error) {
          print('Error streaming unread count: $error');
        },
      );
    } catch (e) {
      _error = e.toString();
      print('Error initializing notification listener: $e');
      notifyListeners();
    }
  }

  /// Cancel all subscriptions
  Future<void> _cancelSubscriptions() async {
    await _notificationStreamSubscription?.cancel();
    await _unreadCountStreamSubscription?.cancel();
    _notificationStreamSubscription = null;
    _unreadCountStreamSubscription = null;
  }

  // ==================== LOAD NOTIFICATIONS ====================

  /// Load notifications for a user (one-time fetch)
  Future<void> loadNotifications(String userId, {int? limit}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _notifications =
          await _notificationService.getUserNotifications(userId, limit: limit);
      _unreadCount = await _notificationService.getUnreadCount(userId);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      print('Error loading notifications: $e');
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
  }

  // ==================== MARK AS READ ====================

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _notificationService.markAsRead(notificationId, userId);

      // Update local state
      final index =
          _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      print('Error marking notification as read: $e');
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update local state
      _notifications = _notifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error marking all notifications as read: $e');
      notifyListeners();
    }
  }

  // ==================== DELETE ====================

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      final notificationWasUnread =
          _notifications.firstWhere((n) => n.id == notificationId).isRead ==
              false;
      _notifications.removeWhere((n) => n.id == notificationId);
      if (notificationWasUnread) {
        _unreadCount--;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error deleting notification: $e');
      notifyListeners();
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _notificationService.deleteAllUserNotifications(userId);

      // Update local state
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error deleting all notifications: $e');
      notifyListeners();
    }
  }

  // ==================== UTILITY ====================

  /// Get notification by ID
  NotificationModel? getNotificationById(String notificationId) {
    try {
      return _notifications.firstWhere((n) => n.id == notificationId);
    } catch (e) {
      return null;
    }
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get recent notifications (within 24 hours)
  List<NotificationModel> getRecentNotifications() {
    return _notifications.where((n) => n.isRecent).toList();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _cancelSubscriptions();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
