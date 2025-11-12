import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elearning_app/features/quiz/domain/entities/quiz_entity.dart';
import 'package:elearning_app/features/quiz/presentation/providers/quiz_list_provider.dart';
import 'package:elearning_app/features/quiz/presentation/providers/quiz_repository_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_detail_provider.dart';
import 'package:elearning_app/features/group/presentation/providers/group_list_provider.dart';

/// Quiz List Screen
/// PDF Requirement: Quizzes with question bank and difficulty levels (easy, medium, hard)
class QuizListScreen extends ConsumerStatefulWidget {
  final String courseId;

  const QuizListScreen({super.key, required this.courseId});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizzesByCourseProvider(widget.courseId));
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final groupsAsync = ref.watch(groupsByCourseWithCountsProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Quiz',
            onPressed: () {
              context.push('/courses/${widget.courseId}/quizzes/new');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Course Context Banner
          courseAsync.when(
            data: (course) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.teal.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      course?.code ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course?.name ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Quizzes with difficulty levels',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Text('Error loading course: $err'),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Quizzes List
          Expanded(
            child: quizzesAsync.when(
              data: (quizzes) {
                if (quizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Quizzes Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a quiz to get started',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/courses/${widget.courseId}/quizzes/new');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Quiz'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter quizzes by search query
                final filteredQuizzes = quizzes.where((quiz) {
                  return quiz.title.toLowerCase().contains(_searchQuery) ||
                      quiz.description.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredQuizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No quizzes found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return groupsAsync.when(
                  data: (groups) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = filteredQuizzes[index];
                      return _QuizCard(
                        quiz: quiz,
                        allGroups: groups,
                        onDelete: () => _confirmDelete(quiz),
                        onEdit: () {
                          context.push('/courses/${widget.courseId}/quizzes/${quiz.id}/edit');
                        },
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading groups: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(quizzesByCourseProvider(widget.courseId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(QuizEntity quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"?\n\n'
          'This will also delete all student attempts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repository = ref.read(quizRepositoryProvider);
      final success = await repository.deleteQuiz(quiz.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quiz "${quiz.title}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the list
          ref.invalidate(quizzesByCourseProvider(widget.courseId));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete quiz'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Quiz Card Widget
class _QuizCard extends StatelessWidget {
  final QuizEntity quiz;
  final List<dynamic> allGroups;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _QuizCard({
    required this.quiz,
    required this.allGroups,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final targetGroupNames = allGroups
        .where((g) => quiz.targetGroupIds.contains(g.id))
        .map((g) => g.name)
        .toList();

    final isAllGroups = targetGroupNames.length == allGroups.length;

    // Determine status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (quiz.isClosed) {
      statusColor = Colors.grey;
      statusText = 'CLOSED';
      statusIcon = Icons.lock;
    } else if (quiz.isOpen) {
      statusColor = Colors.green;
      statusText = 'OPEN';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.blue;
      statusText = 'UPCOMING';
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Quiz Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              quiz.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Quiz Details
            Row(
              children: [
                // Duration
                _QuizDetailBadge(
                  icon: Icons.timer,
                  text: '${quiz.durationMinutes} min',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                // Total Questions
                _QuizDetailBadge(
                  icon: Icons.format_list_numbered,
                  text: '${quiz.totalQuestions} Q',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                // Attempts
                _QuizDetailBadge(
                  icon: Icons.repeat,
                  text: '${quiz.maxAttempts}x',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Difficulty Levels (PDF Requirement)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (quiz.easyQuestionsCount > 0)
                    _DifficultyBadge(
                      count: quiz.easyQuestionsCount,
                      label: 'Easy',
                      color: Colors.green,
                    ),
                  if (quiz.mediumQuestionsCount > 0)
                    _DifficultyBadge(
                      count: quiz.mediumQuestionsCount,
                      label: 'Medium',
                      color: Colors.orange,
                    ),
                  if (quiz.hardQuestionsCount > 0)
                    _DifficultyBadge(
                      count: quiz.hardQuestionsCount,
                      label: 'Hard',
                      color: Colors.red,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Close Time & Group Targeting
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Closes: ${DateFormat('MMM dd, HH:mm').format(quiz.closeTime)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAllGroups ? Colors.blue.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllGroups ? Icons.groups : Icons.group,
                        size: 12,
                        color: isAllGroups ? Colors.blue.shade700 : Colors.purple.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAllGroups ? 'All' : targetGroupNames.join(", "),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isAllGroups ? Colors.blue.shade900 : Colors.purple.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz Detail Badge Widget
class _QuizDetailBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _QuizDetailBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Difficulty Badge Widget (PDF Requirement)
class _DifficultyBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _DifficultyBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
