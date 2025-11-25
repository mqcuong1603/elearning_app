// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/notification_provider.dart';
// import '../../services/auth_service.dart';
// import '../../models/notification_model.dart';
// import '../../config/app_theme.dart';
// import '../../config/app_constants.dart';

// /// Notifications Screen
// /// Displays all notifications with read/unread status
// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({super.key});

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   bool _showUnreadOnly = false;
//   String _selectedFilter = 'all'; // 'all', 'announcement', 'assignment', 'quiz', 'message', etc.

//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//   }

//   Future<void> _initializeNotifications() async {
//     final authService = context.read<AuthService>();
//     final userId = authService.currentUser?.id;

//     if (userId != null) {
//       final notificationProvider = context.read<NotificationProvider>();
//       await notificationProvider.initializeRealTimeListener(userId);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = context.read<AuthService>();
//     final userId = authService.currentUser?.id;

//     if (userId == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Notifications'),
//         ),
//         body: const Center(
//           child: Text('User not logged in'),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         backgroundColor: AppTheme.primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           // Filter menu
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.filter_list),
//             tooltip: 'Filter notifications',
//             onSelected: (value) {
//               setState(() {
//                 _selectedFilter = value;
//               });
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'all',
//                 child: Text('All Notifications'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeAnnouncement,
//                 child: Text('Announcements'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeAssignment,
//                 child: Text('Assignments'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeQuiz,
//                 child: Text('Quizzes'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeMessage,
//                 child: Text('Messages'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeGrade,
//                 child: Text('Grades'),
//               ),
//               const PopupMenuItem(
//                 value: AppConstants.notificationTypeDeadline,
//                 child: Text('Deadlines'),
//               ),
//             ],
//           ),
//           // Mark all as read
//           IconButton(
//             icon: const Icon(Icons.done_all),
//             tooltip: 'Mark all as read',
//             onPressed: () => _markAllAsRead(context, userId),
//           ),
//           // Delete all
//           IconButton(
//             icon: const Icon(Icons.delete_sweep),
//             tooltip: 'Delete all',
//             onPressed: () => _deleteAllNotifications(context, userId),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Toggle for unread only
//           Container(
//             color: AppTheme.primaryColor.withValues(alpha: 0.1),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 const Text(
//                   'Show unread only',
//                   style: TextStyle(fontSize: 14),
//                 ),
//                 const Spacer(),
//                 Switch(
//                   value: _showUnreadOnly,
//                   onChanged: (value) {
//                     setState(() {
//                       _showUnreadOnly = value;
//                     });
//                   },
//                   activeTrackColor: AppTheme.primaryColor,
//                 ),
//               ],
//             ),
//           ),
//           // Notifications list
//           Expanded(
//             child: Consumer<NotificationProvider>(
//               builder: (context, notificationProvider, child) {
//                 if (notificationProvider.isLoading) {
//                   return const Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 }

//                 if (notificationProvider.error != null) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           color: Colors.red,
//                           size: 60,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Error: ${notificationProvider.error}',
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () => _initializeNotifications(),
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 var notifications = notificationProvider.notifications;

//                 // Filter by type
//                 if (_selectedFilter != 'all') {
//                   notifications = notifications
//                       .where((n) => n.type == _selectedFilter)
//                       .toList();
//                 }

//                 // Filter by read/unread
//                 if (_showUnreadOnly) {
//                   notifications = notifications.where((n) => !n.isRead).toList();
//                 }

