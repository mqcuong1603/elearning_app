import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../models/course_model.dart';
import '../../services/student_service.dart';
import '../../services/group_service.dart';
import '../../services/course_service.dart';

/// Debug screen to diagnose enrollment issues
class EnrollmentDebugScreen extends StatefulWidget {
  const EnrollmentDebugScreen({super.key});

  @override
  State<EnrollmentDebugScreen> createState() => _EnrollmentDebugScreenState();
}

class _EnrollmentDebugScreenState extends State<EnrollmentDebugScreen> {
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Results
  UserModel? _student;
  List<GroupModel> _enrolledGroups = [];
  List<CourseModel> _enrolledCourses = [];
  Map<String, List<String>> _groupDetails = {};

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _debugEnrollment() async {
    final studentIdOrUsername = _studentIdController.text.trim();
    if (studentIdOrUsername.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a student ID or username';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _student = null;
      _enrolledGroups = [];
      _enrolledCourses = [];
      _groupDetails = {};
    });

    try {
      final studentService = context.read<StudentService>();
      final groupService = context.read<GroupService>();
      final courseService = context.read<CourseService>();

      // Try to find student by studentId first
      UserModel? student;
      try {
        student = await studentService.getStudentByStudentId(studentIdOrUsername);
      } catch (e) {
        // If not found by studentId, try by username
        final allStudents = await studentService.getAllStudents();
        student = allStudents.firstWhere(
          (s) => s.username == studentIdOrUsername,
          orElse: () => throw Exception('Student not found'),
        );
      }

      // Get all groups
      final allGroups = await groupService.getAllGroups();

      // Find groups this student is in
      final studentGroups = allGroups.where((g) => g.hasStudent(student!.id)).toList();

      // Get courses for these groups
      final courses = <CourseModel>[];
      final groupDetails = <String, List<String>>{};

      for (final group in studentGroups) {
        final course = await courseService.getCourseById(group.courseId);
        if (course != null) {
          courses.add(course);
          groupDetails[group.name] = [
            'Group ID: ${group.id}',
            'Course: ${course.code} - ${course.name}',
            'Students in group: ${group.studentIds.length}',
          ];
        }
      }

      setState(() {
        _student = student;
        _enrolledGroups = studentGroups;
        _enrolledCourses = courses;
        _groupDetails = groupDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Debug Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Student Enrollment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter student ID (e.g., 522i0001) or username to debug:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID or Username',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 522i0001 or student01',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _debugEnrollment,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Debug'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_student != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Student Information',
                        icon: Icons.person,
                        children: [
                          _buildInfoRow('Firestore Document ID', _student!.id),
                          _buildInfoRow('Username', _student!.username),
                          _buildInfoRow('Full Name', _student!.fullName),
                          _buildInfoRow('Student ID', _student!.studentId ?? 'Not set'),
                          _buildInfoRow('Email', _student!.email),
                          _buildInfoRow('Role', _student!.role),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Enrollment Status',
                        icon: Icons.school,
                        children: [
                          _buildInfoRow(
                            'Number of Groups',
                            '${_enrolledGroups.length}',
                            valueColor: _enrolledGroups.isEmpty ? Colors.red : Colors.green,
                          ),
                          _buildInfoRow(
                            'Number of Courses',
                            '${_enrolledCourses.length}',
                            valueColor: _enrolledCourses.isEmpty ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                      if (_enrolledGroups.isEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Student is NOT enrolled in any groups!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This student needs to be added to a group to see courses.\n\n'
                                      'Important: When adding to groups, make sure to use the student\'s Firestore ID:\n'
                                      '${_student!.id}\n\n'
                                      'NOT the studentId field: ${_student!.studentId ?? "N/A"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_enrolledGroups.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Enrolled Groups (${_enrolledGroups.length})',
                          icon: Icons.group,
                          children: _enrolledGroups.map((group) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_groupDetails[group.name] ?? []).map(
                                    (detail) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        detail,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (_enrolledCourses.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Enrolled Courses (${_enrolledCourses.length})',
                          icon: Icons.book,
                          children: _enrolledCourses.map((course) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${course.code} - ${course.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Instructor: ${course.instructorName}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Sessions: ${course.sessions}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
