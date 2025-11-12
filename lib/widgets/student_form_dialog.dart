import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/app_theme.dart';

class StudentFormDialog extends StatefulWidget {
  final UserModel? student; // null for create, non-null for edit
  final Future<bool> Function(String username, String? excludeId)?
      checkUsernameExists;

  const StudentFormDialog({
    super.key,
    this.student,
    this.checkUsernameExists,
  });

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();

  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _usernameController.text = widget.student!.username;
      _fullNameController.text = widget.student!.fullName;
      _emailController.text = widget.student!.email;
      _studentIdController.text = widget.student!.studentId ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<String?> _validateUsername(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final username = value.trim().toLowerCase();

    // Check format (letters and numbers only, no spaces)
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
      return 'Username must contain only letters and numbers (no spaces)';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    // Check if username exists (only for new students or if username changed)
    if (widget.checkUsernameExists != null &&
        (widget.student == null ||
            username != widget.student!.username.toLowerCase())) {
      setState(() => _isCheckingUsername = true);
      final exists =
          await widget.checkUsernameExists!(username, widget.student?.id);
      setState(() => _isCheckingUsername = false);

      if (exists) {
        return 'Username already exists';
      }
    }

    return null;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional async validation for username
    final usernameError = await _validateUsername(_usernameController.text);
    if (usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(usernameError), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.of(context).pop({
      'username': _usernameController.text.trim().toLowerCase(),
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'studentId': _studentIdController.text.trim().isEmpty
          ? null
          : _studentIdController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Student' : 'Create New Student'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card for new students
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Default password will be the username',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username*',
                  hintText: 'e.g., johndoe, student001',
                  prefixIcon: const Icon(Icons.person),
                  helperText: 'Lowercase letters and numbers only',
                  enabled: !isEditing, // Username cannot be changed
                ),
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  final username = value.trim().toLowerCase();
                  if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
                    return 'Only letters and numbers (no spaces)';
                  }
                  if (username.length < 3) {
                    return 'At least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name*',
                  hintText: 'e.g., John Doe',
                  prefixIcon: Icon(Icons.badge),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  // Check for at least first and last name
                  if (!value.trim().contains(' ')) {
                    return 'Please enter full name (first and last name)';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email*',
                  hintText: 'e.g., student@university.edu',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  // Simple email validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Student ID (Optional)
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID (Optional)',
                  hintText: 'e.g., 2021001234',
                  prefixIcon: Icon(Icons.confirmation_number),
                  helperText: 'Leave empty if not applicable',
                ),
                keyboardType: TextInputType.text,
                maxLength: 50,
              ),

              if (_isCheckingUsername)
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
                      Text('Checking username...',
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
          onPressed: _isCheckingUsername ? null : _save,
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
