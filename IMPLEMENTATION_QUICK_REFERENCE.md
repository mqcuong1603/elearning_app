# Enhanced Homepage Implementation - Quick Reference Guide

## Quick File Locations

| Component | File Path |
|-----------|-----------|
| Current Student Home | `/lib/screens/student/student_home_screen.dart` |
| Auth Service | `/lib/services/auth_service.dart` |
| Course Provider | `/lib/providers/course_provider.dart` |
| Semester Provider | `/lib/providers/semester_provider.dart` |
| Assignment Provider | `/lib/providers/assignment_provider.dart` |
| Notification Provider | `/lib/providers/notification_provider.dart` |
| Announcement Provider | `/lib/providers/announcement_provider.dart` |
| App Constants | `/lib/config/app_constants.dart` |
| User Model | `/lib/models/user_model.dart` |
| Course Model | `/lib/models/course_model.dart` |
| Semester Model | `/lib/models/semester_model.dart` |

---

## Data Flow Diagram

```
                         StudentHomeScreen
                                |
                  ______________|______________
                 |              |              |
              watch         read/watch      read
                 |              |              |
            AuthService    Providers       Services
          (currentUser)   (CoursePrvdr,   (CourseService,
                          SemesterPrvdr)  AssignmentService)
                 |              |              |
                 |______________|______________|
                                |
                         Firestore + Hive
```

---

## Current User Access Pattern

```dart
// Get current user (global auth state)
final authService = context.watch<AuthService>();
final currentUser = authService.currentUser;

// Check role
if (authService.isStudent) {
  // Load student-specific data
}

// Access user properties
final fullName = currentUser?.fullName;
final studentId = currentUser?.studentId;
final email = currentUser?.email;
```

---

## Semester Context Pattern

```dart
// Load semesters
final semesterProvider = context.read<SemesterProvider>();
await semesterProvider.loadSemesters();

// Get current semester
final currentSemester = semesterProvider.currentSemester;

// Check if viewing current semester
bool isCurrentSemester = _selectedSemester?.isCurrent ?? false;
```

---

## Course Loading Pattern

```dart
// Load courses for student in specific semester
final courseProvider = context.read<CourseProvider>();
final courses = await courseProvider.loadCoursesForStudentBySemester(
  studentId: currentUser.id,
  semesterId: selectedSemester.id,
);

// Watch for updates
Consumer<CourseProvider>(
  builder: (context, courseProvider, child) {
    return ListView.builder(
      itemCount: courseProvider.courses.length,
      itemBuilder: (context, index) {
        final course = courseProvider.courses[index];
        return CourseCard(course: course);
      },
    );
  },
)
```

---

## Assignment Loading Pattern

```dart
// Load assignments for student
final assignmentProvider = context.read<AssignmentProvider>();
final assignments = await assignmentProvider.loadAssignmentsForStudent(
  studentId: currentUser.id,
);

// Filter by status
final pendingAssignments = assignments
    .where((a) => a.status == AppConstants.assignmentStatusNotSubmitted)
    .toList();

final overdueAssignments = assignments
    .where((a) => a.dueDate.isBefore(DateTime.now()))
    .toList();
```

---

## Notification Loading Pattern

```dart
// Load notifications
final notificationProvider = context.read<NotificationProvider>();
final notifications = await notificationProvider.loadNotificationsForUser(
  userId: currentUser.id,
);

// Filter unread
final unreadCount = notifications
    .where((n) => !n.isRead)
    .length;
```

---

## Announcement Loading Pattern

```dart
// Load announcements for courses
final announcementProvider = context.read<AnnouncementProvider>();

// For each course, load its announcements
for (var course in enrolledCourses) {
  final announcements = await announcementProvider
      .loadAnnouncementsByCourse(courseId: course.id);
}

// Or load all announcements
final allAnnouncements = await announcementProvider
    .loadAnnouncementsForCourses(courseIds: enrolledCourses.map((c) => c.id).toList());
```

---

## Component State Structure

