# Flutter E-Learning Codebase Structure Analysis

## Overview
This is a comprehensive Flutter application for E-Learning Management, inspired by Google Classroom. It supports both students and instructors with role-based access control.

**Working Directory:** `/home/user/elearning_app`
**Current Branch:** `claude/enhanced-homepage-role-based-01JpXzeSsTpaQvy1KTp4h57A`

---

## 1. Directory Structure

### Main Folders
```
/home/user/elearning_app/lib/
├── config/          # Configuration & Constants
├── models/          # Data Models
├── providers/       # State Management (Provider Pattern)
├── screens/         # UI Screens
├── services/        # API & Business Logic
├── utils/           # Utility Functions
└── widgets/         # Reusable UI Components
```

---

## 2. File Organization

### Config Directory (`/lib/config/`)
- **app_constants.dart** - All app-wide constants including:
  - Admin credentials (username: "admin", password: "admin")
  - User roles: "instructor", "student"
  - Firebase collections and Hive box names
  - Error/Success messages
  - File upload limits
  - Assignment/Quiz defaults

- **app_theme.dart** - Material Design theme configuration
- **firebase_options.dart** - Firebase configuration

### Models Directory (`/lib/models/`)
Key data models using Hive for offline storage and JSON serialization for Firestore:

1. **user_model.dart**
   - Fields: id, username, fullName, email, role, avatarUrl, studentId, createdAt, updatedAt, additionalInfo
   - Methods: isInstructor, isStudent getters, copyWith(), toJson(), fromJson()
   - Hive Type ID: 0

2. **semester_model.dart**
   - Fields: id, code, name, createdAt, updatedAt, isCurrent
   - Represents academic semesters
   - Hive Type ID: 1

3. **course_model.dart**
   - Fields: id, code, name, semesterId, sessions, coverImageUrl, description, instructorId, instructorName, createdAt, updatedAt
   - Hive Type ID: 2

4. Other Models:
   - announcement_model.dart
   - assignment_model.dart
   - assignment_submission_model.dart
   - course_model.dart
   - forum_topic_model.dart
   - forum_reply_model.dart
   - group_model.dart
   - material_model.dart
   - message_model.dart
   - notification_model.dart
   - question_model.dart
   - quiz_model.dart
   - quiz_submission_model.dart

### Providers Directory (`/lib/providers/`)
ChangeNotifier-based state management:

1. **semester_provider.dart**
   - Manages: semesters list, current semester, loading state, errors
   - Methods: loadSemesters(), createSemester(), updateSemester(), deleteSemester(), markAsCurrent(), importFromCSV()

2. **student_provider.dart**
   - Manages: students list, filtered students, loading state
   - Methods: loadStudents(), getStudentById(), createStudent(), updateStudent(), deleteStudent(), searchStudents(), sortStudents()

3. **course_provider.dart**
   - Manages: courses list, filtered courses, current semester ID
   - Methods: loadCourses(), loadCoursesBySemester(), getCourseById(), createCourse(), updateCourse(), deleteCourse(), loadCoursesForStudent(), loadCoursesForStudentBySemester()

4. Other Providers:
   - announcement_provider.dart
   - assignment_provider.dart
   - group_provider.dart
   - material_provider.dart
   - message_provider.dart
   - notification_provider.dart
   - quiz_provider.dart
   - forum_provider.dart

### Services Directory (`/lib/services/`)
Business logic layer handling API calls and data operations:

1. **auth_service.dart**
   - Current User: `UserModel? _currentUser`
   - Methods:
     - `login(username, password)` - Returns UserModel
     - `logout()` - Clears current user
     - `registerStudent()` - Create new student (instructor only)
     - `updateProfile()` - Update user info
     - `changePassword()` - Change user password
     - `getUserById()` - Fetch user from Firestore
     - `validateSession()` - Check auth on app start
     - `checkUsernameExists()` - Verify username
   - Getters: `isLoggedIn`, `isInstructor`, `isStudent`, `currentUser`
   - Uses Firebase Anonymous Auth + Custom Firestore credentials

2. **semester_service.dart**
   - Methods: getAllSemesters(), createSemester(), updateSemester(), deleteSemester(), markAsCurrent(), batchCreateSemesters()

3. **course_service.dart**
   - Methods: getAllCourses(), getCourseById(), getCoursesBySemester(), getCoursesForStudent(), getCoursesForStudentBySemester(), createCourse(), updateCourse(), deleteCourse()

