import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/course_model.dart';
import '../../../models/forum_topic_model.dart';
import '../../../providers/forum_provider.dart';
import '../../../services/auth_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';
import 'forum_topic_detail_screen.dart';
import 'create_topic_screen.dart';

/// Forum List Screen
/// Displays all forum topics for a course
class ForumListScreen extends StatefulWidget {
  final CourseModel course;

  const ForumListScreen({
    super.key,
    required this.course,
  });

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _loadTopics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forumProvider = context.read<ForumProvider>();
      forumProvider.loadTopicsByCourse(widget.course.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isInstructor = authService.currentUser?.role == AppConstants.roleInstructor;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Forum'),
            Text(
              widget.course.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTopics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Topics list
          Expanded(
            child: Consumer<ForumProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingTopics) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.topicsError != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.topicsError}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTopics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.topics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No topics yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a discussion!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadTopics(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.topics.length,
                    itemBuilder: (context, index) {
                      final topic = provider.topics[index];
                      return _buildTopicCard(topic, isInstructor, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTopic(context),
        icon: const Icon(Icons.add),
        label: const Text('New Topic'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search topics...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ForumProvider>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          context.read<ForumProvider>().searchTopics(value);
        },
      ),
    );
  }

  Widget _buildTopicCard(ForumTopicModel topic, bool isInstructor, ForumProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToTopicDetail(context, topic),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with pin indicator and menu
              Row(
                children: [
                  // Pin indicator
                  if (topic.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Options menu (instructor only)
                  if (isInstructor)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleTopicAction(value, topic, provider),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                topic.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(topic.isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                topic.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Content preview
              Text(
                topic.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 12),

              // Footer with author, time, and reply count
              Row(
                children: [
                  // Author info
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: topic.isAuthorInstructor
                        ? AppTheme.primaryColor
                        : Colors.blue,
                    child: Text(
                      topic.authorName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topic.authorName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (topic.isAuthorInstructor) ...[
                    const SizedBox(width: 4),
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
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.formatDateTime(topic.createdAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  // Reply count
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${topic.replyCount}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  // Attachment indicator
                  if (topic.attachments.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTopicAction(String action, ForumTopicModel topic, ForumProvider provider) {
    switch (action) {
      case 'pin':
        _togglePin(topic, provider);
        break;
      case 'delete':
        _deleteTopic(topic, provider);
        break;
    }
  }

  Future<void> _togglePin(ForumTopicModel topic, ForumProvider provider) async {
    final success = await provider.togglePinTopic(topic.id, !topic.isPinned);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(topic.isPinned ? 'Topic unpinned' : 'Topic pinned'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteTopic(ForumTopicModel topic, ForumProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: const Text('Are you sure you want to delete this topic? This will also delete all replies.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteTopic(topic.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topic deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToTopicDetail(BuildContext context, ForumTopicModel topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForumTopicDetailScreen(
          course: widget.course,
          topicId: topic.id,
        ),
      ),
    );
  }

  void _navigateToCreateTopic(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTopicScreen(course: widget.course),
      ),
    );
  }
}
