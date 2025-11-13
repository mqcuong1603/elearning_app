import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/announcement_model.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';
import '../services/auth_service.dart';
import '../providers/announcement_provider.dart';

/// Announcement Card Widget
/// Displays announcement with comments in a social media style
class AnnouncementCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isInstructor;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    this.onEdit,
    this.onDelete,
    this.isInstructor = false,
  }) : super(key: key);

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isAddingComment = true);

    final success = await context.read<AnnouncementProvider>().addComment(
          announcementId: widget.announcement.id,
          userId: currentUser.id,
          userFullName: currentUser.fullName,
          content: _commentController.text.trim(),
        );

    if (mounted) {
      setState(() => _isAddingComment = false);

      if (success) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
        );
      } else {
        final error = context.read<AnnouncementProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to add comment')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AnnouncementProvider>().deleteComment(
            announcementId: widget.announcement.id,
            commentId: commentId,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment deleted successfully')),
          );
        } else {
          final error = context.read<AnnouncementProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Failed to delete comment')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with instructor info and actions
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    widget.announcement.instructorName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.announcement.instructorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppConstants.formatDateTime(
                            widget.announcement.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isInstructor) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: widget.onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Title
            Text(
              widget.announcement.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),

            // Content
            Text(
              widget.announcement.content,
              style: const TextStyle(fontSize: 14),
            ),

            // Attachments
            if (widget.announcement.attachments.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingM),
              const Divider(),
              const SizedBox(height: AppTheme.spacingS),
              Wrap(
                spacing: AppTheme.spacingS,
                runSpacing: AppTheme.spacingS,
                children: widget.announcement.attachments.map((attachment) {
                  return Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      attachment.filename,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: null, // TODO: Add download functionality
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppTheme.spacingM),
            const Divider(),

            // Stats and actions bar
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.announcement.viewCount} views',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.announcement.commentCount} comments',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showComments = !_showComments);
                  },
                  icon: Icon(
                    _showComments
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                  label: Text(_showComments ? 'Hide' : 'Show Comments'),
                ),
              ],
            ),

            // Comments section
            if (_showComments) ...[
              const Divider(),
              const SizedBox(height: AppTheme.spacingS),

              // Comment input
              if (currentUser != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        currentUser.fullName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: IconButton(
                            icon: _isAddingComment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            onPressed: _isAddingComment ? null : _addComment,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        enabled: !_isAddingComment,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],

              // Comments list
              if (widget.announcement.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  child: Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...widget.announcement.comments.map((comment) {
                  final isOwnComment = currentUser?.id == comment.userId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            comment.userFullName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.userFullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (isOwnComment || widget.isInstructor)
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 16, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _deleteComment(comment.id),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppConstants.formatDateTime(comment.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
