import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';

/// Screen for students to take quizzes with timer and auto-grading
class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String courseId;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
    required this.courseId,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  Timer? _timer;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuiz();
    });
  }

  Future<void> _startQuiz() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final success = await quizProvider.startQuiz(widget.quizId, widget.courseId);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quizProvider.quizError ?? 'Failed to start quiz'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Start the timer
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      if (provider.timeRemainingSeconds > 0) {
        provider.updateTimeRemaining(provider.timeRemainingSeconds - 1);
      } else {
        // Time's up! Auto-submit
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _confirmExit(),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<QuizProvider>(
            builder: (context, provider, child) {
              return Text(provider.selectedQuiz?.title ?? 'Quiz');
            },
          ),
          actions: [
            Consumer<QuizProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      _formatTime(provider.timeRemainingSeconds),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.timeRemainingSeconds < 300
                            ? Colors.red
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<QuizProvider>(
          builder: (context, provider, child) {
            if (_showResults) {
              return _buildResultsView(provider);
            }

            if (provider.quizQuestions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildProgressBar(provider),
                Expanded(
                  child: _buildQuestionView(
                    provider.quizQuestions[_currentQuestionIndex],
                    provider,
                  ),
                ),
                _buildNavigationBar(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(QuizProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${provider.totalQuestionsCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${provider.answeredQuestionsCount} answered',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: provider.progressPercentage / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(QuestionModel question, QuizProvider provider) {
    final selectedChoiceId = provider.selectedAnswers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getDifficultyColor(question.difficulty).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getDifficultyColor(question.difficulty)),
            ),
            child: Text(
              question.difficulty.toUpperCase(),
              style: TextStyle(
                color: _getDifficultyColor(question.difficulty),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Question text
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          // Choices
          ...question.choices.asMap().entries.map((entry) {
            final index = entry.key;
            final choice = entry.value;
            final isSelected = selectedChoiceId == choice.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  provider.selectAnswer(question.id, choice.id);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D...
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(QuizProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex--;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
              ),
            ),
          const Spacer(),
          // Question navigation dots
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  provider.totalQuestionsCount,
                  (index) {
                    final question = provider.quizQuestions[index];
                    final isAnswered = provider.selectedAnswers.containsKey(question.id);
                    final isCurrent = index == _currentQuestionIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(context).primaryColor
                              : isAnswered
                                  ? Colors.green
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_currentQuestionIndex < provider.totalQuestionsCount - 1)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex++;
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: provider.isQuizCompleted && !_isSubmitting
                  ? () => _confirmSubmit()
                  : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsView(QuizProvider provider) {
    final submission = provider.currentSubmission;
    if (submission == null) {
      return const Center(child: Text('No results available'));
    }

    final isPassed = submission.score >= 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            size: 100,
            color: isPassed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            isPassed ? 'Congratulations!' : 'Keep Trying!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Score',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submission.formattedScore,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isPassed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildResultRow(
                    'Correct Answers',
                    '${submission.correctAnswersCount} / ${submission.totalQuestions}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const Divider(height: 32),
                  _buildResultRow(
                    'Time Taken',
                    submission.formattedDuration,
                    Icons.timer,
                    Colors.blue,
                  ),
                  const Divider(height: 32),
                  _buildResultRow(
                    'Attempt',
                    '#${submission.attemptNumber}',
                    Icons.repeat,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Quizzes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Quiz'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (result == true) {
      _timer?.cancel();
      final provider = Provider.of<QuizProvider>(context, listen: false);
      provider.cancelQuiz();
    }

    return result ?? false;
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text(
          'Are you sure you want to submit? You cannot change your answers after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;

    final success = await quizProvider.submitQuiz(
      studentId: user.id,
      studentName: user.fullName,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        setState(() {
          _showResults = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                quizProvider.submissionError ?? 'Failed to submit quiz'),
          ),
        );
      }
    }
  }
}
