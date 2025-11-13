import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/user_model.dart';
import '../../providers/assignment_provider.dart';
import '../../services/group_service.dart';
import '../../services/student_service.dart';
import '../../config/app_theme.dart';
import 'assignment_grading_screen.dart';

/// Instructor Assignment Tracking Dashboard
/// Real-time tracking of submissions, grades, and student status
class AssignmentTrackingScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final String courseId;

  const AssignmentTrackingScreen({
    super.key,
    required this.assignment,
    required this.courseId,
  });

  @override
  State<AssignmentTrackingScreen> createState() =>
      _AssignmentTrackingScreenState();
}

class _AssignmentTrackingScreenState extends State<AssignmentTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // name, status, grade, submitted_at
  bool _sortAscending = true;
  String _filterStatus = 'all'; // all, submitted, not_submitted, graded, late
  List<Map<String, dynamic>> _studentStatus = [];
  List<Map<String, dynamic>> _filteredStatus = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame to avoid notifying listeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assignmentProvider =
          Provider.of<AssignmentProvider>(context, listen: false);
      final groupService = context.read<GroupService>();
      final studentService = context.read<StudentService>();

      // Get all groups in the course
      final groups = await groupService.getGroupsByCourse(widget.courseId);

      // Collect all unique student IDs from all groups
      final Set<String> studentIds = {};
      for (var group in groups) {
        studentIds.addAll(group.studentIds);
      }

      // Load student details for all student IDs
      final students = <UserModel>[];
      for (var studentId in studentIds) {
        final student = await studentService.getStudentById(studentId);
        if (student != null) {
          students.add(student);
        }
      }

      // Load submission status
      await assignmentProvider.loadStudentSubmissionStatus(
        assignmentId: widget.assignment.id,
        students: students,
      );

      // Load stats
      await assignmentProvider.loadSubmissionStats(
        assignmentId: widget.assignment.id,
        students: students,
      );

      setState(() {
        _studentStatus = assignmentProvider.studentSubmissionStatus;
        _stats = assignmentProvider.submissionStats;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_studentStatus);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        final name = (student['studentName'] as String).toLowerCase();
        final email = (student['studentEmail'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((student) {
        switch (_filterStatus) {
          case 'submitted':
            return student['hasSubmitted'] == true;
          case 'not_submitted':
            return student['hasSubmitted'] == false;
          case 'graded':
            return student['grade'] != null;
          case 'late':
            return student['isLate'] == true;
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = (a['studentName'] as String)
              .compareTo(b['studentName'] as String);
          break;
        case 'status':
          comparison = (a['status'] as String).compareTo(b['status'] as String);
          break;
        case 'grade':
          final gradeA = a['grade'] as double?;
          final gradeB = b['grade'] as double?;
          if (gradeA == null && gradeB == null) {
            comparison = 0;
          } else if (gradeA == null) {
            comparison = 1;
          } else if (gradeB == null) {
            comparison = -1;
          } else {
            comparison = gradeA.compareTo(gradeB);
          }
          break;
        case 'submitted_at':
          final dateA = a['submittedAt'] as DateTime?;
          final dateB = b['submittedAt'] as DateTime?;
          if (dateA == null && dateB == null) {
            comparison = 0;
          } else if (dateA == null) {
            comparison = 1;
          } else if (dateB == null) {
            comparison = -1;
          } else {
            comparison = dateA.compareTo(dateB);
          }
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredStatus = filtered;
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final assignmentProvider =
          Provider.of<AssignmentProvider>(context, listen: false);
      final groupService = context.read<GroupService>();
      final studentService = context.read<StudentService>();

      // Get all groups in the course
      final groups = await groupService.getGroupsByCourse(widget.courseId);

      // Collect all unique student IDs from all groups
      final Set<String> studentIds = {};
      for (var group in groups) {
        studentIds.addAll(group.studentIds);
      }

      // Load student details for all student IDs
      final students = <UserModel>[];
      for (var studentId in studentIds) {
        final student = await studentService.getStudentById(studentId);
        if (student != null) {
          students.add(student);
        }
      }

      final csvString = await assignmentProvider.exportGradesToCSV(
        assignmentId: widget.assignment.id,
        assignmentTitle: widget.assignment.title,
        students: students,
      );

      if (csvString == null) {
        throw Exception('Failed to generate CSV');
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename =
          'assignment_${widget.assignment.id}_grades_$timestamp.csv';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully to $filename'),
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
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _applyFilters();
    });
  }

  void _onFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        _filterStatus = filter;
        _applyFilters();
      });
    }
  }

  Widget _buildStatsCards() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: AppTheme.spacingM,
      crossAxisSpacing: AppTheme.spacingM,
      children: [
        _buildStatCard(
          'Total Students',
          _stats!['totalStudents'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Submitted',
          _stats!['submitted'].toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Not Submitted',
          _stats!['notSubmitted'].toString(),
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Late Submissions',
          _stats!['lateSubmissions'].toString(),
          Icons.warning,
          Colors.red,
        ),
        _buildStatCard(
          'Graded',
          _stats!['graded'].toString(),
          Icons.grade,
          Colors.purple,
        ),
        _buildStatCard(
          'Not Graded',
          _stats!['notGraded'].toString(),
          Icons.pending_actions,
          Colors.grey,
        ),
        _buildStatCard(
          'Multiple Attempts',
          _stats!['multipleAttempts'].toString(),
          Icons.repeat,
          Colors.teal,
        ),
        _buildStatCard(
          'Average Grade',
          _stats!['averageGrade'] != null
              ? _stats!['averageGrade'].toStringAsFixed(1)
              : 'N/A',
          Icons.analytics,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spacingXS),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Filters and sorting
            Row(
              children: [
                // Status filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                          value: 'submitted', child: Text('Submitted')),
                      DropdownMenuItem(
                          value: 'not_submitted', child: Text('Not Submitted')),
                      DropdownMenuItem(value: 'graded', child: Text('Graded')),
                      DropdownMenuItem(value: 'late', child: Text('Late')),
                    ],
                    onChanged: _onFilterChanged,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),

                // Sort by
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'status', child: Text('Status')),
                      DropdownMenuItem(value: 'grade', child: Text('Grade')),
                      DropdownMenuItem(
                          value: 'submitted_at',
                          child: Text('Submission Date')),
                    ],
                    onChanged: (value) {
                      if (value != null) _onSortChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),

                // Sort direction
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _applyFilters();
                    });
                  },
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),

                // Export CSV button
                ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredStatus.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No students found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Attempts')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Submitted At')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _filteredStatus.map((student) {
            return _buildStudentRow(student);
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildStudentRow(Map<String, dynamic> student) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final hasSubmitted = student['hasSubmitted'] as bool;
    final isLate = student['isLate'] as bool;
    final attemptCount = student['attemptCount'] as int;
    final grade = student['grade'] as double?;
    final submittedAt = student['submittedAt'] as DateTime?;
    final status = student['status'] as String;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'not_submitted':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'graded':
        statusColor = Colors.green;
        statusIcon = Icons.grade;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return DataRow(
      cells: [
        // Student Name
        DataCell(
          Row(
            children: [
              if (isLate)
                const Icon(Icons.warning, color: Colors.red, size: 16),
              if (isLate) const SizedBox(width: 4),
              Text(student['studentName'] as String),
            ],
          ),
        ),

        // Email
        DataCell(Text(student['studentEmail'] as String)),

        // Status
        DataCell(
          Chip(
            avatar: Icon(statusIcon, color: Colors.white, size: 16),
            label: Text(
              _formatStatus(status),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: statusColor,
            visualDensity: VisualDensity.compact,
          ),
        ),

        // Attempts
        DataCell(
          Text(
            attemptCount > 0 ? '$attemptCount' : '-',
            style: TextStyle(
              fontWeight:
                  attemptCount > 1 ? FontWeight.bold : FontWeight.normal,
              color: attemptCount > 1 ? Colors.blue : null,
            ),
          ),
        ),

        // Grade
        DataCell(
          grade != null
              ? Text(
                  grade.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : const Text('-'),
        ),

        // Submitted At
        DataCell(
          submittedAt != null
              ? Text(dateFormat.format(submittedAt))
              : const Text('-'),
        ),

        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSubmitted)
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Submission',
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AssignmentGradingScreen(
                          assignment: widget.assignment,
                          studentId: student['studentId'] as String,
                          studentName: student['studentName'] as String,
                        ),
                      ),
                    );

                    // Refresh data if grading was successful
                    if (result == true) {
                      _loadData();
                    }
                  },
                ),
              if (!hasSubmitted) const Icon(Icons.remove, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'not_submitted':
        return 'Not Submitted';
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track: ${widget.assignment.title}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              _buildStatsCards(),
              const SizedBox(height: AppTheme.spacingL),

              // Search and filters
              _buildSearchAndFilters(),
              const SizedBox(height: AppTheme.spacingL),

              // Results count
              Text(
                'Showing ${_filteredStatus.length} of ${_studentStatus.length} students',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Student table
              _buildStudentTable(),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }
}