```dart
class StudentHomeScreen extends StatefulWidget {
  // Current implementation has:
  int _selectedIndex = 0;                    // Tab selection
  List<CourseModel> _enrolledCourses = [];   // Courses for semester
  bool _isLoadingCourses = true;             // Loading state
  List<SemesterModel> _semesters = [];       // All semesters
  SemesterModel? _selectedSemester;          // Selected semester

  // ADD FOR ENHANCED VERSION:
  List<AssignmentModel> _assignments = [];       // User assignments
  List<NotificationModel> _notifications = [];   // User notifications
  List<AnnouncementModel> _announcements = [];   // Course announcements
  Map<String, int> _assignmentStats = {};       // Counts by status
  bool _isLoadingAssignments = false;            // Assignment loading
  bool _isLoadingNotifications = false;          // Notification loading
}
```

---

## Tab Implementation Template

```dart
Widget _buildHomeTab(dynamic currentUser) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(AppTheme.spacingM),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Welcome Section (existing)
        _buildWelcomeCard(currentUser),
        
        // 2. Quick Actions (NEW)
        _buildQuickActionsSection(),
        
        // 3. My Courses (existing)
        _buildCoursesSection(),
        
        // 4. Upcoming Deadlines (NEW - replace placeholder)
        _buildUpcomingDeadlinesSection(),
        
        // 5. Announcements (NEW)
        _buildAnnouncementsSection(),
        
        // 6. Notifications (NEW)
        _buildNotificationsSection(),
      ],
    ),
  );
}
```

---

## Widget Building Pattern

```dart
Widget _buildUpcomingDeadlinesSection() {
  // Filter and sort assignments
  final upcoming = _assignments
      .where((a) => a.dueDate.isAfter(DateTime.now()))
      .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  if (upcoming.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Center(
          child: Text('No upcoming deadlines'),
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Upcoming Deadlines',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: AppTheme.spacingM),
      ...upcoming.take(5).map((assignment) {
        return _buildDeadlineCard(assignment);
      }).toList(),
    ],
  );
}
```

---

## Common Methods to Implement

```dart
Future<void> _loadAssignments() async {
  if (!mounted) return;
  
  final authService = context.read<AuthService>();
  final currentUser = authService.currentUser;
  
  if (currentUser == null) return;
  
  setState(() => _isLoadingAssignments = true);
  
  try {
    final assignmentProvider = context.read<AssignmentProvider>();
    _assignments = await assignmentProvider.loadAssignmentsForStudent(
      currentUser.id,
    );
    
    // Calculate stats
    _assignmentStats = {
      'total': _assignments.length,
      'submitted': _assignments.where((a) => 
        a.status != AppConstants.assignmentStatusNotSubmitted).length,
      'pending': _assignments.where((a) => 
        a.status == AppConstants.assignmentStatusNotSubmitted).length,
      'graded': _assignments.where((a) => 
        a.status == AppConstants.assignmentStatusGraded).length,
    };
    
    if (mounted) setState(() => _isLoadingAssignments = false);
  } catch (e) {
    print('Error loading assignments: $e');
    if (mounted) setState(() => _isLoadingAssignments = false);
  }
}

Future<void> _loadNotifications() async {
  if (!mounted) return;
  
  final authService = context.read<AuthService>();
  final currentUser = authService.currentUser;
  
  if (currentUser == null) return;
  
  setState(() => _isLoadingNotifications = true);
  
  try {
    final notificationProvider = context.read<NotificationProvider>();
    _notifications = await notificationProvider.loadNotificationsForUser(
      currentUser.id,
    );
    
    if (mounted) setState(() => _isLoadingNotifications = false);
  } catch (e) {
    print('Error loading notifications: $e');
    if (mounted) setState(() => _isLoadingNotifications = false);
  }
}

Future<void> _loadAnnouncements() async {
  if (!mounted || _enrolledCourses.isEmpty) return;
  
  try {
    final announcementProvider = context.read<AnnouncementProvider>();
    final courseIds = _enrolledCourses.map((c) => c.id).toList();
    
    _announcements = await announcementProvider.loadAnnouncementsForCourses(
      courseIds: courseIds,
    );
    
    if (mounted) setState(() {});
  } catch (e) {
    print('Error loading announcements: $e');
  }
}
```

---

## Dashboard Tab - Stats Card Implementation

