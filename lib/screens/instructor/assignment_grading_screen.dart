import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment_model.dart';
import '../../models/assignment_submission_model.dart';
import '../../providers/assignment_provider.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

/// Assignment Grading Screen
/// Allows instructors to view student submissions and provide grades/feedback
class AssignmentGradingScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final String studentId;
  final String studentName;

  const AssignmentGradingScreen({
    super.key,
    required this.assignment,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AssignmentGradingScreen> createState() =>
      _AssignmentGradingScreenState();
}

class _AssignmentGradingScreenState extends State<AssignmentGradingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();

  List<AssignmentSubmissionModel> _submissions = [];
  AssignmentSubmissionModel? _selectedSubmission;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame to avoid notifying listeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissions();
    });
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      await provider.loadSubmissionsByStudent(
        assignmentId: widget.assignment.id,
        studentId: widget.studentId,
      );

      setState(() {
        _submissions = provider.submissions;
        // Select the latest submission by default
        if (_submissions.isNotEmpty) {
          _submissions
              .sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
          _selectSubmission(_submissions.first);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submissions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSubmission(AssignmentSubmissionModel submission) {
    setState(() {
      _selectedSubmission = submission;
      _gradeController.text =
          submission.grade != null ? submission.grade.toString() : '';
      _feedbackController.text = submission.feedback ?? '';
    });
  }

  Future<void> _submitGrade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubmission == null) {
      return;
    }

    final grade = double.tryParse(_gradeController.text);
    if (grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid grade')),
      );
      return;
    }

    // Confirm grading
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Grade'),
        content: Text(
          'Grade: $grade\n'
          'Feedback: ${_feedbackController.text.isEmpty ? 'None' : _feedbackController.text.substring(0, _feedbackController.text.length > 50 ? 50 : _feedbackController.text.length)}...\n\n'
          'Submit this grade?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final success = await provider.gradeSubmission(
        submissionId: _selectedSubmission!.id,
        grade: grade,
        feedback: _feedbackController.text.trim(),
        instructorId: currentUser.id,
      );

      if (success) {
        // Reload submissions to show updated grade
        await _loadSubmissions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grade submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Pop with result to trigger refresh in parent screen
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(provider.error ?? 'Failed to submit grade');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _openFile(String url, String filename) async {
    try {
      final uri = Uri.parse(url);
      // Try launching directly - canLaunchUrl can be unreliable on Android
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $filename. Please check your browser or file viewer is installed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Widget _buildSubmissionSelector() {
    if (_submissions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_submissions.length == 1) {
      return Card(
        elevation: 2,
        color: AppTheme.primaryColor.withOpacity(0.1),
        child: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingM),
          child: Text(
            'Single Attempt',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Attempt to Grade:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: _submissions.map((submission) {
                final isSelected = _selectedSubmission?.id == submission.id;
                return FilterChip(
                  label: Text('Attempt ${submission.attemptNumber}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _selectSubmission(submission);
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                  avatar: submission.isGraded
                      ? const Icon(Icons.check_circle, size: 16)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionDetails() {
    if (_selectedSubmission == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No submission selected',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.description, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Attempt ${_selectedSubmission!.attemptNumber} Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedSubmission!.isLate)
                  const Chip(
                    label: Text('Late', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.orange,
                  ),
              ],
            ),
            const Divider(),

            // Submission info
            _buildInfoRow(
              Icons.calendar_today,
              'Submitted',
              dateFormat.format(_selectedSubmission!.submittedAt),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow(
              Icons.person,
              'Student',
              _selectedSubmission!.studentName,
            ),
            const Divider(height: AppTheme.spacingL),

            // Submitted files
            const Text(
              'Submitted Files:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            if (_selectedSubmission!.files.isEmpty)
              const Text(
                'No files submitted',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._selectedSubmission!.files.map((file) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file, size: 32),
                    title: Text(file.filename),
                    subtitle: Text(file.formattedSize),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _openFile(file.url, file.filename),
                          tooltip: 'Download',
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _openFile(file.url, file.filename),
                          tooltip: 'Open',
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Current grade (if any)
            if (_selectedSubmission!.isGraded) ...[
              const Divider(height: AppTheme.spacingL),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grade, color: Colors.green),
                        const SizedBox(width: AppTheme.spacingS),
                        const Text(
                          'Current Grade:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          '${_selectedSubmission!.grade}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedSubmission!.feedback != null &&
                        _selectedSubmission!.feedback!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      const Text(
                        'Feedback:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(_selectedSubmission!.feedback!),
                    ],
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Graded on: ${dateFormat.format(_selectedSubmission!.gradedAt!)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildGradingForm() {
    if (_selectedSubmission == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.grade, color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    _selectedSubmission!.isGraded
                        ? 'Update Grade'
                        : 'Grade Submission',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Grade field
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 85',
                  helperText: 'Enter grade as a number (0-100)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a grade';
                  }
                  final grade = double.tryParse(value);
                  if (grade == null) {
                    return 'Please enter a valid number';
                  }
                  if (grade < 0 || grade > 100) {
                    return 'Grade must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Feedback field
              TextFormField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Provide feedback to the student...',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitGrade,
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
                  label: Text(_isSubmitting
                      ? 'Submitting...'
                      : _selectedSubmission!.isGraded
                          ? 'Update Grade'
                          : 'Submit Grade'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade: ${widget.studentName}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment info
                  Card(
                    elevation: 2,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.assignment.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Student: ${widget.studentName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Attempt selector
                  _buildSubmissionSelector(),
                  const SizedBox(height: AppTheme.spacingL),

                  // Submission details
                  _buildSubmissionDetails(),
                  const SizedBox(height: AppTheme.spacingL),

                  // Grading form
                  _buildGradingForm(),
                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
            ),
    );
  }
}
