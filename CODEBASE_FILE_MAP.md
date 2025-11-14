# Complete Codebase File Map

## Core Files Summary

### Configuration Files (`/lib/config/`)

| File | Purpose | Key Constants |
|------|---------|---|
| `app_constants.dart` | Global constants | Admin creds, roles, Firestore collections, error messages |
| `app_theme.dart` | Material design theme | Colors, spacing, typography |
| `firebase_options.dart` | Firebase setup | Platform-specific configs |

---

### Data Models (`/lib/models/`)

| Model | Purpose | Key Fields | Hive Type ID |
|-------|---------|---|---|
| `user_model.dart` | User (student/instructor) | id, username, fullName, email, role, studentId | 0 |
| `semester_model.dart` | Academic semester | id, code, name, isCurrent | 1 |
| `course_model.dart` | Course | id, code, name, semesterId, sessions, instructorId | 2 |
| `group_model.dart` | Student group/enrollment | id, name, courseId | 3 |
| `announcement_model.dart` | Course announcements | id, title, content, courseId, creatorId | 4 |
| `assignment_model.dart` | Assignments | id, title, courseId, dueDate, maxAttempts | 5 |
| `assignment_submission_model.dart` | Student submissions | id, assignmentId, studentId, status, grade | 6 |
| `quiz_model.dart` | Quizzes | id, title, courseId, timeLimit, totalPoints | 7 |
| `question_model.dart` | Quiz questions | id, quizId, questionText, options, correctAnswer | 8 |
| `quiz_submission_model.dart` | Quiz attempts | id, quizId, studentId, answers, score | 9 |
| `material_model.dart` | Course materials | id, title, courseId, fileUrl, type | 10 |
| `forum_topic_model.dart` | Forum discussion topics | id, courseId, title, creatorId, createdAt | 11 |
| `forum_reply_model.dart` | Replies to forum topics | id, topicId, content, creatorId | 12 |
| `message_model.dart` | Direct messages | id, senderId, recipientId, content | 13 |
| `notification_model.dart` | User notifications | id, userId, type, content, isRead | 14 |

---

### Services (`/lib/services/`)

#### Authentication & Core Services

| Service | Purpose | Main Methods |
|---------|---------|---|
| `auth_service.dart` | User authentication | login(), logout(), registerStudent(), updateProfile(), validateSession(), isInstructor, isStudent, currentUser |
| `firestore_service.dart` | Firestore database | CRUD operations, query building |
| `storage_service.dart` | Firebase storage files | upload(), download(), delete() |
| `hive_service.dart` | Local database caching | Box management, offline sync |

#### Domain Services

| Service | Purpose | Main Methods |
|---------|---------|---|
| `semester_service.dart` | Semester management | getAllSemesters(), createSemester(), markAsCurrent() |
| `course_service.dart` | Course management | getCoursesBySemester(), getCoursesForStudent(), createCourse(), deleteCourse() |
| `student_service.dart` | Student management | getAllStudents(), createStudent(), updateStudent(), deleteStudent() |
| `group_service.dart` | Student groups/enrollment | getGroupsByCourse(), addStudentToGroup(), removeStudentFromGroup() |
| `announcement_service.dart` | Announcements | getAnnouncementsByCourse(), createAnnouncement(), updateAnnouncement() |
| `assignment_service.dart` | Assignment management | getAssignmentsByCourse(), submitAssignment(), gradeSubmission(), getAssignmentsForStudent() |
| `quiz_service.dart` | Quiz management | getQuizzesByCourse(), createQuiz(), submitQuizAnswer(), getQuizSubmissions() |
| `question_service.dart` | Quiz questions | getQuestionsByQuiz(), createQuestion(), updateQuestion() |
| `material_service.dart` | Course materials | getMaterialsByCourse(), createMaterial(), downloadMaterial() |
| `forum_service.dart` | Forum discussions | getForumTopicsByCourse(), createTopic(), createReply(), getTopicReplies() |
| `message_service.dart` | Direct messaging | getConversations(), sendMessage(), getMessages() |
| `notification_service.dart` | Notifications | getNotifications(), sendNotification(), markAsRead() |
| `email_service.dart` | Email notifications | sendEmail(), configureSMTP() |
| `csv_service.dart` | CSV import/export | parseCSV(), importStudents(), exportData() |
| `deadline_monitoring_service.dart` | Deadline tracking | startMonitoring(), checkDeadlines(), sendReminders() |

---

### State Management - Providers (`/lib/providers/`)

