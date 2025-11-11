import 'package:flutter/material.dart';

class StudentListScreen extends StatelessWidget {
  final String courseId;

  const StudentListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Center(child: Text('Student List for Course $courseId - Coming Soon')),
    );
  }
}