4. **student_service.dart**
   - Methods: getAllStudents(), getStudentById(), createStudent(), updateStudent(), deleteStudent(), batchCreateStudents()

5. **firestore_service.dart**
   - Low-level Firestore operations

6. **hive_service.dart**
   - Local offline caching using Hive database
   - Box names for different data types

7. **storage_service.dart**
   - Firebase Storage file upload/download operations

8. Other Services:
   - announcement_service.dart
   - assignment_service.dart
   - group_service.dart
   - material_service.dart
   - quiz_service.dart
   - notification_service.dart
   - message_service.dart
   - forum_service.dart
   - csv_service.dart
   - deadline_monitoring_service.dart

### Screens Directory (`/lib/screens/`)

#### Structure:
```
screens/
├── auth/
│   └── login_screen.dart
├── student/
│   ├── student_home_screen.dart          (Current homepage)
│   ├── assignment_submission_screen.dart
│   ├── quiz_taking_screen.dart
│   └── all_forums_screen.dart
├── instructor/
│   ├── instructor_dashboard_screen.dart
│   ├── student_management_screen.dart
│   ├── course_management_screen.dart
│   ├── assignment_grading_screen.dart
│   ├── quiz_management_screen.dart
│   └── ...
├── shared/
│   ├── course_space_screen.dart
│   ├── material_details_screen.dart
│   └── forum/
│       ├── forum_list_screen.dart
│       ├── forum_topic_detail_screen.dart
│       └── create_topic_screen.dart
│   └── messaging/
│       ├── conversations_list_screen.dart
│       └── chat_screen.dart
├── common/
│   └── notifications_screen.dart
└── debug/
    ├── enrollment_debug_screen.dart
    └── data_migration_screen.dart
```

#### Current Student Home Screen (`/lib/screens/student/student_home_screen.dart`)
**State:** Stateful Widget
**Key Features:**
- 5 Bottom Navigation Tabs:
  1. Home - Shows enrolled courses
  2. Dashboard - Quick stats (placeholder)
  3. Forum - All forums
  4. Messages - Conversations
  5. Profile - User info

**Current State Variables:**
- `_selectedIndex` - Current tab
- `_enrolledCourses` - List of courses
- `_isLoadingCourses` - Loading indicator
- `_semesters` - Available semesters
- `_selectedSemester` - Selected semester

**Key Methods:**
- `_loadSemesters()` - Fetch semesters from provider
- `_loadEnrolledCourses()` - Fetch courses for semester
- `_onSemesterChanged()` - Handle semester switching
- `_handleLogout()` - Logout with confirmation

**UI Components:**
- Welcome Card with user avatar and name
- Semester Switcher dropdown
- Course Cards (tap to navigate to CourseSpaceScreen)
- Dashboard Tab (placeholder with stat cards)
- Profile Tab with user information

---

## 3. Authentication & Role Detection

### Current Implementation

**AuthService (`/lib/services/auth_service.dart`)**
```dart
UserModel? _currentUser;

bool get isLoggedIn => _currentUser != null;
bool get isInstructor => _currentUser?.role == AppConstants.roleInstructor;
bool get isStudent => _currentUser?.role == AppConstants.roleStudent;
```

**User Model Role Detection**
```dart
class UserModel {
  final String role; // 'instructor' or 'student'
  
  bool get isInstructor => role == AppConstants.roleInstructor;
  bool get isStudent => role == AppConstants.roleStudent;
}
```

**App Startup Flow (`/lib/main.dart`)**
1. Firebase initialization
2. Hive offline database initialization
3. MultiProvider setup for dependency injection
4. SplashScreen shown initially
5. SplashScreen calls `authService.validateSession()`
6. Route based on role:
   - Instructor → InstructorDashboardScreen
   - Student → StudentHomeScreen
   - Not logged in → LoginScreen

**Login Credentials:**
- Admin: username="admin", password="admin" (hardcoded)
- Students: stored in Firestore with plain text passwords (not production-ready)

---

## 4. State Management Setup

### Provider Pattern (Provider Package v6.1.2)

**Multi-Provider Configuration in main.dart:**

#### Services (Singleton)
```dart
Provider<AuthService>(create: (_) => AuthService())
Provider<FirestoreService>(create: (_) => FirestoreService())
Provider<StorageService>(create: (_) => StorageService())
Provider<HiveService>(create: (_) => HiveService.instance)
// ... More services
```

