import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';
import '../../models/semester_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../services/csv_service.dart';
import '../../widgets/course_form_dialog.dart';
import '../../widgets/csv_import_dialog.dart';
import '../../config/app_theme.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  SemesterModel? _selectedSemester;
  String _searchQuery = '';
  String _sortBy = 'code';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final semesterProvider = context.read<SemesterProvider>();

    // Load semesters if not already loaded
    if (semesterProvider.semesters.isEmpty) {
      await semesterProvider.loadSemesters();
    }

    // Set current semester or first semester
    if (semesterProvider.currentSemester != null) {
      setState(() {
        _selectedSemester = semesterProvider.currentSemester;
      });
      _loadCourses();
    } else if (semesterProvider.semesters.isNotEmpty) {
      setState(() {
        _selectedSemester = semesterProvider.semesters.first;
      });
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    if (_selectedSemester == null) return;

    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadCoursesBySemester(_selectedSemester!.id);
  }

  Future<void> _createCourse() async {
    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a semester first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final courseProvider = context.read<CourseProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CourseFormDialog(
        semester: _selectedSemester!,
        checkCodeExists: (code, excludeId) =>
            courseProvider.courseCodeExistsInSemester(
          code,
          _selectedSemester!.id,
          excludeId: excludeId,
        ),
      ),
    );

    if (result != null && mounted) {
      final course = await courseProvider.createCourse(
        code: result['code'],
        name: result['name'],
        semesterId: _selectedSemester!.id,
        sessions: result['sessions'],
        description: result['description'],
      );

      if (mounted) {
        if (course != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course "${course.code}" created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                courseProvider.error ?? 'Failed to create course',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCourse(CourseModel course) async {
    final courseProvider = context.read<CourseProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CourseFormDialog(
        course: course,
        semester: _selectedSemester!,
        checkCodeExists: (code, excludeId) =>
            courseProvider.courseCodeExistsInSemester(
          code,
          _selectedSemester!.id,
          excludeId: excludeId,
        ),
      ),
    );

    if (result != null && mounted) {
      final updatedCourse = course.copyWith(
        code: result['code'],
        name: result['name'],
        description: result['description'],
        sessions: result['sessions'],
      );

      final success = await courseProvider.updateCourse(updatedCourse);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course "${updatedCourse.code}" updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                courseProvider.error ?? 'Failed to update course',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete course "${course.code} - ${course.name}"?\n\nThis action cannot be undone.',
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
      final courseProvider = context.read<CourseProvider>();
      final success = await courseProvider.deleteCourse(
        course.id,
        course.semesterId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course "${course.code}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                courseProvider.error ?? 'Failed to delete course',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _importFromCsv() async {
    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a semester first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final courseProvider = context.read<CourseProvider>();
    final csvService = context.read<CsvService>();

    try {
      // Step 1: Pick and parse CSV file
      final data = await csvService.pickAndParseCsv(
        expectedHeaders: const ['code', 'name', 'sessions', 'semesterId'],
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
          title: 'Import Courses',
          headers: const ['Code', 'Name', 'Sessions', 'Semester ID'],
          data: data,
          previewBuilder: (row) {
            return {
              'Code': row['code'] ?? '',
              'Name': row['name'] ?? '',
              'Sessions': row['sessions'] ?? '',
              'Semester ID': row['semesterId'] ?? '',
            };
          },
          onImport: () async {
            final result = await courseProvider.importCoursesFromCsv(
              data,
              _selectedSemester!.id,
            );
            return result ?? {'success': 0, 'failed': 0, 'alreadyExists': 0};
          },
        ),
      );

      if (result != null && mounted) {
        final success = result['success'] ?? 0;
        final failed = result['failed'] ?? 0;
        final exists = result['alreadyExists'] ?? 0;

        // Wait for the previous dialog to fully close before showing results
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        await showDialog(
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
    final courseProvider = context.read<CourseProvider>();
    final csvService = context.read<CsvService>();

    if (courseProvider.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No courses to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final csvData = courseProvider.courses.map((course) {
        return {
          'code': course.code,
          'name': course.name,
          'sessions': course.sessions.toString(),
          'description': course.description ?? '',
          'instructor': course.instructorName,
          'created': DateFormat('yyyy-MM-dd').format(course.createdAt),
        };
      }).toList();

      final fileName = 'courses_${_selectedSemester?.code ?? 'all'}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      await csvService.exportToCsv(csvData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${courseProvider.courses.length} courses to $fileName'),
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
        title: const Text('Course Management'),
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
          // Semester Selector
          _buildSemesterSelector(),

          // Search and Sort Bar
          _buildSearchBar(),

          // Courses List
          Expanded(child: _buildCoursesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourse,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Consumer<SemesterProvider>(
      builder: (context, semesterProvider, child) {
        if (semesterProvider.semesters.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text('No semesters available. Create a semester first.'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<SemesterModel>(
                  value: _selectedSemester,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Select Semester'),
                  items: semesterProvider.semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Row(
                        children: [
                          Text(semester.displayText),
                          if (semester.isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (semester) {
                    if (semester != null) {
                      setState(() {
                        _selectedSemester = semester;
                      });
                      _loadCourses();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          context.read<CourseProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                context.read<CourseProvider>().searchCourses(value);
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
              context.read<CourseProvider>().sortCourses(
                    _sortBy,
                    ascending: _sortAscending,
                  );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'code', child: Text('Sort by Code')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'sessions', child: Text('Sort by Sessions')),
              const PopupMenuItem(value: 'created', child: Text('Sort by Created Date')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        if (_selectedSemester == null) {
          return const Center(
            child: Text('Please select a semester'),
          );
        }

        if (courseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courseProvider.courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No courses found in this semester'
                      : 'No courses match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _createCourse,
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Course'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => courseProvider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: courseProvider.courses.length,
            itemBuilder: (context, index) {
              final course = courseProvider.courses[index];
              return _buildCourseCard(course);
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            course.code.substring(0, 2).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          course.code,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.name),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${course.sessions} sessions',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    course.instructorName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
              _editCourse(course);
            } else if (value == 'delete') {
              _deleteCourse(course);
            }
          },
        ),
        onTap: () => _editCourse(course),
      ),
    );
  }
}
