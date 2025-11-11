import 'package:flutter/material.dart';

class AssignmentListScreen extends StatelessWidget {
  final String courseId;

  const AssignmentListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: Center(child: Text('Assignments for Course $courseId - Coming Soon')),
    );
  }
}