#### ProxyProviders (Dependent Services)
```dart
ProxyProvider2<FirestoreService, HiveService, SemesterService>(
  update: (_, firestoreService, hiveService, __) => SemesterService(...)
)
// Allows services to depend on other services
```

#### ChangeNotifierProviders (State Management)
```dart
ChangeNotifierProxyProvider<CourseService, CourseProvider>(
  create: (context) => CourseProvider(
    courseService: context.read<CourseService>()
  ),
  update: (_, courseService, previous) => 
    previous ?? CourseProvider(courseService: courseService)
)
```

**Usage in Screens:**
```dart
// Watch for changes
final authService = context.watch<AuthService>();

// Read without listening
final courseProvider = context.read<CourseProvider>();

// Get notified of changes
Consumer<CourseProvider>(
  builder: (context, courseProvider, child) {
    // Rebuild when courseProvider changes
  }
)
```

---

## 5. Models Summary

### Core Models

#### UserModel
```dart
class UserModel {
  String id;
  String username;
  String fullName;
  String email;
  String role; // 'instructor' or 'student'
  String? avatarUrl;
  String? studentId;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? additionalInfo;
  
  // Getters
  bool get isInstructor;
  bool get isStudent;
  String get displayName;
}
```

#### CourseModel
```dart
class CourseModel {
  String id;
  String code; // e.g., "CS101"
  String name;
  String semesterId;
  int sessions; // 10 or 15
  String? coverImageUrl;
  String? description;
  String instructorId;
  String instructorName;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### SemesterModel
```dart
class SemesterModel {
  String id;
  String code; // e.g., "2024-1"
  String name; // e.g., "Fall 2024"
  DateTime createdAt;
  DateTime updatedAt;
  bool isCurrent;
}
```

---

## 6. Available Services & Methods

### Course Service (`course_service.dart`)
```dart
- getAllCourses() → List<CourseModel>
- getCourseById(courseId) → CourseModel
- getCoursesBySemester(semesterId) → List<CourseModel>
- getCoursesForStudent(studentId) → List<CourseModel>
- getCoursesForStudentBySemester(studentId, semesterId) → List<CourseModel>
- createCourse({...}) → CourseModel
- updateCourse(course) → void
- deleteCourse(id) → void
- courseCodeExistsInSemester(code, semesterId) → bool
- batchCreateCourses(data, semesterId) → Map<String, dynamic>
```

### Assignment Service (`assignment_service.dart`)
```dart
- getAssignmentsByCourse(courseId) → List<AssignmentModel>
- getAssignmentsForStudent(studentId) → List<AssignmentModel>
- getAssignmentSubmissions(assignmentId) → List<AssignmentSubmissionModel>
- createAssignment({...}) → AssignmentModel
- submitAssignment({...}) → AssignmentSubmissionModel
- gradeAssignmentSubmission({...}) → void
```

### Quiz Service (`quiz_service.dart`)
```dart
- getQuizzesByCourse(courseId) → List<QuizModel>
- getQuizzesForStudent(studentId) → List<QuizModel>
- createQuiz({...}) → QuizModel
- getQuizSubmissions(quizId) → List<QuizSubmissionModel>
- submitQuizAnswer({...}) → void
```

### Announcement Service (`announcement_service.dart`)
```dart
- getAnnouncementsByCourse(courseId) → List<AnnouncementModel>
- getAnnouncements(limit) → List<AnnouncementModel>
- createAnnouncement({...}) → AnnouncementModel
```

### Material Service (`material_service.dart`)
```dart
- getMaterialsByCourse(courseId) → List<MaterialModel>
- createMaterial({...}) → MaterialModel
- downloadMaterial(materialId) → File
```

### Notification Service (`notification_service.dart`)
```dart
- getNotifications(userId) → List<NotificationModel>
- sendNotification({...}) → void
- markAsRead(notificationId) → void
```

---

## 7. Widgets Directory

Reusable UI components:
```
widgets/
├── announcement_card.dart              # Display announcements
├── announcement_form_dialog.dart       # Create/edit announcements
├── assignment_form_dialog.dart         # Create/edit assignments
├── course_form_dialog.dart             # Create/edit courses
├── csv_import_dialog.dart              # CSV import UI
├── group_form_dialog.dart              # Create/edit groups
├── material_form_dialog.dart           # Create/edit materials
├── notification_bell_icon.dart         # Notification bell widget
├── semester_form_dialog.dart           # Create/edit semesters
└── student_form_dialog.dart            # Create/edit students
```

---

## 8. Database Setup

### Firestore Collections
- users
- semesters
- courses
- groups
- announcements
- assignments
- assignment_submissions
- quizzes
- questions
- quiz_submissions
- materials
- forum_topics
- forum_replies
- messages
- notifications

### Hive Local Storage
- users_box
- semesters_box
- courses_box
- groups_box
- announcements_box
- assignments_box
- quizzes_box
- materials_box
- notifications_box
- cache_box
- settings_box

---

## 9. Key Constants & Configuration

### Admin Credentials
```dart
static const String adminUsername = 'admin';
static const String adminPassword = 'admin';
```

### User Roles
```dart
static const String roleInstructor = 'instructor';
static const String roleStudent = 'student';
```

### File Upload Limits
```dart
static const int maxFileSizeMB = 50;
static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv'];
```

---

## 10. Dependencies (pubspec.yaml)

**Key Packages:**
- **firebase_core** (v4.2.1) - Firebase initialization
- **firebase_auth** (v6.1.2) - Authentication
- **cloud_firestore** (v6.1.0) - Database
- **firebase_storage** (v13.0.4) - File storage
- **provider** (v6.1.2) - State management
- **hive** (v2.2.3) - Local database
- **cached_network_image** (v3.3.1) - Image caching
- **go_router** (v17.0.0) - Navigation (available but not currently used)

---

## 11. Recommended Architecture for Enhanced Homepage

### Component Hierarchy
```
StudentHomeScreen (Widget)
├── Header Section
│   ├── Welcome Card (User Info)
│   └── Action Buttons
├── Content Tabs
│   ├── Home Tab
│   │   ├── Semester Switcher
│   │   ├── Course Cards
│   │   └── Quick Actions
│   ├── Dashboard Tab
│   │   ├── Stats Cards
│   │   └── Upcoming Deadlines
│   ├── Forum Tab
│   ├── Messages Tab
│   └── Profile Tab
└── Bottom Navigation Bar
```

### State Management Flow
```
StudentHomeScreen
├── watch<AuthService>() → currentUser
├── read<SemesterProvider>() → loadSemesters()
├── read<CourseProvider>() → loadCoursesForStudentBySemester()
├── read<AssignmentProvider>() → loadAssignmentsForStudent()
├── read<NotificationProvider>() → loadNotifications()
└── read<AnnouncementProvider>() → loadAnnouncements()
```

---

## 12. Available Context Access Points

In StudentHomeScreen, you can access:

```dart
// Services (Singleton)
context.read<AuthService>()           // Current user, role detection
context.read<FirestoreService>()      // Direct Firestore access
context.read<StorageService>()        // File operations
context.read<HiveService>()           // Local storage

