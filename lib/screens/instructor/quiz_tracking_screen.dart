import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_constants.dart';
import '../../models/quiz_submission_model.dart';
import '../../providers/quiz_provider.dart';

/// Screen for instructors to track quiz results and export to CSV
class QuizTrackingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String courseId;

  const QuizTrackingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.courseId,
  });

  @override
  State<QuizTrackingScreen> createState() => _QuizTrackingScreenState();
}

class _QuizTrackingScreenState extends State<QuizTrackingScreen> {
  String _sortBy = 'submittedAt'; // submittedAt, score, studentName
  bool _sortAscending = false;
  String _filterBy = 'all'; // all, best, latest
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    await Future.wait([
      provider.loadAllSubmissions(widget.quizId),
      provider.loadQuizStatistics(widget.quizId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results - ${widget.quizTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingSubmissions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.submissionError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.submissionError}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final submissions = _filterAndSortSubmissions(provider.submissions);

          return Column(
            children: [
              _buildStatisticsCard(provider),
              _buildFiltersBar(),
              Expanded(
                child: submissions.isEmpty
                    ? _buildEmptyState()
                    : _buildSubmissionsList(submissions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(QuizProvider provider) {
    final stats = provider.quizStatistics;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiz Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Submissions',
                  stats['totalSubmissions'].toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Students',
                  stats['uniqueStudents'].toString(),
                  Icons.people,
                  Colors.purple,
                ),
                _buildStatItem(
                  'Average',
                  '${stats['averageScore'].toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Pass Rate',
                  '${stats['passRate'].toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Highest: ${stats['highestScore'].toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(width: 24),
                Text(
                  'Lowest: ${stats['lowestScore'].toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Text('Sort by:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'submittedAt', child: Text('Date')),
              DropdownMenuItem(value: 'score', child: Text('Score')),
              DropdownMenuItem(value: 'studentName', child: Text('Name')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
          const SizedBox(width: 16),
          const Text('Filter:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _filterBy,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Attempts')),
              DropdownMenuItem(value: 'best', child: Text('Best Only')),
              DropdownMenuItem(value: 'latest', child: Text('Latest Only')),
            ],
            onChanged: (value) {
              setState(() {
                _filterBy = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<QuizSubmissionModel> _filterAndSortSubmissions(
      List<QuizSubmissionModel> submissions) {
    List<QuizSubmissionModel> filtered = List.from(submissions);

    // Apply filter
    if (_filterBy == 'best') {
      // Get best submission for each student
      final Map<String, QuizSubmissionModel> bestSubmissions = {};
      for (final submission in filtered) {
        final existing = bestSubmissions[submission.studentId];
        if (existing == null || submission.score > existing.score) {
          bestSubmissions[submission.studentId] = submission;
        }
      }
      filtered = bestSubmissions.values.toList();
    } else if (_filterBy == 'latest') {
      // Get latest submission for each student
      final Map<String, QuizSubmissionModel> latestSubmissions = {};
      for (final submission in filtered) {
        final existing = latestSubmissions[submission.studentId];
        if (existing == null ||
            submission.submittedAt.isAfter(existing.submittedAt)) {
          latestSubmissions[submission.studentId] = submission;
        }
      }
      filtered = latestSubmissions.values.toList();
    }

    // Apply sort
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'score':
          comparison = a.score.compareTo(b.score);
          break;
        case 'studentName':
          comparison = a.studentName.compareTo(b.studentName);
          break;
        case 'submittedAt':
        default:
          comparison = a.submittedAt.compareTo(b.submittedAt);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No submissions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Student submissions will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(List<QuizSubmissionModel> submissions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(QuizSubmissionModel submission) {
    final isPassed = submission.score >= 50;
    final scoreColor = submission.score >= 80
        ? Colors.green
        : submission.score >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor.withOpacity(0.1),
          child: Text(
            submission.score.toStringAsFixed(0),
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          submission.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(submission.submittedAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text('Attempt ${submission.attemptNumber}'),
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
            const SizedBox(width: 8),
            Icon(
              isPassed ? Icons.check_circle : Icons.cancel,
              color: isPassed ? Colors.green : Colors.red,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'Score',
                        submission.formattedScore,
                        Icons.grade,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        'Correct',
                        '${submission.correctAnswersCount}/${submission.totalQuestions}',
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'Duration',
                        submission.formattedDuration,
                        Icons.timer,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        'Started At',
                        DateFormat('HH:mm').format(submission.startedAt),
                        Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      final submissions = _filterAndSortSubmissions(provider.submissions);

      if (submissions.isEmpty) {
        throw Exception('No submissions to export');
      }

      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Student Name',
        'Student ID',
        'Score (%)',
        'Correct Answers',
        'Total Questions',
        'Duration',
        'Attempt Number',
        'Started At',
        'Submitted At',
        'Status',
      ]);

      // Data rows
      for (final submission in submissions) {
        rows.add([
          submission.studentName,
          submission.studentId,
          submission.score.toStringAsFixed(2),
          submission.correctAnswersCount,
          submission.totalQuestions,
          submission.formattedDuration,
          submission.attemptNumber,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(submission.startedAt),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(submission.submittedAt),
          submission.score >= 50 ? 'Passed' : 'Failed',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'quiz_results_${widget.quizTitle.replaceAll(RegExp(r'[^\w\s]'), '')}_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
