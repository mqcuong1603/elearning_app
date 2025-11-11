import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:elearning_app/features/group/domain/entities/group_entity.dart';
import 'package:elearning_app/features/group/presentation/providers/group_repository_provider.dart';
import 'package:elearning_app/features/group/presentation/providers/group_list_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_detail_provider.dart';

/// Group Form Screen (Create/Edit)
/// PDF Requirement: One group per course rule - validates on creation
class GroupFormScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String? groupId;

  const GroupFormScreen({
    super.key,
    required this.courseId,
    this.groupId,
  });

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  GroupEntity? _originalGroup;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.groupId != null;
    if (_isEditMode) {
      _loadGroup();
    }
  }

  Future<void> _loadGroup() async {
    final repository = ref.read(groupRepositoryProvider);
    final group = await repository.getGroupById(widget.groupId!);

    if (group != null && mounted) {
      setState(() {
        _originalGroup = group;
        _nameController.text = group.name;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Group' : 'New Group'),
      ),
      body: courseAsync.when(
        data: (course) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Context Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course?.code ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course?.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${course?.sessions ?? 0} sessions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // One Group Per Course Warning (only for new groups)
                if (!_isEditMode) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PDF Requirement: One group per course',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Group Name Field
                const Text(
                  'Group Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Group 1, Group A',
                    prefixIcon: const Icon(Icons.groups),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.trim().length < 2) {
                      return 'Group name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveGroup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEditMode ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error loading course: $err'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(courseDetailProvider(widget.courseId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(groupRepositoryProvider);
      final name = _nameController.text.trim();

      // PDF REQUIREMENT: One group per course - validate on creation only
      if (!_isEditMode) {
        final existingGroups = await repository.getGroupsByCourse(widget.courseId);
        if (existingGroups.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showOneGroupPerCourseError(existingGroups.first.name);
          }
          return;
        }
      }

      // Get course to extract semester_id
      final courseAsync = ref.read(courseDetailProvider(widget.courseId));
      final course = courseAsync.value;

      if (course == null) {
        throw Exception('Course not found');
      }

      final entity = GroupEntity(
        id: _isEditMode ? _originalGroup!.id : const Uuid().v4(),
        name: name,
        courseId: widget.courseId,
        semesterId: course.semesterId,
        createdAt: _isEditMode ? _originalGroup!.createdAt : DateTime.now(),
        updatedAt: _isEditMode ? DateTime.now() : null,
      );

      bool success;
      if (_isEditMode) {
        success = await repository.updateGroup(entity);
      } else {
        success = await repository.createGroup(entity);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Invalidate the groups list to refresh
          ref.invalidate(groupsByCourseWithCountsProvider(widget.courseId));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'Group updated' : 'Group created'),
              backgroundColor: Colors.green,
            ),
          );

          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOneGroupPerCourseError(String existingGroupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Cannot Create Group'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF Requirement: One Group Per Course',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This course already has a group named "$existingGroupName".',
            ),
            const SizedBox(height: 8),
            const Text(
              'Each course can only have one group. Please edit the existing group or delete it first.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
