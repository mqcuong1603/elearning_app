import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_list_provider.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';

/// Course Form Screen
/// Handles both Create and Edit modes for courses
/// PDF Requirement: Course includes code, name, sessions (10 or 15), belongs to semester
class CourseFormScreen extends ConsumerStatefulWidget {
  final String? courseId; // null = create mode
  final String? semesterId; // For create mode

  const CourseFormScreen({
    super.key,
    this.courseId,
    this.semesterId,
  });

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _sessions = 15; // Default to 15 sessions
  bool _isLoading = false;
  CourseEntity? _originalCourse;
  String? _effectiveSemesterId;
  String? _semesterName;

  bool get _isEditMode => widget.courseId != null;

  @override
  void initState() {
    super.initState();
    _effectiveSemesterId = widget.semesterId;
    if (_isEditMode) {
      _loadCourseData();
    } else if (widget.semesterId != null) {
      _loadSemesterInfo();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesterInfo() async {
    try {
      final semesterRepo = ref.read(semesterRepositoryProvider);
      final semester = await semesterRepo.getSemesterById(widget.semesterId!);
      if (semester != null && mounted) {
        setState(() {
          _semesterName = semester.name;
        });
      }
    } catch (e) {
      // Ignore errors, just won't show semester name
    }
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      final course = await repository.getCourseByIdWithDetails(widget.courseId!);

      if (!mounted) return;

      if (course != null) {
        setState(() {
          _originalCourse = course;
          _effectiveSemesterId = course.semesterId;
          _semesterName = course.semesterName;
          _codeController.text = course.code;
          _nameController.text = course.name;
          _descriptionController.text = course.description;
          _sessions = course.sessions;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading course: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_effectiveSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semester information is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      final authState = ref.read(authStateProvider);
      final code = _codeController.text.trim();

      // Get instructor ID (admin user)
      final instructorId = authState.user?.id ?? '';
      if (instructorId.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for duplicate code within same semester (only if code changed in edit mode)
      if (!_isEditMode || (_isEditMode && code != _originalCourse!.code)) {
        final existingCourses = await repository.getCoursesBySemester(_effectiveSemesterId!);
        final duplicate = existingCourses.any((c) => c.code.toLowerCase() == code.toLowerCase());
        if (duplicate) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course code "$code" already exists in this semester'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final entity = CourseEntity(
        id: _isEditMode ? _originalCourse!.id : '',
        code: code,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        semesterId: _effectiveSemesterId!,
        instructorId: instructorId,
        sessions: _sessions,
        createdAt: _isEditMode ? _originalCourse!.createdAt : DateTime.now(),
        updatedAt: _isEditMode ? DateTime.now() : null,
      );

      final success = _isEditMode
          ? await repository.updateCourse(entity)
          : await repository.createCourse(entity);

      if (!mounted) return;

      if (success) {
        ref.invalidate(coursesBySemesterProvider(_effectiveSemesterId!));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Course updated successfully'
                  : 'Course created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Failed to update course'
                  : 'Failed to create course',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${_originalCourse?.name}"?\n\n'
          'This will also delete all groups, assignments, quizzes, and materials in this course. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      final success = await repository.deleteCourse(widget.courseId!);

      if (!mounted) return;

      if (success) {
        ref.invalidate(coursesBySemesterProvider(_effectiveSemesterId!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Course' : 'Create Course'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Course',
              onPressed: _isLoading ? null : _deleteCourse,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Semester Info Card
                    if (_semesterName != null)
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Semester',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _semesterName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Course Code
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Course Code *',
                        hintText: 'e.g., IT101, CS201',
                        helperText: 'Unique identifier for the course',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Course code is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Course Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name *',
                        hintText: 'e.g., Web Programming & Applications',
                        helperText: 'Full name of the course',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Course name is required';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter course description...',
                        helperText: 'Brief description of the course content',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Sessions Selection
                    Text(
                      'Number of Sessions *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select 10 or 15 sessions for this course',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _SessionCard(
                            sessions: 10,
                            isSelected: _sessions == 10,
                            onTap: () => setState(() => _sessions = 10),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionCard(
                            sessions: 15,
                            isSelected: _sessions == 15,
                            onTap: () => setState(() => _sessions = 15),
                          ),
                        ),
                      ],
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
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCourse,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_isEditMode ? 'Update' : 'Create'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Help Text
                    if (!_isEditMode)
                      Text(
                        'After creating the course, you can add groups, assignments, quizzes, and materials.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Session Selection Card
class _SessionCard extends StatelessWidget {
  final int sessions;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionCard({
    required this.sessions,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '$sessions',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'sessions',
              style: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
