import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/message_model.dart';
import '../../../models/announcement_model.dart';
import '../../../providers/message_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/message_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_constants.dart';

/// Chat Screen
/// Displays a conversation between student and instructor (ONLY)
class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerRole;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat (once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authService = context.read<AuthService>();
        final currentUser = authService.currentUser;
        if (currentUser != null) {
          context.read<MessageProvider>().markConversationAsRead(
                currentUser.id,
                widget.partnerId,
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    final messageService = context.read<MessageService>();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.partnerRole == AppConstants.roleInstructor
                  ? AppTheme.primaryColor
                  : Colors.blue,
              child: Text(
                widget.partnerName[0].toUpperCase(),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.partnerRole == AppConstants.roleInstructor)
                    const Text(
                      'Instructor',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info banner about student-instructor only messaging
          if (currentUser.role == AppConstants.roleStudent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Private messaging is only available with instructors',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),

          // Messages list with real-time updates using StreamBuilder
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messageService.streamConversation(
                  currentUser.id, widget.partnerId),
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
                            // Trigger rebuild
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final conversation = snapshot.data ?? [];

                if (conversation.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.length,
                  itemBuilder: (context, index) {
                    final message = conversation[index];
                    final isMe = message.senderId == currentUser.id;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Message input
          _buildMessageInput(currentUser),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (message.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...message.attachments.map((attachment) {
                      return _buildAttachmentItem(attachment, isMe);
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                AppConstants.formatDateTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(AttachmentModel attachment, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _downloadAttachment(attachment),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attachment,
              size: 16,
              color: isMe ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                attachment.filename,
                style: TextStyle(
                  fontSize: 13,
                  color: isMe ? Colors.white : AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              attachment.formattedSize,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(dynamic currentUser) {
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
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFiles,
                  tooltip: 'Attach files',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(currentUser),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(currentUser),
                  color: AppTheme.primaryColor,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<void> _sendMessage(dynamic currentUser) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) {
      return;
    }

    if (currentUser == null) return;

    final messageProvider = context.read<MessageProvider>();

    final message = await messageProvider.sendMessage(
      senderId: currentUser.id,
      senderName: currentUser.fullName,
      senderRole: currentUser.role,
      receiverId: widget.partnerId,
      receiverName: widget.partnerName,
      receiverRole: widget.partnerRole,
      content: content.isNotEmpty ? content : '[Attachment]',
      attachmentFiles: _selectedFiles.isNotEmpty ? _selectedFiles : null,
    );

    if (message != null && mounted) {
      _messageController.clear();
      setState(() {
        _selectedFiles = [];
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (mounted && messageProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
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
