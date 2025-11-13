import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment_model.dart';
import '../../models/assignment_submission_model.dart';
import '../../models/user_model.dart';
import '../../providers/assignment_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';

/// Student Assignment Submission Screen
/// Allows students to view assignment details, submit work, and view submission history
class AssignmentSubmissionScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final UserModel student;

  const AssignmentSubmissionScreen({
    super.key,
    required this.assignment,
    required this.student,
  });

  @override
  State<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  List<PlatformFile> _selectedFiles = [];
  List<String> _selectedFileNames = [];
  List<AssignmentSubmissionModel> _submissions = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame to avoid notifying listeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissions();
    });
  }

  Future<void> _loadSubmissions() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.loadSubmissionsByStudent(
      assignmentId: widget.assignment.id,
      studentId: widget.student.id,
    );
    if (mounted) {
      setState(() {
        _submissions = provider.submissions;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: widget.assignment.allowedFileFormats,
        withData: kIsWeb, // Load file bytes on web
      );

      if (result != null && result.files.isNotEmpty) {
        // Validate file sizes
        final invalidFiles = <String>[];
        final validFiles = <PlatformFile>[];
        final validFileNames = <String>[];

        for (final platformFile in result.files) {
          // Get file size - works for both web (bytes) and mobile (path)
          final fileSize = platformFile.size;

          if (fileSize > widget.assignment.maxFileSize) {
            invalidFiles.add(platformFile.name);
          } else {
            validFiles.add(platformFile);
            validFileNames.add(platformFile.name);
          }
        }

        if (invalidFiles.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The following files exceed the maximum size (${widget.assignment.formattedMaxFileSize}):\n${invalidFiles.join(", ")}',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        setState(() {
          _selectedFiles = validFiles;
          _selectedFileNames = validFileNames;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _selectedFileNames.removeAt(index);
    });
  }

  Future<void> _submitAssignment() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one file to submit')),
      );
      return;
    }

    // Check if assignment is still open
    if (widget.assignment.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment deadline has passed')),
      );
      return;
    }

    // Check max attempts
    if (widget.assignment.maxAttempts > 0 &&
        _submissions.length >= widget.assignment.maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum number of attempts (${widget.assignment.maxAttempts}) reached',
          ),
        ),
      );
      return;
    }

    // Confirm submission
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: Text(
          'You are submitting ${_selectedFiles.length} file(s).\n'
          'This will be attempt ${_submissions.length + 1}${widget.assignment.maxAttempts > 0 ? ' of ${widget.assignment.maxAttempts}' : ''}.\n\n'
          'Continue?',
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
      final isLate = DateTime.now().isAfter(widget.assignment.deadline);

      final submission = await provider.submitAssignment(
        assignmentId: widget.assignment.id,
        studentId: widget.student.id,
        studentName: widget.student.fullName,
        files: _selectedFiles,
        isLate: isLate,
      );

      if (submission != null) {
        // Clear selected files
        setState(() {
          _selectedFiles.clear();
          _selectedFileNames.clear();
        });

        // Reload submissions
        await _loadSubmissions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to submit assignment'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _openAttachment(String url, String filename) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $filename')),
        );
      }
    }
  }

  Widget _buildAssignmentInfo() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (widget.assignment.isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'Not Started';
      statusIcon = Icons.schedule;
    } else if (widget.assignment.isOpen) {
      statusColor = Colors.green;
      statusText = 'Open';
      statusIcon = Icons.check_circle;
    } else if (widget.assignment.isInLatePeriod) {
      statusColor = Colors.orange;
      statusText = 'Late Period';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = 'Closed';
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Chip(
              avatar: Icon(statusIcon, color: Colors.white, size: 18),
              label: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor,
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Title
            Text(
              widget.assignment.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Instructor
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Instructor: ${widget.assignment.instructorName}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: AppTheme.spacingL),

            // Dates
            _buildInfoRow(
              Icons.play_arrow,
              'Starts',
              dateFormat.format(widget.assignment.startDate),
              Colors.blue,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow(
              Icons.event,
              'Due',
              dateFormat.format(widget.assignment.deadline),
              Colors.red,
            ),
            if (widget.assignment.allowLateSubmission &&
                widget.assignment.lateDeadline != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              _buildInfoRow(
                Icons.access_time,
                'Late Deadline',
                dateFormat.format(widget.assignment.lateDeadline!),
                Colors.orange,
              ),
            ],
            const Divider(height: AppTheme.spacingL),

            // Submission Info
            _buildInfoRow(
              Icons.repeat,
              'Max Attempts',
              widget.assignment.maxAttempts == 0
                  ? 'Unlimited'
                  : '${widget.assignment.maxAttempts}',
              Colors.purple,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow(
              Icons.insert_drive_file,
              'Max File Size',
              widget.assignment.formattedMaxFileSize,
              Colors.teal,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.attachment, size: 20, color: Colors.green),
                const SizedBox(width: AppTheme.spacingS),
                const Text(
                  'Allowed Formats: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.assignment.allowedFileFormats
                        .map((format) => Chip(
                              label: Text(
                                format.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Description & Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              widget.assignment.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorAttachments() {
    if (widget.assignment.attachments.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_file, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Instructor Attachments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...widget.assignment.attachments.map((attachment) {
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(attachment.filename),
                subtitle: Text(attachment.formattedSize),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _openAttachment(
                    attachment.url,
                    attachment.filename,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionInterface() {
    // Don't show submission interface if assignment is closed
    if (widget.assignment.isClosed) {
      return Card(
        elevation: 2,
        color: Colors.red[50],
        child: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 32),
              SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  'This assignment is closed and no longer accepting submissions.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if max attempts reached
    if (widget.assignment.maxAttempts > 0 &&
        _submissions.length >= widget.assignment.maxAttempts) {
      return Card(
        elevation: 2,
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 32),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  'You have reached the maximum number of attempts (${widget.assignment.maxAttempts}).',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Submit Your Work${_submissions.isNotEmpty ? ' (Attempt ${_submissions.length + 1})' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            // File picker button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select Files'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Selected files list
            if (_selectedFileNames.isNotEmpty) ...[
              const Text(
                'Selected Files:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ...List.generate(_selectedFileNames.length, (index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(_selectedFileNames[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed:
                          _isSubmitting ? null : () => _removeFile(index),
                    ),
                    dense: true,
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spacingM),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Assignment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionHistory() {
    if (_submissions.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
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
                  'No submissions yet',
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Submission History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._submissions.map((submission) {
              return _buildSubmissionCard(submission);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(AssignmentSubmissionModel submission) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    IconData statusIcon;

    if (submission.isGraded) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (submission.isLate) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('Attempt ${submission.attemptNumber}'),
        subtitle: Text(dateFormat.format(submission.submittedAt)),
        trailing: submission.isLate
            ? const Chip(
                label: Text('Late', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.orange,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submitted files
                const Text(
                  'Submitted Files:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spacingS),
                ...submission.files.map((file) {
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(file.filename),
                    subtitle: Text(file.formattedSize),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openAttachment(file.url, file.filename),
                    ),
                    dense: true,
                  );
                }),

                // Grade and feedback
                if (submission.isGraded) ...[
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.grade, color: Colors.amber),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Grade: ${submission.grade}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (submission.feedback != null &&
                      submission.feedback!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    const Text(
                      'Feedback:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(submission.feedback!),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Graded at: ${dateFormat.format(submission.gradedAt!)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ] else ...[
                  const Divider(),
                  const Row(
                    children: [
                      Icon(Icons.pending, color: Colors.blue),
                      SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Awaiting grading',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submission'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentInfo(),
            const SizedBox(height: AppTheme.spacingL),
            _buildDescription(),
            const SizedBox(height: AppTheme.spacingL),
            _buildInstructorAttachments(),
            const SizedBox(height: AppTheme.spacingL),
            _buildSubmissionInterface(),
            const SizedBox(height: AppTheme.spacingL),
            _buildSubmissionHistory(),
            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }
}
