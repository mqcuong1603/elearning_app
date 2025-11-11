import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';
import 'package:elearning_app/features/course/presentation/providers/course_list_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';

/// Course List Screen
/// Admin/Instructor manages courses within a semester
/// PDF Requirement: Course includes code, name, number of sessions (10 or 15)
class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSemesterAsync = ref.watch(currentSemesterProvider);
    final selectedSemester = ref.watch(selectedSemesterProvider);

    // Use selected semester if available, otherwise use current semester
    final semesterToUse = selectedSemester ?? currentSemesterAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        actions: [
          // CSV Import Button
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import from CSV',
            onPressed: semesterToUse != null
                ? () => context.push('/courses/import?semesterId=${semesterToUse.id}')
                : null,
          ),
          // Add New Course
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Course',
            onPressed: semesterToUse != null
                ? () => context.push('/courses/new?semesterId=${semesterToUse.id}')
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Semester Info Banner
          if (semesterToUse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          semesterToUse.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Code: ${semesterToUse.code}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Semester switcher button
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Switch Semester',
                    onPressed: () => _showSemesterSwitcher(context, ref),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[900]),
                  const SizedBox(width: 8),
                  const Text('No semester selected. Please create a semester first.'),
                ],
              ),
            ),

          // Search Bar
          if (semesterToUse != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses by name or code...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

          // Courses List
          Expanded(
            child: semesterToUse == null
                ? _buildNoSemesterState(context)
                : _buildCoursesList(context, ref, semesterToUse.id),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSemesterState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Semester',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please create a semester first',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/semesters'),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Manage Semesters'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(
    BuildContext context,
    WidgetRef ref,
    String semesterId,
  ) {
    final coursesAsync = ref.watch(coursesBySemesterProvider(semesterId));

    return coursesAsync.when(
      data: (courses) {
        // Filter by search query
        final filteredCourses = _searchQuery.isEmpty
            ? courses
            : courses
                .where((course) =>
                    course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    course.code.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        if (filteredCourses.isEmpty) {
          return _buildEmptyState(context, courses.isEmpty);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coursesBySemesterProvider(semesterId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCourses.length,
            itemBuilder: (context, index) {
              return _CourseCard(
                course: filteredCourses[index],
                onTap: () => context.push('/courses/${filteredCourses[index].id}/edit'),
                onDelete: () => _deleteCourse(context, ref, filteredCourses[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading courses',
              style: TextStyle(color: Colors.red[700], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(coursesBySemesterProvider(semesterId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearchEmpty) {
    if (!isSearchEmpty) {
      // Has courses but search returned nothing
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // No courses at all
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Courses Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              final semester = ref.read(selectedSemesterProvider) ?? ref.read(currentSemesterProvider).value;
              if (semester != null) {
                context.push('/courses/new?semesterId=${semester.id}');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Course'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(
    BuildContext context,
    WidgetRef ref,
    CourseEntity course,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.name}"?\n\n'
          'This will also delete all groups, assignments, quizzes, and materials in this course. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final repository = ref.read(courseRepositoryProvider);
      final success = await repository.deleteCourse(course.id);

      if (!context.mounted) return;

      if (success) {
        ref.invalidate(coursesBySemesterProvider(course.semesterId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSemesterSwitcher(BuildContext context, WidgetRef ref) {
    // TODO: Implement semester switcher dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semester switcher coming soon'),
      ),
    );
  }
}

/// Course Card Widget
class _CourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Course Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getCourseColors(course.code),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Course Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${course.code}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sessions Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '${course.sessions} sessions',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              if (course.description.isNotEmpty) ...[
                Text(
                  course.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Stats Row
              Row(
                children: [
                  if (course.groupCount != null) ...[
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${course.groupCount} groups',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (course.studentCount != null) ...[
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${course.studentCount} students',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generate course-specific colors based on course code
  List<Color> _getCourseColors(String courseCode) {
    final hash = courseCode.hashCode;
    final colors = [
      [Colors.blue[700]!, Colors.blue[400]!],
      [Colors.purple[700]!, Colors.purple[400]!],
      [Colors.green[700]!, Colors.green[400]!],
      [Colors.orange[700]!, Colors.orange[400]!],
      [Colors.teal[700]!, Colors.teal[400]!],
      [Colors.indigo[700]!, Colors.indigo[400]!],
    ];
    return colors[hash.abs() % colors.length];
  }
}
