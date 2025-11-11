import 'package:flutter/material.dart';

class AnnouncementListScreen extends StatelessWidget {
  final String courseId;

  const AnnouncementListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: Center(child: Text('Announcements for Course $courseId - Coming Soon')),
    );
  }
}
