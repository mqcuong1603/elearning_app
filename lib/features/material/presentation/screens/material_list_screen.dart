import 'package:flutter/material.dart';

class MaterialListScreen extends StatelessWidget {
  final String courseId;

  const MaterialListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      body: Center(child: Text('Materials for Course $courseId - Coming Soon')),
    );
  }
}
