import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_constants.dart';
import '../../models/question_model.dart';
import '../../providers/quiz_provider.dart';

/// Screen for managing question bank (Create, Edit, Delete questions)
class QuestionBankScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const QuestionBankScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String _selectedDifficulty = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    await provider.loadQuestions(widget.courseId);
    await provider.loadQuestionStatistics(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question Bank - ${widget.courseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingQuestions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.questionError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.questionError}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredQuestions = _filterQuestions(provider.questions);

          return Column(
            children: [
              _buildStatisticsCard(provider),
              _buildFiltersBar(),
              Expanded(
                child: filteredQuestions.isEmpty
                    ? _buildEmptyState()
                    : _buildQuestionsList(filteredQuestions),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
    );
  }

  Widget _buildStatisticsCard(QuizProvider provider) {
    final stats = provider.questionStatistics;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                'Total', stats['total'].toString(), Colors.blue),
            _buildStatItem(
                'Easy', stats['easy'].toString(), Colors.green),
            _buildStatItem(
                'Medium', stats['medium'].toString(), Colors.orange),
            _buildStatItem(
                'Hard', stats['hard'].toString(), Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedDifficulty,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'easy', child: Text('Easy')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'hard', child: Text('Hard')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDifficulty = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<QuestionModel> _filterQuestions(List<QuestionModel> questions) {
    return questions.where((q) {
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          q.difficulty == _selectedDifficulty;
      final matchesSearch = _searchQuery.isEmpty ||
          q.questionText.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDifficulty && matchesSearch;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create questions to build your quiz bank',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List<QuestionModel> questions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _getDifficultyIcon(question.difficulty),
        title: Text(
          question.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${question.choices.length} choices'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showQuestionDialog(context, question: question),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, question),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choices:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...question.choices.map((choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            choice.isCorrect
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: choice.isCorrect ? Colors.green : null,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(choice.text)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Text('E', style: TextStyle(color: Colors.white)),
        );
      case 'medium':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text('M', style: TextStyle(color: Colors.white)),
        );
      case 'hard':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Text('H', style: TextStyle(color: Colors.white)),
        );
      default:
        return const CircleAvatar(child: Icon(Icons.help));
    }
  }

  void _confirmDelete(BuildContext context, QuestionModel question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
            'Are you sure you want to delete this question? This action cannot be undone.'),
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
              final success = await provider.deleteQuestion(question.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Question deleted successfully'
                        : 'Failed to delete question'),
                  ),
                );
                if (success) {
                  await provider.loadQuestionStatistics(widget.courseId);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDialog(BuildContext context,
      {QuestionModel? question}) {
    showDialog(
      context: context,
      builder: (context) =>
          _QuestionFormDialog(
            courseId: widget.courseId,
            question: question,
            onSaved: _loadData,
          ),
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  final String courseId;
  final QuestionModel? question;
  final VoidCallback onSaved;

  const _QuestionFormDialog({
    required this.courseId,
    this.question,
    required this.onSaved,
  });

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late String _selectedDifficulty;
  late List<_ChoiceData> _choices;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.question?.questionText ?? '',
    );
    _selectedDifficulty = widget.question?.difficulty ?? 'medium';

    if (widget.question != null) {
      _choices = widget.question!.choices
          .map((c) => _ChoiceData(
                controller: TextEditingController(text: c.text),
                isCorrect: c.isCorrect,
              ))
          .toList();
    } else {
      _choices = List.generate(
        4,
        (index) => _ChoiceData(
          controller: TextEditingController(),
          isCorrect: index == 0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final choice in _choices) {
      choice.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'hard', child: Text('Hard')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Choices (select the correct answer):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildChoiceFields(),
              const SizedBox(height: 8),
              if (_choices.length < 6)
                TextButton.icon(
                  onPressed: _addChoice,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Choice'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveQuestion,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  List<Widget> _buildChoiceFields() {
    return List.generate(_choices.length, (index) {
      final choice = _choices[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _choices.indexWhere((c) => c.isCorrect),
              onChanged: (value) {
                setState(() {
                  for (int i = 0; i < _choices.length; i++) {
                    _choices[i].isCorrect = i == value;
                  }
                });
              },
            ),
            Expanded(
              child: TextFormField(
                controller: choice.controller,
                decoration: InputDecoration(
                  labelText: 'Choice ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            if (_choices.length > 2)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  if (_choices.length > 2) {
                    setState(() {
                      choice.controller.dispose();
                      _choices.removeAt(index);
                      // Ensure at least one choice is correct
                      if (!_choices.any((c) => c.isCorrect)) {
                        _choices[0].isCorrect = true;
                      }
                    });
                  }
                },
              ),
          ],
        ),
      );
    });
  }

  void _addChoice() {
    setState(() {
      _choices.add(_ChoiceData(
        controller: TextEditingController(),
        isCorrect: false,
      ));
    });
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one choice is correct
    if (!_choices.any((c) => c.isCorrect)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select one correct answer')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<QuizProvider>(context, listen: false);
    final choices = _choices
        .map((c) => ChoiceModel(
              id: const Uuid().v4(),
              text: c.controller.text.trim(),
              isCorrect: c.isCorrect,
            ))
        .toList();

    bool success;
    if (widget.question == null) {
      success = await provider.createQuestion(
        courseId: widget.courseId,
        questionText: _questionController.text.trim(),
        choices: choices,
        difficulty: _selectedDifficulty,
      );
    } else {
      success = await provider.updateQuestion(
        questionId: widget.question!.id,
        questionText: _questionController.text.trim(),
        choices: choices,
        difficulty: _selectedDifficulty,
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
            content: Text(widget.question == null
                ? 'Question created successfully'
                : 'Question updated successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.questionError ?? 'Failed to save question'),
          ),
        );
      }
    }
  }
}

class _ChoiceData {
  final TextEditingController controller;
  bool isCorrect;

  _ChoiceData({
    required this.controller,
    required this.isCorrect,
  });
}