//                 if (notifications.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.notifications_none,
//                           size: 80,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           _showUnreadOnly
//                               ? 'No unread notifications'
//                               : 'No notifications yet',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return RefreshIndicator(
//                   onRefresh: () => notificationProvider.refreshNotifications(userId),
//                   child: ListView.builder(
//                     itemCount: notifications.length,
//                     itemBuilder: (context, index) {
//                       final notification = notifications[index];
//                       return _buildNotificationTile(
//                         context,
//                         notification,
//                         userId,
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationTile(
//     BuildContext context,
//     NotificationModel notification,
//     String userId,
//   ) {
//     return Dismissible(
//       key: Key(notification.id),
//       direction: DismissDirection.endToStart,
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(
//           Icons.delete,
//           color: Colors.white,
//         ),
//       ),
//       onDismissed: (direction) {
//         context.read<NotificationProvider>().deleteNotification(notification.id);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Notification deleted')),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: notification.isRead ? Colors.white : AppTheme.primaryColor.withValues(alpha: 0.05),
//           border: Border(
//             bottom: BorderSide(color: Colors.grey[300]!),
//           ),
//         ),
//         child: ListTile(
//           leading: CircleAvatar(
//             backgroundColor: _getNotificationColor(notification.type),
//             child: Text(
//               notification.icon,
//               style: const TextStyle(fontSize: 20),
//             ),
//           ),
//           title: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   notification.title,
//                   style: TextStyle(
//                     fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//               if (!notification.isRead)
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: const BoxDecoration(
//                     color: Colors.blue,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//             ],
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 4),
//               Text(
//                 notification.message,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: Colors.grey[700],
//                   fontSize: 13,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 notification.relativeTime,
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//           onTap: () => _handleNotificationTap(context, notification, userId),
//           trailing: PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert),
//             onSelected: (value) {
//               if (value == 'mark_read') {
//                 context.read<NotificationProvider>().markAsRead(notification.id, userId);
//               } else if (value == 'delete') {
//                 context.read<NotificationProvider>().deleteNotification(notification.id);
//               }
//             },
//             itemBuilder: (context) => [
//               if (!notification.isRead)
//                 const PopupMenuItem(
//                   value: 'mark_read',
//                   child: Row(
//                     children: [
//                       Icon(Icons.check, size: 20),
//                       SizedBox(width: 8),
//                       Text('Mark as read'),
//                     ],
//                   ),
//                 ),
//               const PopupMenuItem(
//                 value: 'delete',
//                 child: Row(
//                   children: [
//                     Icon(Icons.delete, size: 20),
//                     SizedBox(width: 8),
//                     Text('Delete'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getNotificationColor(String type) {
//     switch (type) {
//       case AppConstants.notificationTypeAnnouncement:
//         return Colors.blue.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeAssignment:
//         return Colors.orange.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeQuiz:
//         return Colors.purple.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeMaterial:
//         return Colors.green.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeMessage:
//         return Colors.teal.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeForum:
//         return Colors.indigo.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeGrade:
//         return Colors.amber.withValues(alpha: 0.2);
//       case AppConstants.notificationTypeDeadline:
//         return Colors.red.withValues(alpha: 0.2);
//       default:
//         return Colors.grey.withValues(alpha: 0.2);
//     }
//   }

//   void _handleNotificationTap(
//     BuildContext context,
//     NotificationModel notification,
//     String userId,
//   ) {
//     // Mark as read
//     if (!notification.isRead) {
//       context.read<NotificationProvider>().markAsRead(notification.id, userId);
//     }

//     // Navigate to related screen based on notification type
//     // TODO: Implement navigation to related screens
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Notification tapped: ${notification.title}'),
//         duration: const Duration(seconds: 1),
//       ),
//     );
//   }

//   Future<void> _markAllAsRead(BuildContext context, String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Mark All as Read'),
//         content: const Text('Are you sure you want to mark all notifications as read?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Mark All'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && context.mounted) {
//       await context.read<NotificationProvider>().markAllAsRead(userId);
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('All notifications marked as read')),
//         );
//       }
//     }
//   }

//   Future<void> _deleteAllNotifications(BuildContext context, String userId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete All Notifications'),
//         content: const Text(
//           'Are you sure you want to delete all notifications? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete All'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && context.mounted) {
//       await context.read<NotificationProvider>().deleteAllNotifications(userId);
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('All notifications deleted')),
//         );
//       }
//     }
//   }
// }
