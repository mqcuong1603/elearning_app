import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/material_model.dart';
// For AttachmentModel
import '../config/app_theme.dart';

/// Material Form Dialog
/// Used for creating and editing materials with files and links
class MaterialFormDialog extends StatefulWidget {
  final MaterialModel? material; // Null for create, populated for edit
  final String courseId;

  const MaterialFormDialog({
    super.key,
    this.material,
    required this.courseId,
  });

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _linkTitleController = TextEditingController();

  final List<PlatformFile> _newFiles = [];
  final List<String> _newFileNames = [];
  List<LinkModel> _links = [];
  final List<String> _filesToRemove = []; // IDs of existing files to remove

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.material != null) {
      _titleController.text = widget.material!.title;
      _descriptionController.text = widget.material!.description;
      _links = List.from(widget.material!.links);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkUrlController.dispose();
    _linkTitleController.dispose();
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
          _newFiles.addAll(result.files);
          _newFileNames.addAll(result.files.map((file) => file.name));
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

  void _removeNewFile(int index) {
    setState(() {
      _newFiles.removeAt(index);
      _newFileNames.removeAt(index);
    });
  }

  void _markExistingFileForRemoval(String fileId) {
    setState(() {
      if (_filesToRemove.contains(fileId)) {
        _filesToRemove.remove(fileId);
      } else {
        _filesToRemove.add(fileId);
      }
    });
  }

  void _showAddLinkDialog() {
    _linkUrlController.clear();
    _linkTitleController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkTitleController,
              decoration: const InputDecoration(
                labelText: 'Link Title *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Course Resources',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: _linkUrlController,
              decoration: const InputDecoration(
                labelText: 'URL *',
                border: OutlineInputBorder(),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = _linkUrlController.text.trim();
              final title = _linkTitleController.text.trim();

              if (url.isEmpty || title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both fields'),
                  ),
                );
                return;
              }

              // Basic URL validation
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL must start with http:// or https://'),
                  ),
                );
                return;
              }

              setState(() {
                _links.add(LinkModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: url,
                  title: title,
                ));
              });

              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Check if there's at least one file or link
      final hasExistingFiles = widget.material != null &&
          widget.material!.files.isNotEmpty &&
          _filesToRemove.length < widget.material!.files.length;
      final hasNewFiles = _newFiles.isNotEmpty;
      final hasLinks = _links.isNotEmpty;

      if (!hasExistingFiles && !hasNewFiles && !hasLinks) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add at least one file or link to the material',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'newFiles': _newFiles,
        'links': _links,
        'filesToRemove': _filesToRemove,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.material != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Material' : 'Create Material'),
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
                    hintText: 'Enter material title',
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

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter material description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                const Divider(),

                // Note about visibility
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Materials are automatically visible to all students in the course',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingM),
                const Divider(),

                // File attachments section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Files',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file, size: 20),
                      label: const Text('Add Files'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),

                // New files
                if (_newFileNames.isNotEmpty)
                  ...List.generate(_newFileNames.length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file,
                            color: Colors.blue),
                        title: Text(
                          _newFileNames[index],
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text('New file'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeNewFile(index),
                          tooltip: 'Remove file',
                        ),
                      ),
                    );
                  }),

                // Existing files (when editing)
                if (isEditing && widget.material!.files.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  const Text(
                    'Existing Files:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  ...widget.material!.files.map((file) {
                    final isMarkedForRemoval = _filesToRemove.contains(file.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isMarkedForRemoval
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      child: ListTile(
                        leading: Icon(
                          Icons.insert_drive_file,
                          color: isMarkedForRemoval ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          file.filename,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration: isMarkedForRemoval
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(file.formattedSize),
                        trailing: IconButton(
                          icon: Icon(
                            isMarkedForRemoval
                                ? Icons.restore_from_trash
                                : Icons.delete,
                            color:
                                isMarkedForRemoval ? Colors.blue : Colors.red,
                          ),
                          onPressed: () => _markExistingFileForRemoval(file.id),
                          tooltip: isMarkedForRemoval
                              ? 'Restore file'
                              : 'Delete file',
                        ),
                      ),
                    );
                  }),
                ],

                if (_newFileNames.isEmpty &&
                    (!isEditing || widget.material!.files.isEmpty))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No files added yet',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingM),
                const Divider(),

                // Links section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Links',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showAddLinkDialog,
                      icon: const Icon(Icons.link, size: 20),
                      label: const Text('Add Link'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),

                if (_links.isNotEmpty)
                  ...List.generate(_links.length, (index) {
                    final link = _links[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.link, color: Colors.orange),
                        title: Text(
                          link.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          link.url,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeLink(index),
                          tooltip: 'Remove link',
                        ),
                      ),
                    );
                  })
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No links added yet',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingS),
                const Text(
                  'Tip: Add at least one file or link to create a material',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
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
