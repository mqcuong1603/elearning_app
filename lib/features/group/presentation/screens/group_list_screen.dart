import 'package:flutter/material.dart';

class GroupListScreen extends StatelessWidget {
  final String courseId;

  const GroupListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: Center(child: Text('Group List for Course $courseId - Coming Soon')),
    );
  }
}
