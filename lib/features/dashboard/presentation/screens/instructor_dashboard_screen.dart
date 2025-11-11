import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_list_provider.dart';

/// Instructor Dashboard
/// PDF Requirement: "For the instructor, the homepage transforms into a dashboard
/// summarizing key metrics for the current semester: number of courses, groups,
/// and students managed; number of assignments and quizzes; and progress charts"
class InstructorDashboardScreen extends ConsumerWidget {
  const InstructorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentSemesterAsync = ref.watch(currentSemesterProvider);
    final selectedSemester = ref.watch(selectedSemesterProvider);

    final semesterToUse = selectedSemester ?? currentSemesterAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                authState.user?.displayName.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: semesterToUse == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentSemesterProvider);
                ref.invalidate(coursesBySemesterProvider(semesterToUse.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Semester Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.dashboard,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, ${authState.user?.displayName ?? "Admin"}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${semesterToUse.name} (${semesterToUse.code})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (semesterToUse.isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Metrics Overview
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Metrics Grid
                          _buildMetricsGrid(context, ref, semesterToUse.id),

                          const SizedBox(height: 24),

                          // Quick Actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildQuickActions(context),

                          const SizedBox(height: 24),

                          // Management Sections
                          const Text(
                            'Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildManagementCards(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    WidgetRef ref,
    String semesterId,
  ) {
    final coursesAsync = ref.watch(coursesBySemesterProvider(semesterId));

    return coursesAsync.when(
      data: (courses) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              title: 'Courses',
              value: '${courses.length}',
              icon: Icons.book,
              color: Colors.blue,
              onTap: () => context.push('/courses'),
            ),
            _MetricCard(
              title: 'Groups',
              value: '0', // TODO: Calculate from courses
              icon: Icons.group,
              color: Colors.green,
              onTap: () {},
            ),
            _MetricCard(
              title: 'Students',
              value: '0', // TODO: Calculate from enrollments
              icon: Icons.people,
              color: Colors.orange,
              onTap: () {},
            ),
            _MetricCard(
              title: 'Assignments',
              value: '0', // TODO: Get from assignments
              icon: Icons.assignment,
              color: Colors.purple,
              onTap: () {},
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickActionChip(
          label: 'New Course',
          icon: Icons.add_circle,
          onTap: () => context.push('/courses/new'),
        ),
        _QuickActionChip(
          label: 'New Semester',
          icon: Icons.calendar_month,
          onTap: () => context.push('/semesters/new'),
        ),
        _QuickActionChip(
          label: 'Import Students',
          icon: Icons.upload_file,
          onTap: () => context.push('/students/import'),
        ),
        _QuickActionChip(
          label: 'Reports',
          icon: Icons.analytics,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagementCards(BuildContext context) {
    return Column(
      children: [
        _ManagementCard(
          title: 'Semester Management',
          description: 'Create and manage academic semesters',
          icon: Icons.calendar_today,
          color: Colors.indigo,
          onTap: () => context.push('/semesters'),
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          title: 'Course Management',
          description: 'Manage courses and course content',
          icon: Icons.school,
          color: Colors.blue,
          onTap: () => context.push('/courses'),
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          title: 'Student Management',
          description: 'View and manage student accounts',
          icon: Icons.people,
          color: Colors.green,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.school, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'E-Learning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Faculty of IT',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Semesters'),
            onTap: () {
              Navigator.pop(context);
              context.push('/semesters');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Courses'),
            onTap: () {
              Navigator.pop(context);
              context.push('/courses');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final ref = ProviderScope.containerOf(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSemesterSwitcher(BuildContext context, WidgetRef ref) {
    // TODO: Implement semester switcher dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semester switcher coming soon')),
    );
  }
}

/// Metric Card Widget
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
}

/// Quick Action Chip Widget
class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// Management Card Widget
class _ManagementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
