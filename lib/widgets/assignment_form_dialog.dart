import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/assignment_model.dart';
import '../models/group_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../config/app_theme.dart';
import '../config/app_constants.dart';

/// Assignment Form Dialog
/// Used for creating and editing assignments with comprehensive settings
class AssignmentFormDialog extends StatefulWidget {
  final AssignmentModel? assignment; // Null for create, populated for edit
  final List<GroupModel> groups; // All groups in the course
  final String courseId;

  const AssignmentFormDialog({
    super.key,
    this.assignment,
    required this.groups,
    required this.courseId,
  });

  @override
  State<AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends State<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxAttemptsController = TextEditingController();
  final _maxFileSizeMBController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _allowLateSubmission = false;
  DateTime? _lateDeadline;
  List<String> _selectedGroupIds = [];
  bool _isForAllGroups = true;
  List<File> _attachmentFiles = [];
  List<String> _attachmentNames = [];
  List<AttachmentModel> _existingAttachments = [];

  // File format settings
  final List<String> _availableFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'zip',
    'rar',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv'
  ];
  List<String> _selectedFormats = ['pdf', 'doc', 'docx'];

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.assignment != null) {
      _titleController.text = widget.assignment!.title;
      _descriptionController.text = widget.assignment!.description;
      _startDate = widget.assignment!.startDate;
      _deadline = widget.assignment!.deadline;
      _allowLateSubmission = widget.assignment!.allowLateSubmission;
      _lateDeadline = widget.assignment!.lateDeadline;
      _maxAttemptsController.text = widget.assignment!.maxAttempts.toString();
      _maxFileSizeMBController.text =
          (widget.assignment!.maxFileSize / (1024 * 1024)).toString();
      _selectedFormats = List.from(widget.assignment!.allowedFileFormats);
      _selectedGroupIds = List.from(widget.assignment!.groupIds);
      _isForAllGroups = widget.assignment!.isForAllGroups;
      _existingAttachments = List.from(widget.assignment!.attachments);
    } else {
      // Default values for new assignment
      _maxAttemptsController.text = '3';
      _maxFileSizeMBController.text = '25';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxAttemptsController.dispose();
    _maxFileSizeMBController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
      );

      if (time != null) {
        setState(() {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          // Ensure deadline is after start date
          if (_deadline.isBefore(_startDate)) {
            _deadline = _startDate.add(const Duration(days: 7));
          }
        });
      }
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isAfter(_startDate)
          ? _deadline
          : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
      );

      if (time != null) {
        setState(() {
          _deadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          // Ensure late deadline is after deadline if it exists
          if (_lateDeadline != null && _lateDeadline!.isBefore(_deadline)) {
            _lateDeadline = _deadline.add(const Duration(days: 2));
          }
        });
      }
    }
  }

  Future<void> _pickLateDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lateDeadline ?? _deadline.add(const Duration(days: 2)),
      firstDate: _deadline,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _lateDeadline ?? _deadline.add(const Duration(hours: 1))),
      );

      if (time != null) {
        setState(() {
          _lateDeadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachmentFiles = result.paths
              .where((path) => path != null)
              .map((path) => File(path!))
              .toList();
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

  void _removeExistingAttachment(int index) {
    setState(() {
      _existingAttachments.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validation checks
      if (!_isForAllGroups && _selectedGroupIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please select at least one group or choose "All Groups"'),
          ),
        );
        return;
      }

      if (_selectedFormats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one allowed file format'),
          ),
        );
        return;
      }

      if (_allowLateSubmission && _lateDeadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a late deadline'),
          ),
        );
        return;
      }

      // Parse values
      final maxAttempts = int.tryParse(_maxAttemptsController.text) ?? 3;
      final maxFileSizeMB =
          double.tryParse(_maxFileSizeMBController.text) ?? 25.0;
      final maxFileSizeBytes = (maxFileSizeMB * 1024 * 1024).toInt();

      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDate,
        'deadline': _deadline,
        'allowLateSubmission': _allowLateSubmission,
        'lateDeadline': _lateDeadline,
        'maxAttempts': maxAttempts,
        'allowedFileFormats': _selectedFormats,
        'maxFileSize': maxFileSizeBytes,
        'groupIds': _isForAllGroups ? <String>[] : _selectedGroupIds,
        'attachmentFiles': _attachmentFiles,
        'existingAttachments': _existingAttachments,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assignment != null;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Title
            Row(
              children: [
                Text(
                  isEditing ? 'Edit Assignment' : 'Create Assignment',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Assignment Title *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Web Development Project - Module 1',
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
                          labelText: 'Description & Instructions *',
                          border: OutlineInputBorder(),
                          hintText:
                              'Provide detailed instructions for the assignment',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingL),

                      // Date & Time Settings
                      const Text(
                        'Dates & Deadlines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Start Date
                      InkWell(
                        onTap: _pickStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(dateFormat.format(_startDate)),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Deadline
                      InkWell(
                        onTap: _pickDeadline,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Deadline *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event),
                          ),
                          child: Text(dateFormat.format(_deadline)),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Allow Late Submission
                      CheckboxListTile(
                        title: const Text('Allow Late Submission'),
                        subtitle: const Text(
                            'Students can submit after the deadline'),
                        value: _allowLateSubmission,
                        onChanged: (value) {
                          setState(() {
                            _allowLateSubmission = value ?? false;
                            if (_allowLateSubmission && _lateDeadline == null) {
                              _lateDeadline =
                                  _deadline.add(const Duration(days: 2));
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      // Late Deadline (if late submission is allowed)
                      if (_allowLateSubmission) ...[
                        const SizedBox(height: AppTheme.spacingS),
                        InkWell(
                          onTap: _pickLateDeadline,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Late Deadline *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                              helperText: 'Final deadline for late submissions',
                            ),
                            child: Text(_lateDeadline != null
                                ? dateFormat.format(_lateDeadline!)
                                : 'Select late deadline'),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingL),

                      // Submission Settings
                      const Text(
                        'Submission Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Max Attempts
                      TextFormField(
                        controller: _maxAttemptsController,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Attempts *',
                          border: OutlineInputBorder(),
                          hintText: '0 = unlimited, 1-10 = limited attempts',
                          helperText: 'How many times students can submit',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter maximum attempts';
                          }
                          final attempts = int.tryParse(value);
                          if (attempts == null ||
                              attempts < 0 ||
                              attempts > 10) {
                            return 'Enter a number between 0 and 10';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Max File Size
                      TextFormField(
                        controller: _maxFileSizeMBController,
                        decoration: const InputDecoration(
                          labelText: 'Max File Size (MB) *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 25',
                          helperText: 'Maximum size per file in MB',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter maximum file size';
                          }
                          final size = double.tryParse(value);
                          if (size == null || size <= 0 || size > 100) {
                            return 'Enter a number between 1 and 100';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Allowed File Formats
                      const Text(
                        'Allowed File Formats *',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableFormats.map((format) {
                          final isSelected = _selectedFormats.contains(format);
                          return FilterChip(
                            label: Text(format.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFormats.add(format);
                                } else {
                                  _selectedFormats.remove(format);
                                }
                              });
                            },
                            selectedColor:
                                AppTheme.primaryColor.withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.spacingL),

                      // Group Scoping
                      const Text(
                        'Visibility & Scope',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      CheckboxListTile(
                        title: const Text('All Groups'),
                        subtitle: const Text(
                            'Visible to all students in this course'),
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
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }),
                      ],
                      const SizedBox(height: AppTheme.spacingL),

                      // Instructor Attachments
                      const Text(
                        'Attachments (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      const Text(
                        'Attach files/images that students need for this assignment',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add Files'),
                      ),

                      // Display existing attachments (when editing)
                      if (_existingAttachments.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingM),
                        const Text(
                          'Current Attachments:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        ...List.generate(_existingAttachments.length, (index) {
                          final attachment = _existingAttachments[index];
                          return Card(
                            color: Colors.blue[50],
                            child: ListTile(
                              leading: const Icon(Icons.cloud_done,
                                  color: Colors.blue),
                              title: Text(attachment.filename),
                              subtitle: Text(attachment.formattedSize),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _removeExistingAttachment(index),
                                tooltip: 'Remove attachment',
                              ),
                            ),
                          );
                        }),
                      ],

                      // Display newly selected files
                      if (_attachmentNames.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingM),
                        const Text(
                          'New Files to Upload:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        ...List.generate(_attachmentNames.length, (index) {
                          return Card(
                            color: Colors.green[50],
                            child: ListTile(
                              leading: const Icon(Icons.upload_file,
                                  color: Colors.green),
                              title: Text(_attachmentNames[index]),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeAttachment(index),
                                tooltip: 'Remove file',
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: AppTheme.spacingXL),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
