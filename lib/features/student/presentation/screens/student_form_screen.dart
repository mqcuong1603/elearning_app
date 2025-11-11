import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';
import 'package:elearning_app/features/student/domain/entities/student_entity.dart';
import 'package:elearning_app/features/student/presentation/providers/student_repository_provider.dart';
import 'package:elearning_app/features/student/presentation/providers/student_list_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_detail_provider.dart';
import 'package:elearning_app/features/group/presentation/providers/group_list_provider.dart';
import 'package:elearning_app/core/database/dao/user_dao.dart';

/// Student Enrollment Form Screen
/// Allows admin to manually enroll existing student users into course groups
/// PDF Requirement: One student per group per course
class StudentFormScreen extends ConsumerStatefulWidget {
  final String? courseId;

  const StudentFormScreen({super.key, this.courseId});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  String? _selectedGroupId;
  bool _isLoading = false;
  List<UserEntity> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final userDao = UserDao();
    final students = await userDao.getAllStudents();
    if (mounted) {
      setState(() {
        _allStudents = students;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courseId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enroll Student')),
        body: const Center(
          child: Text('Error: Course ID is required'),
        ),
      );
    }

    final courseAsync = ref.watch(courseDetailProvider(widget.courseId!));
    final groupsAsync = ref.watch(groupsByCourseWithCountsProvider(widget.courseId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Student'),
      ),
      body: courseAsync.when(
        data: (course) => groupsAsync.when(
          data: (groups) => SingleChildScrollView(
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
                                  'Enrolling student in this course',
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

                  // Group Selection
                  if (groups.isEmpty) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No groups available. Please create a group first before enrolling students.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/courses/${widget.courseId}/groups/new');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Group'),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Select Group',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      decoration: InputDecoration(
                        hintText: 'Choose a group',
                        prefixIcon: const Icon(Icons.groups),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: groups.map((group) {
                        return DropdownMenuItem(
                          value: group.id,
                          child: Text('${group.name} (${group.studentCount ?? 0} students)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroupId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a group';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Student Selection
                    const Text(
                      'Select Student',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStudentId,
                      decoration: InputDecoration(
                        hintText: 'Choose a student',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _allStudents.map((student) {
                        return DropdownMenuItem(
                          value: student.id,
                          child: Text('${student.displayName} (${student.email})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStudentId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a student';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // PDF Requirement Note
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'PDF Requirement: Each student can only be in one group per course.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            onPressed: _isLoading ? null : _enrollStudent,
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
                                : const Text('Enroll Student'),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                Text('Error loading groups: $err'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(groupsByCourseWithCountsProvider(widget.courseId!));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
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
                  ref.invalidate(courseDetailProvider(widget.courseId!));
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

  Future<void> _enrollStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(studentRepositoryProvider);
      final courseAsync = ref.read(courseDetailProvider(widget.courseId!));
      final course = courseAsync.value;

      if (course == null) {
        throw Exception('Course not found');
      }

      // Check if student is already enrolled in this course (PDF requirement)
      final isAlreadyEnrolled = await repository.isStudentEnrolled(
        _selectedStudentId!,
        widget.courseId!,
        course.semesterId,
      );

      if (isAlreadyEnrolled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showAlreadyEnrolledDialog();
        }
        return;
      }

      // Create enrollment
      final enrollment = StudentEnrollmentEntity(
        id: const Uuid().v4(),
        studentId: _selectedStudentId!,
        groupId: _selectedGroupId!,
        courseId: widget.courseId!,
        semesterId: course.semesterId,
        enrolledAt: DateTime.now(),
      );

      final success = await repository.enrollStudent(enrollment);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Refresh the student list
          ref.invalidate(enrollmentsByCourseWithDetailsProvider(widget.courseId!));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student enrolled successfully'),
              backgroundColor: Colors.green,
            ),
          );

          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enroll student'),
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

  void _showAlreadyEnrolledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Already Enrolled'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Requirement: One Group Per Course',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This student is already enrolled in a group for this course.',
            ),
            SizedBox(height: 8),
            Text(
              'Each student can only belong to one group per course. Remove them from their current group first if you want to reassign them.',
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
