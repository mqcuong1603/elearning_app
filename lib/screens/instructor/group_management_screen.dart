import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/group_model.dart';
import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../models/semester_model.dart';
import '../../widgets/group_form_dialog.dart';
import '../../services/csv_service.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({Key? key}) : super(key: key);

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
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
    final groupProvider = context.read<GroupProvider>();
    final courseProvider = context.read<CourseProvider>();
    final studentProvider = context.read<StudentProvider>();
    final semesterProvider = context.read<SemesterProvider>();

    await Future.wait([
      groupProvider.loadGroups(),
      courseProvider.loadCourses(),
      studentProvider.loadStudents(),
      semesterProvider.loadSemesters(),
    ]);

    // Set selected semester to current semester by default
    if (mounted && _selectedSemesterId == null) {
      setState(() {
        _selectedSemesterId = semesterProvider.currentSemester?.id;
      });
    }
  }

  void _showAddGroupDialog() async {
    final courseProvider = context.read<CourseProvider>();
    final semesterProvider = context.read<SemesterProvider>();

    // Filter courses by selected semester
    final courses = _selectedSemesterId != null
        ? courseProvider.courses
            .where((course) => course.semesterId == _selectedSemesterId)
            .toList()
        : courseProvider.courses;

    if (courses.isEmpty) {
      final semesterName = _selectedSemesterId != null
          ? semesterProvider.getSemesterById(_selectedSemesterId!)?.name ?? 'this semester'
          : 'any semester';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No courses found in $semesterName. Please create a course first.'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GroupFormDialog(
        courses: courses,
        preSelectedCourseId: _selectedCourseId,
      ),
    );

    if (result != null && mounted) {
      final success = await context.read<GroupProvider>().createGroup(
            name: result['name'],
            courseId: result['courseId'],
          );

      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      } else if (mounted) {
        final error = context.read<GroupProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create group')),
        );
      }
    }
  }

  void _showEditGroupDialog(GroupModel group) async {
    final courseProvider = context.read<CourseProvider>();

    // Filter courses by selected semester
    final courses = _selectedSemesterId != null
        ? courseProvider.courses
            .where((course) => course.semesterId == _selectedSemesterId)
            .toList()
        : courseProvider.courses;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GroupFormDialog(
        group: group,
        courses: courses,
      ),
    );

    if (result != null && mounted) {
      final updatedGroup = group.copyWith(
        name: result['name'],
      );

      final success =
          await context.read<GroupProvider>().updateGroup(updatedGroup);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      } else if (mounted) {
        final error = context.read<GroupProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to update group')),
        );
      }
    }
  }

  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\n'
          'Note: Groups with students cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteGroup(group.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(String id) async {
    final success = await context.read<GroupProvider>().deleteGroup(id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully')),
      );
    } else if (mounted) {
      final error = context.read<GroupProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to delete group')),
      );
    }
  }

  void _showManageStudentsDialog(GroupModel group) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    final course = courseProvider.courses.firstWhere(
      (c) => c.id == group.courseId,
      orElse: () => CourseModel(
        id: '',
        code: '',
        name: 'Unknown',
        sessions: 10,
        semesterId: '',
        instructorId: '',
        instructorName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => _ManageStudentsDialog(
        group: group,
        course: course,
        allStudents: studentProvider.students,
        onAddStudent: (studentId) async {
          final success = await context.read<GroupProvider>().addStudentToGroup(
                groupId: group.id,
                studentId: studentId,
              );
          if (success) {
            return null;
          } else {
            return context.read<GroupProvider>().error ?? 'Failed to add student';
          }
        },
        onRemoveStudent: (studentId) async {
          final success = await context.read<GroupProvider>().removeStudentFromGroup(
                groupId: group.id,
                studentId: studentId,
              );
          if (success) {
            return null;
          } else {
            return context.read<GroupProvider>().error ?? 'Failed to remove student';
          }
        },
      ),
    );
  }

  Future<void> _importGroupsFromCsv() async {
    try {
      final csvService = CsvService();
      final result = await csvService.pickAndParseCsv(
        expectedHeaders: AppConstants.csvHeadersGroups,
      );

      if (!mounted) return;

      final importResult = await context.read<GroupProvider>().importGroupsFromCsv(result);

      if (importResult != null && mounted) {
        _showImportResultDialog(importResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _importStudentGroupAssignments() async {
    try {
      final csvService = CsvService();
      final result = await csvService.pickAndParseCsv(
        expectedHeaders: AppConstants.csvHeadersStudentGroups,
      );

      if (!mounted) return;

      final importResult = await context
          .read<GroupProvider>()
          .importStudentGroupAssignments(result);

      if (importResult != null && mounted) {
        _showImportResultDialog(importResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showImportResultDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${results['total']}'),
            Text('Success: ${results['success']}',
                style: const TextStyle(color: Colors.green)),
            Text('Already Exists: ${results['alreadyExists']}',
                style: const TextStyle(color: Colors.orange)),
            Text('Failed: ${results['failed']}',
                style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCourseFilter() {
    final courseProvider = context.read<CourseProvider>();

    // Filter courses by selected semester
    final courses = _selectedSemesterId != null
        ? courseProvider.courses
            .where((course) => course.semesterId == _selectedSemesterId)
            .toList()
        : courseProvider.courses;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Courses'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedCourseId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                    context.read<GroupProvider>().clearCourseFilter();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ...courses.map((course) {
                return ListTile(
                  title: Text('${course.code} - ${course.name}'),
                  leading: Radio<String?>(
                    value: course.id,
                    groupValue: _selectedCourseId,
                    onChanged: (value) {
                      setState(() {
                        _selectedCourseId = value;
                      });
                      context.read<GroupProvider>().filterByCourse(value);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }).toList(),
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
        title: const Text('Group Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import_groups':
                  _importGroupsFromCsv();
                  break;
                case 'import_assignments':
                  _importStudentGroupAssignments();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_groups',
                child: Text('Import Groups (CSV)'),
              ),
              const PopupMenuItem(
                value: 'import_assignments',
                child: Text('Import Student-Group Assignments (CSV)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Semester Selector
          Consumer<SemesterProvider>(
            builder: (context, semesterProvider, child) {
              if (semesterProvider.semesters.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: const Text(
                    'No semesters available. Please create a semester first.',
                    style: TextStyle(color: Colors.orange),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingM,
                  AppTheme.spacingM,
                  AppTheme.spacingM,
                  0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    const Text('Semester:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSemesterId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: semesterProvider.semesters.map((semester) {
                          return DropdownMenuItem(
                            value: semester.id,
                            child: Text(
                              '${semester.name} (${semester.code})${semester.isCurrent ? ' - Current' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSemesterId = value;
                            _selectedCourseId = null; // Clear course filter when semester changes
                          });
                          context.read<GroupProvider>().clearCourseFilter();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search groups...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<GroupProvider>().clearSearch();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      context.read<GroupProvider>().searchGroups(value);
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showCourseFilter,
                  tooltip: 'Filter by course',
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                    context
                        .read<GroupProvider>()
                        .sortGroups(_sortBy, ascending: _sortAscending);
                  },
                  tooltip: 'Sort',
                ),
              ],
            ),
          ),

          // Groups List
          Expanded(
            child: Consumer2<GroupProvider, CourseProvider>(
              builder: (context, groupProvider, courseProvider, child) {
                if (groupProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (groupProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${groupProvider.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter groups by selected semester (via course relationship)
                final filteredGroups = _selectedSemesterId != null
                    ? groupProvider.groups.where((group) {
                        final course = courseProvider.courses.firstWhere(
                          (c) => c.id == group.courseId,
                          orElse: () => CourseModel(
                            id: '',
                            code: '',
                            name: '',
                            sessions: 10,
                            semesterId: '',
                            instructorId: '',
                            instructorName: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        return course.semesterId == _selectedSemesterId;
                      }).toList()
                    : groupProvider.groups;

                if (filteredGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No groups found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          _selectedSemesterId != null
                              ? 'No groups in this semester. Tap the + button to create one.'
                              : 'Tap the + button to create a group',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => groupProvider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      return _GroupCard(
                        group: group,
                        onEdit: () => _showEditGroupDialog(group),
                        onDelete: () => _confirmDeleteGroup(group),
                        onManageStudents: () => _showManageStudentsDialog(group),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageStudents;

  const _GroupCard({
    Key? key,
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onManageStudents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final course = courseProvider.courses.firstWhere(
      (c) => c.id == group.courseId,
      orElse: () => CourseModel(
        id: '',
        code: '',
        name: 'Unknown Course',
        sessions: 10,
        semesterId: '',
        instructorId: '',
        instructorName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        '${course.code} - ${course.name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
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
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: AppTheme.spacingS),
                Text('${group.studentCount} students'),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onManageStudents,
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Manage Students'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageStudentsDialog extends StatefulWidget {
  final GroupModel group;
  final CourseModel course;
  final List<UserModel> allStudents;
  final Future<String?> Function(String studentId) onAddStudent;
  final Future<String?> Function(String studentId) onRemoveStudent;

  const _ManageStudentsDialog({
    Key? key,
    required this.group,
    required this.course,
    required this.allStudents,
    required this.onAddStudent,
    required this.onRemoveStudent,
  }) : super(key: key);

  @override
  State<_ManageStudentsDialog> createState() => _ManageStudentsDialogState();
}

class _ManageStudentsDialogState extends State<_ManageStudentsDialog> {
  late List<String> _currentStudentIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStudentIds = List.from(widget.group.studentIds);
  }

  Future<void> _addStudent(String studentId) async {
    setState(() => _isLoading = true);
    final error = await widget.onAddStudent(studentId);
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() {
        _currentStudentIds.add(studentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _removeStudent(String studentId) async {
    setState(() => _isLoading = true);
    final error = await widget.onRemoveStudent(studentId);
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() {
        _currentStudentIds.remove(studentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsInGroup = widget.allStudents
        .where((s) => _currentStudentIds.contains(s.id))
        .toList();
    final studentsNotInGroup = widget.allStudents
        .where((s) => !_currentStudentIds.contains(s.id))
        .toList();

    return AlertDialog(
      title: Text('Manage Students - ${widget.group.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Course: ${widget.course.code} - ${widget.course.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'In Group'),
                        Tab(text: 'Available'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Students in group
                          studentsInGroup.isEmpty
                              ? const Center(
                                  child: Text('No students in this group'))
                              : ListView.builder(
                                  itemCount: studentsInGroup.length,
                                  itemBuilder: (context, index) {
                                    final student = studentsInGroup[index];
                                    return ListTile(
                                      title: Text(student.fullName),
                                      subtitle: Text(student.email),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: _isLoading
                                            ? null
                                            : () => _removeStudent(student.id),
                                      ),
                                    );
                                  },
                                ),
                          // Available students
                          studentsNotInGroup.isEmpty
                              ? const Center(
                                  child: Text('No available students'))
                              : ListView.builder(
                                  itemCount: studentsNotInGroup.length,
                                  itemBuilder: (context, index) {
                                    final student = studentsNotInGroup[index];
                                    return ListTile(
                                      title: Text(student.fullName),
                                      subtitle: Text(student.email),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.add_circle,
                                            color: Colors.green),
                                        onPressed: _isLoading
                                            ? null
                                            : () => _addStudent(student.id),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
