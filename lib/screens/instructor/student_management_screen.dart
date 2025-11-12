import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/student_provider.dart';
import '../../services/csv_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/student_form_dialog.dart';
import '../../widgets/csv_import_dialog.dart';
import '../../config/app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String _searchQuery = '';
  String _sortBy = 'fullName';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    final studentProvider = context.read<StudentProvider>();
    await studentProvider.loadStudents();
  }

  Future<void> _createStudent() async {
    final studentProvider = context.read<StudentProvider>();
    final authService = context.read<AuthService>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StudentFormDialog(
        checkUsernameExists: (username, excludeId) =>
            authService.checkUsernameExists(username),
      ),
    );

    if (result != null && mounted) {
      final student = await studentProvider.createStudent(
        username: result['username'],
        fullName: result['fullName'],
        email: result['email'],
        studentId: result['studentId'],
      );

      if (mounted) {
        if (student != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Student "${student.fullName}" created successfully.\nDefault password: ${student.username}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                studentProvider.error ?? 'Failed to create student',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editStudent(UserModel student) async {
    final studentProvider = context.read<StudentProvider>();
    final authService = context.read<AuthService>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StudentFormDialog(
        student: student,
        checkUsernameExists: (username, excludeId) =>
            authService.checkUsernameExists(username),
      ),
    );

    if (result != null && mounted) {
      final updatedStudent = student.copyWith(
        fullName: result['fullName'],
        email: result['email'],
        studentId: result['studentId'],
      );

      final success = await studentProvider.updateStudent(updatedStudent);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Student "${updatedStudent.fullName}" updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                studentProvider.error ?? 'Failed to update student',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteStudent(UserModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete "${student.fullName}"?\n\nThis will:\n• Remove the student account\n• Delete all associated data\n• Remove from all groups\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final studentProvider = context.read<StudentProvider>();
      final success = await studentProvider.deleteStudent(student.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student "${student.fullName}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                studentProvider.error ?? 'Failed to delete student',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _importFromCsv() async {
    final studentProvider = context.read<StudentProvider>();
    final csvService = context.read<CsvService>();

    try {
      // Step 1: Pick and parse CSV file
      final data = await csvService.pickAndParseCsv(
        expectedHeaders: const ['studentId', 'fullName', 'email', 'password'],
      );

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found in CSV file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Step 2: Show dialog with preview
      if (!mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CsvImportDialog(
          title: 'Import Students',
          headers: const ['Student ID', 'Full Name', 'Email', 'Password'],
          data: data,
          previewBuilder: (row) {
            return {
              'Student ID': row['studentId'] ?? '',
              'Full Name': row['fullName'] ?? '',
              'Email': row['email'] ?? '',
              'Password': '********',
            };
          },
          onImport: () async {
            return await studentProvider.importStudentsFromCsv(data);
          },
        ),
      );

    if (result != null && mounted) {
      final success = result['success'] ?? 0;
      final failed = result['failed'] ?? 0;
      final exists = result['alreadyExists'] ?? 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ Successfully imported: $success'),
              if (exists > 0) Text('⊘ Already exists: $exists'),
              if (failed > 0) Text('✗ Failed: $failed'),
              const SizedBox(height: 16),
              if (success > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Default passwords are set to usernames',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv() async {
    final studentProvider = context.read<StudentProvider>();
    final csvService = context.read<CsvService>();

    if (studentProvider.students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final csvData = studentProvider.students.map((student) {
        return {
          'username': student.username,
          'fullName': student.fullName,
          'email': student.email,
          'studentId': student.studentId ?? '',
          'created': DateFormat('yyyy-MM-dd').format(student.createdAt),
        };
      }).toList();

      final fileName =
          'students_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      await csvService.exportToCsv(csvData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${studentProvider.students.length} students to $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import from CSV',
            onPressed: _importFromCsv,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV',
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Sort Bar
          _buildSearchBar(),

          // Students List
          Expanded(child: _buildStudentsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('New Student'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          context.read<StudentProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                context.read<StudentProvider>().searchStudents(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
              context.read<StudentProvider>().sortStudents(
                    _sortBy,
                    ascending: _sortAscending,
                  );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'fullName', child: Text('Sort by Name')),
              const PopupMenuItem(
                  value: 'username', child: Text('Sort by Username')),
              const PopupMenuItem(value: 'email', child: Text('Sort by Email')),
              const PopupMenuItem(
                  value: 'studentId', child: Text('Sort by Student ID')),
              const PopupMenuItem(
                  value: 'created', child: Text('Sort by Created Date')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        if (studentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (studentProvider.students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No students found'
                      : 'No students match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _createStudent,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add First Student'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => studentProvider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: studentProvider.students.length,
            itemBuilder: (context, index) {
              final student = studentProvider.students[index];
              return _buildStudentCard(student);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(UserModel student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            student.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  student.username,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    student.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (student.studentId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.confirmation_number,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${student.studentId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _editStudent(student);
            } else if (value == 'delete') {
              _deleteStudent(student);
            }
          },
        ),
        onTap: () => _editStudent(student),
      ),
    );
  }
}
