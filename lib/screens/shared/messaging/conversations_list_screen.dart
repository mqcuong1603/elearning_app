import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/message_provider.dart';
import '../../../services/auth_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';
import 'chat_screen.dart';

/// Conversations List Screen
/// Displays all conversations for the current user (student-instructor only)
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        context.read<MessageProvider>().loadConversationsList(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Messages'),
            Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.unreadCount > 0) {
                  return Text(
                    '${provider.unreadCount} unread',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.conversationsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser?.role == AppConstants.roleInstructor
                        ? 'Students can message you here'
                        : 'Start a conversation with your instructor',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadConversations(),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: provider.conversationsList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = provider.conversationsList[index];
                return _buildConversationItem(conversation, currentUser!);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation, dynamic currentUser) {
    final partnerId = conversation['userId'] as String;
    final partnerName = conversation['userName'] as String;
    final partnerRole = conversation['userRole'] as String;
    final lastMessage = conversation['lastMessage'] as String;
    final lastMessageTime = conversation['lastMessageTime'] as DateTime;
    final isRead = conversation['isRead'] as bool;
    final unreadCount = conversation['unreadCount'] as int;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: partnerRole == AppConstants.roleInstructor
                ? AppTheme.primaryColor
                : Colors.blue,
            child: Text(
              partnerName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              partnerName,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (partnerRole == AppConstants.roleInstructor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Instructor',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            lastMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isRead ? Colors.grey[600] : Colors.black87,
              fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.formatDateTime(lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToChat(context, partnerId, partnerName, partnerRole),
    );
  }

  void _navigateToChat(
    BuildContext context,
    String partnerId,
    String partnerName,
    String partnerRole,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: partnerId,
          partnerName: partnerName,
          partnerRole: partnerRole,
        ),
      ),
    ).then((_) {
      // Reload conversations when returning
      _loadConversations();
    });
  }
}