| Provider | Service It Wraps | State Variables | Key Methods |
|----------|------------------|---|---|
| `semester_provider.dart` | SemesterService | semesters, currentSemester, isLoading, error | loadSemesters(), createSemester(), markAsCurrent(), search() |
| `course_provider.dart` | CourseService | courses, currentSemesterId, isLoading, error | loadCourses(), loadCoursesBySemester(), loadCoursesForStudent() |
| `student_provider.dart` | StudentService | students, filteredStudents, isLoading, error | loadStudents(), createStudent(), deleteStudent(), search(), sort() |
| `group_provider.dart` | GroupService | groups, isLoading, error | loadGroups(), createGroup(), addStudent(), removeStudent() |
| `announcement_provider.dart` | AnnouncementService | announcements, isLoading, error | loadAnnouncements(), createAnnouncement(), deleteAnnouncement() |
| `assignment_provider.dart` | AssignmentService | assignments, submissions, isLoading, error | loadAssignments(), submitAssignment(), gradeSubmission() |
| `material_provider.dart` | MaterialService | materials, isLoading, error | loadMaterials(), createMaterial(), deleteMaterial() |
| `quiz_provider.dart` | QuizService | quizzes, submissions, isLoading, error | loadQuizzes(), submitAnswer(), getQuizResults() |
| `forum_provider.dart` | ForumService | topics, replies, isLoading, error | loadTopics(), createTopic(), createReply() |
| `message_provider.dart` | MessageService | conversations, messages, isLoading, error | loadConversations(), sendMessage(), getMessages() |
| `notification_provider.dart` | NotificationService | notifications, unreadCount, isLoading, error | loadNotifications(), markAsRead(), deleteNotification() |

---

### Screens (`/lib/screens/`)

#### Authentication (`/auth/`)
| Screen | Purpose | Type |
|--------|---------|------|
| `login_screen.dart` | User login | Stateful |

#### Student Screens (`/student/`)
| Screen | Purpose | Type | State |
|--------|---------|------|-------|
| `student_home_screen.dart` | Main student homepage | Stateful | _selectedIndex, _enrolledCourses, _semesters, _selectedSemester |
| `assignment_submission_screen.dart` | Submit assignments | Stateful | _selectedFile, _submittedStatus |
| `quiz_taking_screen.dart` | Take quizzes | Stateful | _currentQuestion, _answers, _timeRemaining |
| `all_forums_screen.dart` | View all forums | Stateful | _forumTopics, _isLoading |

#### Instructor Screens (`/instructor/`)
| Screen | Purpose |
|--------|---------|
| `instructor_dashboard_screen.dart` | Main instructor dashboard |
| `student_management_screen.dart` | Manage students |
| `course_management_screen.dart` | Manage courses |
| `semester_management_screen.dart` | Manage semesters |
| `assignment_grading_screen.dart` | Grade assignments |
| `assignment_tracking_screen.dart` | Track assignment submissions |
| `quiz_management_screen.dart` | Manage quizzes |
| `quiz_tracking_screen.dart` | Track quiz submissions |
| `question_bank_screen.dart` | Manage quiz questions |
| `group_management_screen.dart` | Manage student groups |

#### Shared Screens (`/shared/`)
| Screen | Purpose |
|--------|---------|
| `course_space_screen.dart` | Course content view (materials, assignments, etc.) |
| `material_details_screen.dart` | View course material |
| `forum/forum_list_screen.dart` | List forum topics |
| `forum/forum_topic_detail_screen.dart` | View topic with replies |
| `forum/create_topic_screen.dart` | Create forum topic |
| `messaging/conversations_list_screen.dart` | List conversations |
| `messaging/chat_screen.dart` | One-on-one chat |

#### Common Screens (`/common/`)
| Screen | Purpose |
|--------|---------|
| `notifications_screen.dart` | View all notifications |

#### Debug Screens (`/debug/`)
| Screen | Purpose |
|--------|---------|
| `enrollment_debug_screen.dart` | Debug enrollment issues |
| `data_migration_screen.dart` | Migrate data between versions |

---

### Reusable Widgets (`/lib/widgets/`)

| Widget | Purpose | Input Parameters |
|--------|---------|---|
| `announcement_card.dart` | Display announcement | AnnouncementModel, onTap callback |
| `announcement_form_dialog.dart` | Create/edit announcement | title, content, onSubmit |
| `assignment_form_dialog.dart` | Create/edit assignment | courseId, onSubmit |
| `course_form_dialog.dart` | Create/edit course | semesterId, onSubmit |
| `csv_import_dialog.dart` | Import CSV data | fileType, onSubmit |
| `group_form_dialog.dart` | Create/edit group | courseId, onSubmit |
| `material_form_dialog.dart` | Create/edit material | courseId, onSubmit |
| `notification_bell_icon.dart` | Notification bell | unreadCount, onPressed |
| `semester_form_dialog.dart` | Create/edit semester | onSubmit |
| `student_form_dialog.dart` | Create/edit student | onSubmit |

---

### Utilities (`/lib/utils/`)

(Not yet explored in detail - check for helper functions)

---

## Data Flow Architecture

