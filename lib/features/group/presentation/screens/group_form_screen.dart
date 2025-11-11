import 'package:flutter/material.dart';

class GroupFormScreen extends StatelessWidget {
  final String courseId;
  final String? groupId;

  const GroupFormScreen({super.key, required this.courseId, this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupId == null ? 'New Group' : 'Edit Group'),
      ),
      body: const Center(child: Text('Group Form - Coming Soon')),
    );
  }
}