```dart
Widget _buildDashboardTab(dynamic currentUser) {
  final totalCourses = _enrolledCourses.length;
  final totalAssignments = _assignmentStats['total'] ?? 0;
  final pendingAssignments = _assignmentStats['pending'] ?? 0;
  final completedAssignments = _assignmentStats['graded'] ?? 0;
  final avgScore = _calculateAverageScore();

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
        
        // Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.spacingM,
          mainAxisSpacing: AppTheme.spacingM,
          children: [
            _buildStatCard(
              icon: Icons.book,
              title: 'Courses',
              value: '$totalCourses',
              color: AppTheme.primaryColor,
            ),
            _buildStatCard(
              icon: Icons.assignment,
              title: 'Assignments',
              value: '$totalAssignments',
              color: AppTheme.infoColor,
            ),
            _buildStatCard(
              icon: Icons.pending_actions,
              title: 'Pending',
              value: '$pendingAssignments',
              color: AppTheme.warningColor,
            ),
            _buildStatCard(
              icon: Icons.assignment_turned_in,
              title: 'Completed',
              value: '$completedAssignments',
              color: AppTheme.successColor,
            ),
          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
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
          ),
        ],
      ),
    ),
  );
}

double _calculateAverageScore() {
  // Implement based on assignment grades
  return 0.0;
}
```

---

## Context Usage Pattern

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSemesters();
    _loadAssignments();      // NEW
    _loadNotifications();    // NEW
    _loadAnnouncements();    // NEW
  });
}

@override
Widget build(BuildContext context) {
  final authService = context.watch<AuthService>();
  final currentUser = authService.currentUser;

  // Also watch providers for updates
  context.watch<AssignmentProvider>();  // NEW
  context.watch<NotificationProvider>(); // NEW
  context.watch<AnnouncementProvider>(); // NEW

  return Scaffold(
    // ... rest of widget
  );
}
```

---

## Error Handling Pattern

```dart
Future<void> _loadAssignments() async {
  if (!mounted) return;

  setState(() => _isLoadingAssignments = true);

  try {
    final assignmentProvider = context.read<AssignmentProvider>();
    final currentUser = context.read<AuthService>().currentUser;
    
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    _assignments = await assignmentProvider.loadAssignmentsForStudent(
      currentUser.id,
    );
    
    if (mounted) {
      setState(() => _isLoadingAssignments = false);
    }
  } catch (e) {
    print('Error loading assignments: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading assignments: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() => _isLoadingAssignments = false);
    }
  }
}
```

---

## UI Helper Methods

```dart
Widget _buildLoadingShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Container(
            height: 100,
            color: Colors.grey[300],
          ),
        );
      },
    ),
  );
}

Widget _buildEmptyState({
  required String title,
  required String message,
  required IconData icon,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textDisabledColor,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textDisabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## Provider Usage Examples

```dart
// In build method
final courseProvider = context.watch<CourseProvider>();
final assignmentProvider = context.watch<AssignmentProvider>();
final semesterProvider = context.watch<SemesterProvider>();

// Check loading states
if (courseProvider.isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// Access data
final courses = courseProvider.courses;
final errorMessage = assignmentProvider.error;

// Get counts
final courseCount = courseProvider.coursesCount;
final assignmentCount = assignmentProvider.assignmentsCount;

// Check if empty
if (courseProvider.courses.isEmpty && !courseProvider.isLoading) {
  return _buildEmptyState(
    icon: Icons.school,
    title: 'No Courses',
    message: 'You are not enrolled in any courses yet',
  );
}
```

---

## Testing User Access

```dart
// Login as student
// Username: (any student from Firestore)
// Password: (student password)

// Login as instructor
// Username: admin
// Password: admin

// View current user info
print('Current User: ${authService.currentUser?.fullName}');
print('Role: ${authService.currentUser?.role}');
print('Is Instructor: ${authService.isInstructor}');
print('Is Student: ${authService.isStudent}');
```

---

## Notes for Implementation

1. **Always check mounted** before setState() in async methods
2. **Load data in initState** using WidgetsBinding.instance.addPostFrameCallback()
3. **Watch providers** only for data that affects UI rendering
4. **Read services** when you don't need to react to changes
5. **Use context.read()** inside async callbacks (not in build)
6. **Handle null values** for optional fields
7. **Filter locally** before making multiple service calls
8. **Cache results** in local state variables
9. **Show loading indicators** during data fetching
10. **Display error messages** to user with SnackBar

