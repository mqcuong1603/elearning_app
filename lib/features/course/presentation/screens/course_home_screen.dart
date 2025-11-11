import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/enrolled_courses_provider.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';

/// Student Homepage - Course Cards View
/// PDF Requirement: "For students, the homepage displays enrolled courses as cards,
/// each featuring a cover image, course name, instructor name, and other relevant details"
class CourseHomeScreen extends ConsumerWidget {
  const CourseHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentSemesterAsync = ref.watch(currentSemesterProvider);
    final selectedSemester = ref.watch(selectedSemesterProvider);
    // Use selected semester if available, otherwise use current semester
    final semesterToUse = selectedSemester ?? currentSemesterAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          // Semester Switcher
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Switch Semester',
            onPressed: () {
              _showSemesterSwitcher(context, ref);
            },
          ),
          // Profile Icon
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                authState.user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
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
                  Column(
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
                        semesterToUse.code,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (semesterToUse.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Past (Read-only)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Courses List
          Expanded(
            child: semesterToUse == null
                ? const Center(child: Text('No semester selected'))
                : _buildCoursesList(context, ref, semesterToUse.id),
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
    final coursesAsync = ref.watch(enrolledCoursesProvider(semesterId));

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No courses enrolled yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(enrolledCoursesProvider(semesterId));
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return _CourseCard(course: courses[index]);
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
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(enrolledCoursesProvider(semesterId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
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
/// Displays course information with cover image
class _CourseCard extends StatelessWidget {
  final CourseEntity course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/courses/${course.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getCourseColors(course.code),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Course Code Watermark
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Course Icon
                    Center(
                      child: Icon(
                        Icons.book,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Course Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Course Name
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

                    // Additional Info
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Instructor', // TODO: Get actual instructor name
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.sessions} sessions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