// Business Logic Services
context.read<CourseService>()         // Course operations
context.read<SemesterService>()       // Semester operations
context.read<StudentService>()        // Student operations
context.read<AssignmentService>()     // Assignment operations
context.read<NotificationService>()   // Notification operations
context.read<AnnouncementService>()   // Announcement operations

// State Providers
context.watch<SemesterProvider>()     // Watch semester state
context.watch<CourseProvider>()       // Watch course state
context.watch<AssignmentProvider>()   // Watch assignment state
context.watch<AnnouncementProvider>() // Watch announcement state
context.watch<NotificationProvider>() // Watch notification state
```

---

## 13. Navigation Pattern

**Current Routing (Manual Navigation):**
```dart
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
```

**Note:** GoRouter is available but not currently used. Current implementation uses MaterialPageRoute.

---

## Key Takeaways for Implementation

1. **Role Detection:** Already implemented in AuthService and UserModel
   - Use `authService.isStudent` / `authService.isInstructor`
   - Or `currentUser.isStudent` / `currentUser.isInstructor`

2. **State Management:** Provider pattern with ChangeNotifier
   - Services provide business logic
   - Providers manage UI state
   - Use `context.read()` and `context.watch()`

3. **Semester Context:** Already implemented
   - Current semester available through SemesterProvider
   - Courses filtered by semester
   - Past semester courses are read-only

4. **User Data:** UserModel contains all necessary user info
   - fullName, email, studentId, role, additionalInfo
   - Easy to extend with custom fields

5. **Screen Structure:** StudentHomeScreen uses IndexedStack
   - Easy to add/modify tabs
   - State preserved when switching tabs

6. **API Layer:** All services follow similar pattern
   - Fetch from Firestore
   - Cache in Hive
   - Convert to/from Models
