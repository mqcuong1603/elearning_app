import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/semester_model.dart';
import '../config/app_constants.dart';
import '../config/app_theme.dart';

class CourseFormDialog extends StatefulWidget {
  final CourseModel? course; // null for create, non-null for edit
  final SemesterModel semester;
  final Future<bool> Function(String code, String? excludeId) checkCodeExists;

  const CourseFormDialog({
    super.key,
    this.course,
    required this.semester,
    required this.checkCodeExists,
  });

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedSessions = 10;
  bool _isCheckingCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _codeController.text = widget.course!.code;
      _nameController.text = widget.course!.name;
      _descriptionController.text = widget.course!.description ?? '';
      _selectedSessions = widget.course!.sessions;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _validateCode(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'Course code is required';
    }

    final code = value.trim().toUpperCase();

    // Check format (letters and numbers only)
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
      return 'Code must contain only letters and numbers';
    }

    if (code.length < 3) {
      return 'Code must be at least 3 characters';
    }

    // Check if code exists (only for new courses or if code changed)
    if (widget.course == null || code != widget.course!.code.toUpperCase()) {
      setState(() => _isCheckingCode = true);
      final exists =
          await widget.checkCodeExists(code, widget.course?.id);
      setState(() => _isCheckingCode = false);

      if (exists) {
        return 'Course code already exists in this semester';
      }
    }

    return null;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional async validation for code
    final codeError = await _validateCode(_codeController.text);
    if (codeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(codeError), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.of(context).pop({
      'code': _codeController.text.trim().toUpperCase(),
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'sessions': _selectedSessions,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Course' : 'Create New Course'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Semester info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Semester',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(widget.semester.displayText,
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Course Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code*',
                  hintText: 'e.g., CS101, IT202',
                  prefixIcon: Icon(Icons.code),
                  helperText: 'Letters and numbers only',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course code is required';
                  }
                  final code = value.trim().toUpperCase();
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
                    return 'Code must contain only letters and numbers';
                  }
                  if (code.length < 3) {
                    return 'Code must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name*',
                  hintText: 'e.g., Introduction to Programming',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course name is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Name must be at least 5 characters';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Number of Sessions
              const Text('Number of Sessions*',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.allowedCourseSessions.map((sessions) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$sessions sessions'),
                        selected: _selectedSessions == sessions,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSessions = sessions);
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief course description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),

              if (_isCheckingCode)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Checking course code...',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCheckingCode ? null : _save,
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