```
┌─────────────────────────────────────┐
│      User Interface Layer           │
│  (Screens in /screens/)             │
└────────────┬────────────────────────┘
             │
    ┌────────▼─────────┐
    │   State Layer    │
    │  (Providers)     │
    │  Watch patterns  │
    └────────┬─────────┘
             │
    ┌────────▼──────────────┐
    │   Business Logic      │
    │    (Services)         │
    │  - Auth              │
    │  - Courses           │
    │  - Assignments       │
    │  - etc.              │
    └────────┬──────────────┘
             │
    ┌────────▼──────────────────────┐
    │    Data Persistence Layer      │
    │  ┌──────────────┐  ┌────────┐ │
    │  │ Firestore    │  │  Hive  │ │
    │  │ (Remote)     │  │(Local) │ │
    │  └──────────────┘  └────────┘ │
    └───────────────────────────────┘
```

---

## Current User Authentication Flow

```
SplashScreen
    │
    ├─ AuthService.validateSession()
    │   ├─ Check Firebase Auth
    │   └─ Restore UserModel from Firestore
    │
    ├─ If logged in:
    │   ├─ authService.isInstructor → InstructorDashboardScreen
    │   └─ authService.isStudent → StudentHomeScreen
    │
    └─ If not logged in:
        └─ LoginScreen
```

---

## Role-Based Access Pattern

```
if (authService.isStudent) {
  // Show StudentHomeScreen with:
  // - Enrolled courses
  // - Personal assignments
  // - Quiz submissions
  // - Forum access
  // - Messages
}

if (authService.isInstructor) {
  // Show InstructorDashboardScreen with:
  // - Course management
  // - Student management
  // - Assignment grading
  // - Quiz management
  // - Announcements
}
```

---

## Available Methods at Each Layer

### AuthService Methods
```
- login(username, password) → UserModel
- logout() → void
- registerStudent({...}) → UserModel
- updateProfile({...}) → void
- changePassword({...}) → void
- validateSession() → bool
- checkUsernameExists(username) → bool
- getUserById(userId) → UserModel
```

### CourseProvider Methods
```
- loadCourses() → Future<void>
- loadCoursesBySemester(semesterId) → Future<void>
- loadCoursesForStudent(studentId) → Future<List<CourseModel>>
- loadCoursesForStudentBySemester(studentId, semesterId) → Future<List<CourseModel>>
- createCourse({...}) → Future<CourseModel>
- updateCourse(course) → Future<bool>
- deleteCourse(id, semesterId) → Future<bool>
- searchCourses(query) → void
- sortCourses(sortBy, ascending) → void
```

### AssignmentProvider Methods
```
- loadAssignments() → Future<void>
- loadAssignmentsForStudent(studentId) → Future<void>
- createAssignment({...}) → Future<AssignmentModel>
- updateAssignment(assignment) → Future<bool>
- deleteAssignment(id) → Future<bool>
- submitAssignment({...}) → Future<void>
- gradeSubmission({...}) → Future<bool>
```

---

## Context Dependency Injection

All providers and services are registered in `main.dart`:

### To Access in Screens:
```dart
// Read a service (no rebuild)
final authService = context.read<AuthService>();

// Watch a provider (rebuild on changes)
final courseProvider = context.watch<CourseProvider>();

// Read within async callback
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<SemesterProvider>();
});

// Multiple watch using Consumer
Consumer2<CourseProvider, AssignmentProvider>(
  builder: (context, courseProvider, assignmentProvider, child) {
    // Use both providers
  },
)
```

---

## Key Integration Points for Enhanced Homepage

### Data Sources for Each Section

| Section | Data Source | Provider/Service |
|---------|-------------|---|
| Welcome Card | AuthService.currentUser | AuthService |
| Semester Switcher | SemesterProvider.semesters | SemesterProvider |
| Course Cards | CourseProvider.courses | CourseProvider |
| Pending Assignments | AssignmentProvider | AssignmentProvider |
| Upcoming Deadlines | AssignmentProvider (filtered) | AssignmentProvider |
| Quick Stats | Multiple providers | CourseProvider + AssignmentProvider |
| Notifications Badge | NotificationProvider | NotificationProvider |
| Announcements | AnnouncementProvider | AnnouncementProvider |

---

## Performance Considerations

1. **Lazy Loading**: Load data only when needed
2. **Caching**: Hive provides offline caching
3. **Pagination**: Use itemsPerPage constant (20)
4. **Filtering**: Filter data locally before display
5. **Debouncing**: Search has 500ms debounce
6. **State Preservation**: IndexedStack keeps tab state

---

## Testing Credentials

### Admin (Instructor)
```
Username: admin
Password: admin
Role: instructor
Access: Full instructor features
```

### Students
- Username: Any student ID from Firestore
- Password: Student password from Firestore
- Role: student
- Access: Student features only

---

## Next Steps for Implementation

1. **Review** `/lib/screens/student/student_home_screen.dart`
2. **Examine** the providers and services needed
3. **Plan** additional state variables and methods
4. **Implement** loading methods in initState
5. **Build** new UI sections
6. **Test** with different roles and semesters
7. **Optimize** performance and error handling

