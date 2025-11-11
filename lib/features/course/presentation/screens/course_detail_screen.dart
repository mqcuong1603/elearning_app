import 'package:flutter/material.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: Center(child: Text('Course Details for ID: $courseId - Coming Soon')),
    );
  }
}
