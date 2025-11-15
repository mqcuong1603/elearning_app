import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import '../shared/course_space_screen.dart';
import '../shared/messaging/conversations_list_screen.dart';
import '../common/profile_screen.dart';
import './all_forums_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  List<CourseModel> _enrolledCourses = [];
  bool _isLoadingCourses = true;
  String? _selectedSemesterId;
  String? _lastKnownCurrentSemesterId; // Track current semester changes

  // Dashboard data
  List<AssignmentModel> _allAssignments = [];
  List<QuizModel> _allQuizzes = [];
  bool _isLoadingDashboard = false;
  List<String> _studentGroupIds = [];

  @override
  void initState() {
    super.initState();
    // Defer loading to after the first frame to avoid build-phase conflicts
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
          await _loadEnrolledCourses();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading semesters: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadEnrolledCourses() async {
    if (!mounted) return;

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null || _selectedSemesterId == null) return;

    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courseProvider = context.read<CourseProvider>();
      final courses = await courseProvider.loadCoursesForStudentBySemester(
        currentUser.id,
        _selectedSemesterId!,
      );

      if (mounted) {
        setState(() {
          _enrolledCourses = courses;
          _isLoadingCourses = false;
        });

        // Load dashboard data after courses are loaded
        await _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null || _enrolledCourses.isEmpty) return;

    setState(() {
      _isLoadingDashboard = true;
    });

    try {
      final groupProvider = context.read<GroupProvider>();
      final assignmentProvider = context.read<AssignmentProvider>();
      final quizProvider = context.read<QuizProvider>();

      // Get student's group IDs from all enrolled courses
      Set<String> groupIds = {};
      for (var course in _enrolledCourses) {
        await groupProvider.loadGroupsByCourse(course.id);
        for (var group in groupProvider.groups) {
          if (group.studentIds.contains(currentUser.id)) {
            groupIds.add(group.id);
          }
        }
      }

      _studentGroupIds = groupIds.toList();

      // Load all assignments and quizzes for enrolled courses
      List<AssignmentModel> allAssignments = [];
      List<QuizModel> allQuizzes = [];

      for (var course in _enrolledCourses) {
        // Load assignments for this course
        await assignmentProvider.loadAssignmentsForStudent(
          courseId: course.id,
          studentId: currentUser.id,
          studentGroupIds: _studentGroupIds,
        );
        allAssignments.addAll(assignmentProvider.assignments);

        // Load quizzes for this course
        await quizProvider.loadAvailableQuizzes(
          courseId: course.id,
          studentGroupIds: _studentGroupIds,
        );
        allQuizzes.addAll(quizProvider.quizzes);
      }

      if (mounted) {
        setState(() {
          _allAssignments = allAssignments;
          _allQuizzes = allQuizzes;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDashboard = false;
        });
        print('Error loading dashboard data: $e');
      }
    }
  }

  Future<void> _onSemesterChanged(SemesterModel? semester) async {
    if (semester == null || semester.id == _selectedSemesterId) return;

    setState(() {
      _selectedSemesterId = semester.id;
    });

    await _loadEnrolledCourses();
  }

  bool _isCurrentSemester(SemesterModel? semester) {
    return semester?.isCurrent ?? false;
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
      // If student is viewing the old current semester, auto-switch to new one
      if (_selectedSemesterId == _lastKnownCurrentSemesterId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedSemesterId = currentSemesterId;
              _lastKnownCurrentSemesterId = currentSemesterId;
            });
            _loadEnrolledCourses();
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
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(currentUser, semesters, selectedSemester),
          _buildDashboardTab(currentUser),
          _buildForumTab(currentUser),
          _buildMessagingTab(currentUser),
          _buildProfileTab(currentUser),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Forum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(dynamic currentUser, List<SemesterModel> semesters,
      SemesterModel? selectedSemester) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            color: AppTheme.primaryLightColor,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  UserAvatar(
                    avatarUrl: currentUser?.avatarUrl,
                    fallbackText: currentUser?.fullName ?? 'Student',
                    radius: 30,
                    fontSize: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: AppTheme.textOnPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currentUser?.fullName ?? 'Student',
                          style: TextStyle(
                            color: AppTheme.textOnPrimaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser?.studentId != null)
                          Text(
                            'ID: ${currentUser!.studentId}',
                            style: TextStyle(
                              color: AppTheme.textOnPrimaryColor.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

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
              // Semester Switcher
              if (semesters.isNotEmpty)
                _buildSemesterSwitcher(semesters, selectedSemester),
            ],
          ),
          // Read-only mode indicator for past semesters
          if (!_isCurrentSemester(selectedSemester)) ...[
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'This is a past semester. You can view courses but cannot submit assignments or take quizzes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),

          // Courses List
          if (_isLoadingCourses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingXL),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_enrolledCourses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.school,
                        size: 64,
                        color: AppTheme.textDisabledColor,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'No courses enrolled yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Your instructor will enroll you in courses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textDisabledColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(_enrolledCourses.length, (index) {
              final course = _enrolledCourses[index];
              return _buildCourseCard(course, currentUser, selectedSemester);
            }),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(dynamic currentUser) {
    // Calculate assignment stats
    final now = DateTime.now();
    final openAssignments = _allAssignments.where((a) => a.isOpen).toList();
    final upcomingAssignments = _allAssignments.where((a) => a.isUpcoming).toList();

    final upcomingDueThisWeek = _allAssignments.where((a) {
      final daysUntilDue = a.deadline.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7 && a.isOpen;
    }).toList();

    final totalQuizzes = _allQuizzes.length;

    // Sort upcoming by due date
    upcomingDueThisWeek.sort((a, b) => a.deadline.compareTo(b.deadline));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Quick Stats
          if (_isLoadingDashboard)
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
                    icon: Icons.assignment,
                    title: 'Open',
                    value: '${openAssignments.length}',
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    title: 'Upcoming',
                    value: '${upcomingAssignments.length}',
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
                    icon: Icons.schedule,
                    title: 'Due This Week',
                    value: '${upcomingDueThisWeek.length}',
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.quiz,
                    title: 'Total Quizzes',
                    value: '$totalQuizzes',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Upcoming Deadlines
            Text(
              'Upcoming Deadlines',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (upcomingDueThisWeek.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Center(
                    child: Text(
                      'No upcoming deadlines this week',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ),
                ),
              )
            else
              ...upcomingDueThisWeek.take(5).map((assignment) {
                final daysUntil = assignment.deadline.difference(now).inDays;

                String timeText;
                Color timeColor;
                if (daysUntil == 0) {
                  timeText = 'Due today';
                  timeColor = AppTheme.errorColor;
                } else if (daysUntil == 1) {
                  timeText = 'Due tomorrow';
                  timeColor = AppTheme.warningColor;
                } else if (daysUntil <= 3) {
                  timeText = 'Due in $daysUntil days';
                  timeColor = AppTheme.warningColor;
                } else {
                  timeText = 'Due in $daysUntil days';
                  timeColor = AppTheme.textSecondaryColor;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: ListTile(
                    leading: Icon(
                      Icons.assignment,
                      color: timeColor,
                    ),
                    title: Text(
                      assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _getCourseName(assignment.courseId),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: timeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: timeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ],
      ),
    );
  }

  String _getCourseName(String courseId) {
    try {
      final course =
          _enrolledCourses.firstWhere((c) => c.id == courseId);
      return course.name;
    } catch (e) {
      return 'Unknown Course';
    }
  }

  Widget _buildForumTab(dynamic currentUser) {
    return const AllForumsScreen();
  }

  Widget _buildMessagingTab(dynamic currentUser) {
    return const ConversationsListScreen();
  }

  Widget _buildProfileTab(dynamic currentUser) {
    // Use the ProfileScreen component directly
    return const ProfileScreen();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(
      CourseModel course, dynamic currentUser, SemesterModel? selectedSemester) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: () {
          // Navigate to Course Space
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseSpaceScreen(
                course: course,
                currentUserId: currentUser?.id ?? '',
                currentUserRole: AppConstants.roleStudent,
                isReadOnly: !_isCurrentSemester(selectedSemester),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Cover Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusM),
                  topRight: Radius.circular(AppTheme.radiusM),
                ),
                image: course.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(course.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: course.coverImageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.school,
                        size: 48,
                        color: AppTheme.textOnPrimaryColor.withOpacity(0.7),
                      ),
                    )
                  : null,
            ),

            // Course Info
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Code
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      course.code,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),

                  // Course Name
                  Text(
                    course.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingS),

                  // Instructor Info
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Expanded(
                        child: Text(
                          course.instructorName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),

                  // Sessions Info
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${course.sessions} sessions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
}
