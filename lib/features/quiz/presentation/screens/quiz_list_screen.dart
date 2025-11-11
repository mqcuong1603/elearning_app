import 'package:flutter/material.dart';

class QuizListScreen extends StatelessWidget {
  final String courseId;

  const QuizListScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: Center(child: Text('Quizzes for Course $courseId - Coming Soon')),
    );
  }
}
