import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_constants.dart';
import '../../models/quiz_model.dart';
import '../../models/group_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import 'quiz_tracking_screen.dart';

/// Screen for managing quizzes (Create, Edit, Delete)
class QuizManagementScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const QuizManagementScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    await Future.wait([
      quizProvider.loadQuizzesForCourse(widget.courseId),
      groupProvider.loadGroupsForCourse(widget.courseId),
      quizProvider.loadQuestionStatistics(widget.courseId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes - ${widget.courseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingQuizzes) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.quizError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.quizError}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.quizzes.isEmpty) {
            return _buildEmptyState();
          }

          return _buildQuizzesList(provider.quizzes);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuizDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No quizzes yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a quiz to assess your students',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList(List<QuizModel> quizzes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    final now = DateTime.now();
    final status = quiz.isUpcoming
        ? 'Upcoming'
        : quiz.isAvailable
            ? 'Active'
            : 'Closed';
    final statusColor = quiz.isUpcoming
        ? Colors.orange
        : quiz.isAvailable
            ? Colors.green
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToTracking(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quiz.description,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Opens: ${DateFormat('MMM dd, HH:mm').format(quiz.openDate)}',
                  ),
                  _buildInfoChip(
                    Icons.event_busy,
                    'Closes: ${DateFormat('MMM dd, HH:mm').format(quiz.closeDate)}',
                  ),
                  _buildInfoChip(
                    Icons.timer,
                    '${quiz.durationMinutes} min',
                  ),
                  _buildInfoChip(
                    Icons.repeat,
                    '${quiz.maxAttempts} attempts',
                  ),
                  _buildInfoChip(
                    Icons.quiz,
                    '${quiz.totalQuestions} questions',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (quiz.isForAllGroups)
                    Chip(
                      label: const Text('All Groups'),
                      avatar: const Icon(Icons.group, size: 16),
                    )
                  else
                    Chip(
                      label: Text('${quiz.groupIds.length} groups'),
                      avatar: const Icon(Icons.group, size: 16),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showQuizDialog(context, quiz: quiz),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, quiz),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  void _navigateToTracking(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTrackingScreen(
          quizId: quiz.id,
          quizTitle: quiz.title,
          courseId: widget.courseId,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
            'Are you sure you want to delete "${quiz.title}"? This will also delete all student submissions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<QuizProvider>(context, listen: false);
              final success = await provider.deleteQuiz(quiz.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Quiz deleted successfully'
                        : 'Failed to delete quiz'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQuizDialog(BuildContext context, {QuizModel? quiz}) {
    showDialog(
      context: context,
      builder: (context) => _QuizFormDialog(
        courseId: widget.courseId,
        quiz: quiz,
        onSaved: _loadData,
      ),
    );
  }
}

class _QuizFormDialog extends StatefulWidget {
  final String courseId;
  final QuizModel? quiz;
  final VoidCallback onSaved;

  const _QuizFormDialog({
    required this.courseId,
    this.quiz,
    required this.onSaved,
  });

  @override
  State<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<_QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _maxAttemptsController;
  late DateTime _openDate;
  late DateTime _closeDate;
  late Map<String, int> _questionStructure;
  late List<String> _selectedGroupIds;
  bool _isForAllGroups = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.quiz?.description ?? '');
    _durationController = TextEditingController(
        text: widget.quiz?.durationMinutes.toString() ?? '60');
    _maxAttemptsController =
        TextEditingController(text: widget.quiz?.maxAttempts.toString() ?? '2');

    _openDate = widget.quiz?.openDate ?? DateTime.now();
    _closeDate = widget.quiz?.closeDate ??
        DateTime.now().add(const Duration(days: 7));

    _questionStructure = widget.quiz?.questionStructure ?? {'easy': 5, 'medium': 3, 'hard': 2};
    _selectedGroupIds = widget.quiz?.groupIds ?? [];
    _isForAllGroups = widget.quiz?.isForAllGroups ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(widget.quiz == null ? 'Create Quiz' : 'Edit Quiz'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimePicker(
                        label: 'Open Date',
                        value: _openDate,
                        onChanged: (date) => setState(() => _openDate = date),
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimePicker(
                        label: 'Close Date',
                        value: _closeDate,
                        onChanged: (date) => setState(() => _closeDate = date),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 1) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxAttemptsController,
                              decoration: const InputDecoration(
                                labelText: 'Max Attempts',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 1) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Question Structure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildQuestionStructureField(),
                      const SizedBox(height: 16),
                      const Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Available to all groups'),
                        value: _isForAllGroups,
                        onChanged: (value) {
                          setState(() {
                            _isForAllGroups = value ?? false;
                            if (_isForAllGroups) {
                              _selectedGroupIds = [];
                            }
                          });
                        },
                      ),
                      if (!_isForAllGroups) _buildGroupSelector(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveQuiz,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );

          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(DateFormat('MMM dd, yyyy HH:mm').format(value)),
      ),
    );
  }

  Widget _buildQuestionStructureField() {
    return Column(
      children: [
        _buildDifficultyCounter('Easy', 'easy'),
        const SizedBox(height: 8),
        _buildDifficultyCounter('Medium', 'medium'),
        const SizedBox(height: 8),
        _buildDifficultyCounter('Hard', 'hard'),
      ],
    );
  }

  Widget _buildDifficultyCounter(String label, String difficulty) {
    final count = _questionStructure[difficulty] ?? 0;
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: count > 0
              ? () {
                  setState(() {
                    _questionStructure[difficulty] = count - 1;
                  });
                }
              : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            setState(() {
              _questionStructure[difficulty] = count + 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGroupSelector() {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingGroups) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = provider.groups;
        if (groups.isEmpty) {
          return const Text('No groups available');
        }

        return Column(
          children: groups.map((group) {
            final isSelected = _selectedGroupIds.contains(group.id);
            return CheckboxListTile(
              title: Text(group.name),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedGroupIds.add(group.id);
                  } else {
                    _selectedGroupIds.remove(group.id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_closeDate.isBefore(_openDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Close date must be after open date')),
      );
      return;
    }

    // Validate question structure
    final totalQuestions = _questionStructure.values.fold(0, (sum, count) => sum + count);
    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question to the quiz')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;

    bool success;
    if (widget.quiz == null) {
      success = await quizProvider.createQuiz(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        openDate: _openDate,
        closeDate: _closeDate,
        durationMinutes: int.parse(_durationController.text),
        maxAttempts: int.parse(_maxAttemptsController.text),
        questionStructure: _questionStructure,
        groupIds: _isForAllGroups ? [] : _selectedGroupIds,
        instructorId: user.id,
        instructorName: user.fullName,
      );
    } else {
      success = await quizProvider.updateQuiz(
        quizId: widget.quiz!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        openDate: _openDate,
        closeDate: _closeDate,
        durationMinutes: int.parse(_durationController.text),
        maxAttempts: int.parse(_maxAttemptsController.text),
        questionStructure: _questionStructure,
        groupIds: _isForAllGroups ? [] : _selectedGroupIds,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz == null
                ? 'Quiz created successfully'
                : 'Quiz updated successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizProvider.quizError ?? 'Failed to save quiz'),
          ),
        );
      }
    }
  }
}
