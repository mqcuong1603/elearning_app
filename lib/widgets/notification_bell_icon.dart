import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Notification Bell Icon Widget with Unread Badge
/// Shows a bell icon with a badge indicating the number of unread notifications
class NotificationBellIcon extends StatelessWidget {
  final VoidCallback onTap;
  final Color? iconColor;
  final double iconSize;

  const NotificationBellIcon({
    super.key,
    required this.onTap,
    this.iconColor,
    this.iconSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
              onPressed: onTap,
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
