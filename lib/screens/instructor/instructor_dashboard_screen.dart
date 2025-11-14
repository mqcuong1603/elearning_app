import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../services/auth_service.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/course_model.dart';
import '../../models/semester_model.dart';
import '../auth/login_screen.dart';
import '../shared/course_space_screen.dart';
import '../debug/enrollment_debug_screen.dart';
import '../debug/data_migration_screen.dart';
import 'semester_management_screen.dart';
import 'course_management_screen.dart';
import 'student_management_screen.dart';
import 'group_management_screen.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  List<CourseModel> _instructorCourses = [];
  bool _isLoadingCourses = true;

  // Semester selection
  String? _selectedSemesterId;
  String? _lastKnownCurrentSemesterId; // Track current semester changes

  // Dashboard metrics
  int _totalGroups = 0;
  int _totalStudents = 0;
  int _totalAssignments = 0;
  int _totalQuizzes = 0;
  bool _isLoadingMetrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSemesters();
    });
  }

  @override
  void dispose() {
    // Stop listening to semester updates when screen is disposed
    final semesterProvider = context.read<SemesterProvider>();
    semesterProvider.stopListening();
    super.dispose();
  }

  Future<void> _loadSemesters() async {
    if (!mounted) return;

    try {
      final semesterProvider = context.read<SemesterProvider>();

      // Start listening to real-time semester updates
      semesterProvider.startListening();

      // Also load initial data
      await semesterProvider.loadSemesters();

      if (mounted) {
        // Set current semester as default
        final currentSemester = semesterProvider.currentSemester;
        if (currentSemester != null) {
          setState(() {
            _selectedSemesterId = currentSemester.id;
            _lastKnownCurrentSemesterId = currentSemester.id;
          });
          await _loadInstructorCourses();
        }
      }
    } catch (e) {
      print('Error loading semesters: $e');
    }
  }

  Future<void> _loadInstructorCourses() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null || _selectedSemesterId == null) return;

    setState(() => _isLoadingCourses = true);

    try {
      final courseProvider = context.read<CourseProvider>();

      // Load courses for selected semester
      await courseProvider.loadCoursesBySemester(_selectedSemesterId!);

      // Filter only courses taught by this instructor
      _instructorCourses = courseProvider.courses
          .where((course) => course.instructorId == currentUser.id)
          .toList();

      // Load metrics after courses are loaded
      await _loadDashboardMetrics();
    } catch (e) {
      print('Load instructor courses error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  Future<void> _loadDashboardMetrics() async {
    if (!mounted || _instructorCourses.isEmpty) return;

    setState(() => _isLoadingMetrics = true);

    try {
      final groupProvider = context.read<GroupProvider>();
      final assignmentProvider = context.read<AssignmentProvider>();
      final quizProvider = context.read<QuizProvider>();

      int totalGroups = 0;
      Set<String> uniqueStudentIds = {};
      int totalAssignments = 0;
      int totalQuizzes = 0;

      for (var course in _instructorCourses) {
        // Load groups for this course
        await groupProvider.loadGroupsByCourse(course.id);
        totalGroups += groupProvider.groups.length;

        // Collect unique student IDs
        for (var group in groupProvider.groups) {
          uniqueStudentIds.addAll(group.studentIds);
        }

        // Load assignments for this course
        await assignmentProvider.loadAssignmentsByCourse(course.id);
        totalAssignments += assignmentProvider.assignments.length;

        // Load quizzes for this course
        await quizProvider.loadQuizzesForCourse(course.id);
        totalQuizzes += quizProvider.quizzes.length;
      }

      if (mounted) {
        setState(() {
          _totalGroups = totalGroups;
          _totalStudents = uniqueStudentIds.length;
          _totalAssignments = totalAssignments;
          _totalQuizzes = totalQuizzes;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard metrics: $e');
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
  }

  Future<void> _onSemesterChanged(SemesterModel? semester) async {
    if (semester == null || semester.id == _selectedSemesterId) return;

    setState(() {
      _selectedSemesterId = semester.id;
    });

    await _loadInstructorCourses();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = context.read<AuthService>();
        await authService.logout();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successLogout),
              backgroundColor: AppTheme.successColor,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    // Watch semester provider for real-time updates
    final semesterProvider = context.watch<SemesterProvider>();
    final semesters = semesterProvider.semesters;

    // Detect when current semester changes and auto-switch if needed
    final currentSemesterId = semesterProvider.currentSemester?.id;
    if (currentSemesterId != null &&
        _lastKnownCurrentSemesterId != null &&
        currentSemesterId != _lastKnownCurrentSemesterId) {
      // Current semester has changed
      // If instructor is viewing the old current semester, auto-switch to new one
      if (_selectedSemesterId == _lastKnownCurrentSemesterId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedSemesterId = currentSemesterId;
              _lastKnownCurrentSemesterId = currentSemesterId;
            });
            _loadInstructorCourses();
          }
        });
      } else {
        // Just update the tracking variable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _lastKnownCurrentSemesterId = currentSemesterId;
            });
          }
        });
      }
    }

    // Safely get selected semester with null checks
    SemesterModel? selectedSemester;
    if (semesters.isNotEmpty && _selectedSemesterId != null) {
      try {
        selectedSemester = semesters.firstWhere(
          (s) => s.id == _selectedSemesterId,
        );
      } catch (e) {
        // If selected semester not found, use current semester
        selectedSemester = semesterProvider.currentSemester;
      }
    } else if (semesters.isNotEmpty) {
      selectedSemester = semesterProvider.currentSemester ?? semesters.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        currentUser?.fullName.substring(0, 1).toUpperCase() ??
                            'A',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppTheme.textOnPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            currentUser?.fullName ?? 'Instructor',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            currentUser?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Semester Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (semesters.isNotEmpty)
                  _buildSemesterSwitcher(semesters, selectedSemester),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Quick Stats
            if (_isLoadingMetrics)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXL),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.class_,
                      title: 'Courses',
                      value: '${_instructorCourses.length}',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.groups,
                      title: 'Groups',
                      value: '$_totalGroups',
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.group,
                      title: 'Students',
                      value: '$_totalStudents',
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.assignment,
                      title: 'Assignments',
                      value: '$_totalAssignments',
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.quiz,
                      title: 'Quizzes',
                      value: '$_totalQuizzes',
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  const Expanded(child: SizedBox()), // Empty space
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spacingL),

            // Progress Charts
            if (!_isLoadingMetrics && _instructorCourses.isNotEmpty) ...[
              Text(
                'Progress Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildProgressCharts(),
              const SizedBox(height: AppTheme.spacingL),
            ],

            // My Courses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Courses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CourseManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (_isLoadingCourses)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_instructorCourses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No courses yet',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Create your first course to get started',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...List.generate(
                _instructorCourses.length > 3 ? 3 : _instructorCourses.length,
                (index) => _buildCourseCard(_instructorCourses[index]),
              ),
            const SizedBox(height: AppTheme.spacingL),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.spacingM,
              crossAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.folder,
                  title: 'Manage\nSemesters',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SemesterManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.school,
                  title: 'Manage\nCourses',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CourseManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.people,
                  title: 'Manage\nStudents',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudentManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.groups,
                  title: 'Manage\nGroups',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GroupManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.bug_report,
                  title: 'Debug\nEnrollment',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EnrollmentDebugScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.build,
                  title: 'Fix Data\nIssues',
                  color: Colors.red,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DataMigrationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: () {
          if (currentUser != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseSpaceScreen(
                  course: course,
                  currentUserId: currentUser.id,
                  currentUserRole: AppConstants.roleInstructor,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 24,
                child: Text(
                  course.code.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.textOnPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      course.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.sessions} sessions',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterSwitcher(
      List<SemesterModel> semesters, SemesterModel? selectedSemester) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: DropdownButton<SemesterModel>(
        value: selectedSemester,
        underline: const SizedBox.shrink(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppTheme.primaryColor,
        ),
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        items: semesters.map((SemesterModel semester) {
          return DropdownMenuItem<SemesterModel>(
            value: semester,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  semester.name,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: semester.isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (semester.isCurrent) ...[
                  const SizedBox(width: AppTheme.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      'Current',
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
        onChanged: _onSemesterChanged,
      ),
    );
  }

  Widget _buildProgressCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resource Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: _buildPieChart(),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: _buildChartLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _totalAssignments + _totalQuizzes + _instructorCourses.length + _totalGroups;
    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            value: _instructorCourses.length.toDouble(),
            title: '${_instructorCourses.length}',
            color: AppTheme.primaryColor,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: _totalGroups.toDouble(),
            title: '$_totalGroups',
            color: AppTheme.infoColor,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: _totalAssignments.toDouble(),
            title: '$_totalAssignments',
            color: AppTheme.warningColor,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: _totalQuizzes.toDouble(),
            title: '$_totalQuizzes',
            color: Colors.purple,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem('Courses', _instructorCourses.length, AppTheme.primaryColor),
        const SizedBox(height: AppTheme.spacingS),
        _buildLegendItem('Groups', _totalGroups, AppTheme.infoColor),
        const SizedBox(height: AppTheme.spacingS),
        _buildLegendItem('Assignments', _totalAssignments, AppTheme.warningColor),
        const SizedBox(height: AppTheme.spacingS),
        _buildLegendItem('Quizzes', _totalQuizzes, Colors.purple),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
