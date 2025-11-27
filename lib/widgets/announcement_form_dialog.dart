import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/announcement_model.dart';
import '../models/group_model.dart';
import '../config/app_theme.dart';

/// Announcement Form Dialog
/// Used for creating and editing announcements
class AnnouncementFormDialog extends StatefulWidget {
  final AnnouncementModel? announcement; // Null for create, populated for edit
  final List<GroupModel> groups; // All groups in the course
  final String courseId;

  const AnnouncementFormDialog({
    super.key,
    this.announcement,
    required this.groups,
    required this.courseId,
  });

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  List<String> _selectedGroupIds = [];
  bool _isForAllGroups = true;
  List<PlatformFile> _attachmentFiles = [];
  List<String> _attachmentNames = [];

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _contentController.text = widget.announcement!.content;
      _selectedGroupIds = List.from(widget.announcement!.groupIds);
      _isForAllGroups = widget.announcement!.isForAllGroups;
      // Note: Existing attachments are kept with the announcement, not editable here
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb, // Load file bytes on web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachmentFiles = result.files;
          _attachmentNames = result.files.map((file) => file.name).toList();
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

  void _removeAttachment(int index) {
    setState(() {
      _attachmentFiles.removeAt(index);
      _attachmentNames.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // If not for all groups, ensure at least one group is selected
      if (!_isForAllGroups && _selectedGroupIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please select at least one group or choose "All Groups"'),
          ),
        );
        return;
      }

      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'groupIds': _isForAllGroups ? <String>[] : _selectedGroupIds,
        'attachmentFiles': _attachmentFiles,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Announcement' : 'Create Announcement'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter announcement title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  maxLength: 200,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Content field (rich text)
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter announcement content',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Group scoping
                const Text(
                  'Visibility *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),

                CheckboxListTile(
                  title: const Text('All Groups'),
                  subtitle:
                      const Text('Visible to all students in this course'),
                  value: _isForAllGroups,
                  onChanged: (value) {
                    setState(() {
                      _isForAllGroups = value ?? true;
                      if (_isForAllGroups) {
                        _selectedGroupIds.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (!_isForAllGroups) ...[
                  const Divider(),
                  const Text(
                    'Select Groups:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  if (widget.groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No groups available in this course',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...widget.groups.map((group) {
                      return CheckboxListTile(
                        title: Text(group.name),
                        subtitle: Text('${group.studentCount} students'),
                        value: _selectedGroupIds.contains(group.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedGroupIds.add(group.id);
                            } else {
                              _selectedGroupIds.remove(group.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                ],

                const SizedBox(height: AppTheme.spacingM),
                const Divider(),

                // File attachments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Attachments (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Add Files'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),

                if (_attachmentNames.isNotEmpty)
                  ...List.generate(_attachmentNames.length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(
                          _attachmentNames[index],
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeAttachment(index),
                        ),
                      ),
                    );
                  }),

                if (isEditing &&
                    widget.announcement!.attachments.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  const Text(
                    'Existing Attachments:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  ...widget.announcement!.attachments.map((attachment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(
                          attachment.filename,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(attachment.formattedSize),
                        trailing: const Icon(Icons.check, color: Colors.green),
                      ),
                    );
                  }),
                  const Text(
                    'Note: Existing attachments will be kept. Add new files above.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
