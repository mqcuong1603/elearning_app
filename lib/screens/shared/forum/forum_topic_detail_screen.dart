import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/course_model.dart';
import '../../../models/forum_topic_model.dart';
import '../../../models/forum_reply_model.dart';
import '../../../models/announcement_model.dart';
import '../../../providers/forum_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/forum_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';

/// Forum Topic Detail Screen
/// Displays topic details and threaded replies
class ForumTopicDetailScreen extends StatefulWidget {
  final CourseModel course;
  final String topicId;

  const ForumTopicDetailScreen({
    super.key,
    required this.course,
    required this.topicId,
  });

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  String? _replyingToId;
  String? _replyingToAuthor;
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    // Load topic once for initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ForumProvider>().loadTopicById(widget.topicId);
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumService = context.read<ForumService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Discussion'),
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          final topic = provider.selectedTopic;
          if (topic == null) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('Topic not found'));
          }

          return Column(
            children: [
              // Topic details with real-time replies using StreamBuilder
              Expanded(
                child: StreamBuilder<List<ForumReplyModel>>(
                  stream: forumService.streamRepliesByTopic(widget.topicId),
                  builder: (context, snapshot) {
                    // Handle loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Handle error state
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Trigger rebuild by calling setState
                                setState(() {});
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Get replies from stream
                    final replies = snapshot.data ?? [];

                    // Organize replies by parent for threading
                    final topLevelReplies =
                        replies.where((r) => r.parentReplyId == null).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Trigger stream refresh by rebuilding
                        setState(() {});
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTopicCard(topic),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Replies header
                          Row(
                            children: [
                              const Icon(Icons.comment_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${replies.length} ${replies.length == 1 ? 'Reply' : 'Replies'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Replies list (threaded) - updated in real-time
                          ...topLevelReplies.map((reply) {
                            return _buildReplyCard(reply, replies, 0);
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Reply input
              _buildReplyInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopicCard(ForumTopicModel topic) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    final isAuthor = currentUser?.id == topic.authorId;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pin indicator
            if (topic.isPinned)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin,
                        size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Pinned Topic',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Title
            Text(
              topic.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: topic.isAuthorInstructor
                      ? AppTheme.primaryColor
                      : Colors.blue,
                  child: Text(
                    topic.authorName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          topic.authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (topic.isAuthorInstructor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                      ],
                    ),
                    Text(
                      AppConstants.formatDateTime(topic.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content
            Text(
              topic.content,
              style: const TextStyle(fontSize: 15),
            ),

            // Attachments
            if (topic.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...topic.attachments.map((attachment) {
                return _buildAttachmentItem(attachment);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(
      ForumReplyModel reply, List<ForumReplyModel> allReplies, int depth) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    final isAuthor = currentUser?.id == reply.authorId;
    final isInstructor = currentUser?.role == AppConstants.roleInstructor;
    final nestedReplies =
        allReplies.where((r) => r.parentReplyId == reply.id).toList();

    return Container(
      margin: EdgeInsets.only(left: depth * 24.0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: reply.isAuthorInstructor
                            ? AppTheme.primaryColor
                            : Colors.blue,
                        child: Text(
                          reply.authorName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.authorName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (reply.isAuthorInstructor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'Instructor',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              AppConstants.formatDateTime(reply.createdAt),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Delete button (for author or instructor)
                      if (isAuthor || isInstructor)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red,
                          onPressed: () => _deleteReply(reply),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Content
                  Text(
                    reply.content,
                    style: const TextStyle(fontSize: 14),
                  ),

                  // Attachments
                  if (reply.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...reply.attachments.map((attachment) {
                      return _buildAttachmentItem(attachment);
                    }),
                  ],

                  // Reply button
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _setReplyingTo(reply),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Reply'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nested replies
          if (nestedReplies.isNotEmpty)
            ...nestedReplies.map((nested) {
              return _buildReplyCard(nested, allReplies, depth + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(AttachmentModel attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _downloadAttachment(attachment),
        child: Row(
          children: [
            Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                attachment.filename,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              attachment.formattedSize,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Replying to indicator
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Replying to $_replyingToAuthor',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _clearReplyingTo,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Selected files
          if (_selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: _selectedFiles.map((file) {
                  return Chip(
                    label:
                        Text(file.name, style: const TextStyle(fontSize: 12)),
                    onDeleted: () {
                      setState(() {
                        _selectedFiles.remove(file);
                      });
                    },
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
            ),

          // Input row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFiles,
                tooltip: 'Attach files',
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submitReply,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setReplyingTo(ForumReplyModel reply) {
    setState(() {
      _replyingToId = reply.id;
      _replyingToAuthor = reply.authorName;
    });
    _replyFocusNode.requestFocus();
  }

  void _clearReplyingTo() {
    setState(() {
      _replyingToId = null;
      _replyingToAuthor = null;
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final forumProvider = context.read<ForumProvider>();

    final reply = await forumProvider.createReply(
      topicId: widget.topicId,
      content: content,
      authorId: currentUser.id,
      authorName: currentUser.fullName,
      authorRole: currentUser.role,
      parentReplyId: _replyingToId,
      attachmentFiles: _selectedFiles.isNotEmpty ? _selectedFiles : null,
    );

    if (reply != null && mounted) {
      _replyController.clear();
      _clearReplyingTo();
      setState(() {
        _selectedFiles = [];
      });
      // Snackbar removed - real-time stream will show the reply instantly
    }
  }

  Future<void> _deleteReply(ForumReplyModel reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text(
            'Are you sure you want to delete this reply? This will also delete nested replies.'),
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
      final provider = context.read<ForumProvider>();
      final success = await provider.deleteReply(reply);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _downloadAttachment(AttachmentModel attachment) async {
    try {
      if (kIsWeb) {
        // On web, open file in new browser tab
        final url = Uri.parse(attachment.url);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${attachment.filename}...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Could not open file');
        }
      } else {
        // On mobile/desktop, open with url_launcher (will download or open with default app)
        final url = Uri.parse(attachment.url);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading ${attachment.filename}...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Could not download file');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
