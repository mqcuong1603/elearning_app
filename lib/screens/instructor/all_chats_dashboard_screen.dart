import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/message_model.dart';
import '../shared/messaging/chat_screen.dart';

/// All Chats Dashboard Screen
/// Allows admin to view all conversations in the system
class AllChatsDashboardScreen extends StatefulWidget {
  const AllChatsDashboardScreen({super.key});

  @override
  State<AllChatsDashboardScreen> createState() => _AllChatsDashboardScreenState();
}

class _AllChatsDashboardScreenState extends State<AllChatsDashboardScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllConversations();
  }

  /// Open chat with a user after fetching their role
  Future<void> _openChatWithUser({
    required String userId,
    required String userName,
  }) async {
    try {
      final firestoreService = FirestoreService();

      // Fetch user data to get their role
      final userData = await firestoreService.getDocument(
        collection: AppConstants.collectionUsers,
        documentId: userId,
      );

      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      final userRole = userData['role'] as String;

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              partnerId: userId,
              partnerName: userName,
              partnerRole: userRole,
            ),
          ),
        );
        // Reload conversations after returning from chat
        _loadAllConversations();
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadAllConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = FirestoreService();

      // Get all messages
      final messagesData = await firestoreService.getAll(
        collection: AppConstants.collectionMessages,
        orderBy: 'createdAt',
        descending: true,
      );

      final messages = messagesData
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // Group messages by conversation (sender-receiver pair)
      final conversationsMap = <String, Map<String, dynamic>>{};

      for (var message in messages) {
        // Create a unique key for the conversation (sorted to ensure consistency)
        final users = [message.senderId, message.receiverId]..sort();
        final conversationKey = '${users[0]}_${users[1]}';

        if (!conversationsMap.containsKey(conversationKey)) {
          conversationsMap[conversationKey] = {
            'user1Id': users[0],
            'user1Name': message.senderId == users[0]
                ? message.senderName
                : message.receiverName,
            'user2Id': users[1],
            'user2Name': message.senderId == users[1]
                ? message.senderName
                : message.receiverName,
            'lastMessage': message.content,
            'lastMessageTime': message.createdAt,
            'messageCount': 1,
          };
        } else {
          // Update message count
          conversationsMap[conversationKey]!['messageCount'] =
              (conversationsMap[conversationKey]!['messageCount'] as int) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _conversations = conversationsMap.values.toList()
            ..sort((a, b) => (b['lastMessageTime'] as DateTime)
                .compareTo(a['lastMessageTime'] as DateTime));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading conversations: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }

    return _conversations.where((conv) {
      final user1Name = (conv['user1Name'] as String).toLowerCase();
      final user2Name = (conv['user2Name'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return user1Name.contains(query) || user2Name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Chats Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Statistics Card
          if (!_isLoading && _conversations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        icon: Icons.chat,
                        label: 'Total Conversations',
                        value: '${_conversations.length}',
                      ),
                      _buildStatItem(
                        context,
                        icon: Icons.message,
                        label: 'Total Messages',
                        value: _conversations
                            .fold<int>(
                              0,
                              (sum, conv) => sum + (conv['messageCount'] as int),
                            )
                            .toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppTheme.spacingM),

          // Conversations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              'No conversations yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _filteredConversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  'No conversations match your search',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAllConversations,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                left: AppTheme.spacingM,
                                right: AppTheme.spacingM,
                                bottom: AppTheme.spacingL,
                              ),
                              itemCount: _filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _filteredConversations[index];
                                return _buildConversationCard(conversation);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final user1Name = conversation['user1Name'] as String;
    final user2Name = conversation['user2Name'] as String;
    final lastMessage = conversation['lastMessage'] as String;
    final lastMessageTime = conversation['lastMessageTime'] as DateTime;
    final messageCount = conversation['messageCount'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: () async {
          // Fetch the actual user role before navigating
          await _openChatWithUser(
            userId: conversation['user2Id'],
            userName: user2Name,
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 20,
                          child: Text(
                            user1Name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: AppTheme.spacingS),
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 20,
                          child: Text(
                            user2Name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$user1Name ↔ $user2Name',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$messageCount messages',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              const Divider(),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lastMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                AppConstants.formatDateTime(lastMessageTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
