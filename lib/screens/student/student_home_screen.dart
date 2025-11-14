import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../services/auth_service.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/course_model.dart';
import '../../models/semester_model.dart';
import '../auth/login_screen.dart';
import '../shared/course_space_screen.dart';
import '../shared/messaging/conversations_list_screen.dart';
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
  List<SemesterModel> _semesters = [];
  SemesterModel? _selectedSemester;
  bool _isLoadingSemesters = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to after the first frame to avoid build-phase conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSemesters();
    });
  }

  Future<void> _loadSemesters() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSemesters = true;
    });

    try {
      final semesterProvider = context.read<SemesterProvider>();
      await semesterProvider.loadSemesters();

      if (mounted) {
        setState(() {
          _semesters = semesterProvider.semesters;
          // Set current semester as default
          _selectedSemester = semesterProvider.currentSemester;
          _isLoadingSemesters = false;
        });

        // Load courses for the current semester
        if (_selectedSemester != null) {
          await _loadEnrolledCourses();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSemesters = false;
        });
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

    if (currentUser == null || _selectedSemester == null) return;

    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courseProvider = context.read<CourseProvider>();
      final courses = await courseProvider.loadCoursesForStudentBySemester(
        currentUser.id,
        _selectedSemester!.id,
      );

      if (mounted) {
        setState(() {
          _enrolledCourses = courses;
          _isLoadingCourses = false;
        });
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

  Future<void> _onSemesterChanged(SemesterModel? semester) async {
    if (semester == null || semester.id == _selectedSemester?.id) return;

    setState(() {
      _selectedSemester = semester;
    });

    await _loadEnrolledCourses();
  }

  bool get _isCurrentSemester {
    return _selectedSemester?.isCurrent ?? false;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(currentUser),
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

  Widget _buildHomeTab(dynamic currentUser) {
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'S',
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
              if (_semesters.isNotEmpty)
                _buildSemesterSwitcher(),
            ],
          ),
          // Read-only mode indicator for past semesters
          if (!_isCurrentSemester && _selectedSemester != null) ...[
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
              return _buildCourseCard(course, currentUser);
            }),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(dynamic currentUser) {
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
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Completed',
                  value: '0',
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_actions,
                  title: 'Pending',
                  value: '0',
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
                  title: 'Upcoming',
                  value: '0',
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  title: 'Avg Score',
                  value: '-',
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Center(
                child: Text(
                  'No upcoming deadlines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumTab(dynamic currentUser) {
    return const AllForumsScreen();
  }

  Widget _buildMessagingTab(dynamic currentUser) {
    return const ConversationsListScreen();
  }

  Widget _buildProfileTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          // Profile Header
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'S',
              style: TextStyle(
                fontSize: 40,
                color: AppTheme.textOnPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            currentUser?.fullName ?? 'Student',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (currentUser?.studentId != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Student ID: ${currentUser!.studentId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingL),

          // Profile Info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(currentUser?.email ?? 'N/A'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Username'),
                  subtitle: Text(currentUser?.username ?? 'N/A'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Role'),
                  subtitle: Text(
                    currentUser?.role == AppConstants.roleStudent
                        ? 'Student'
                        : 'Instructor',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Actions
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
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

  Widget _buildCourseCard(CourseModel course, dynamic currentUser) {
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
                isReadOnly: !_isCurrentSemester,
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

  Widget _buildSemesterSwitcher() {
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
        value: _selectedSemester,
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
        items: _semesters.map((SemesterModel semester) {
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusXS),
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
