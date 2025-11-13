import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/course_model.dart';

class GroupFormDialog extends StatefulWidget {
  final GroupModel? group;
  final List<CourseModel> courses;
  final String? preSelectedCourseId;

  const GroupFormDialog({
    super.key,
    this.group,
    required this.courses,
    this.preSelectedCourseId,
  });

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _selectedCourseId = widget.group?.courseId ?? widget.preSelectedCourseId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a course')),
        );
        return;
      }

      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'courseId': _selectedCourseId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Group' : 'Add New Group'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g., Group 1, Group A',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Course Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a course'),
                items: widget.courses.map((course) {
                  return DropdownMenuItem(
                    value: course.id,
                    child: Text(
                      '${course.code} - ${course.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: isEditing
                    ? null // Can't change course when editing
                    : (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a course';
                  }
                  return null;
                },
              ),

              if (isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: Cannot change course for existing group',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
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
