# E-Learning App Architecture Overview & Notification System Implementation Guide

## Executive Summary

This is a **Flutter (Dart)** e-learning management system built with:
- **Backend**: Firebase (Firestore, Storage, Auth)
- **State Management**: Provider pattern
- **Offline Support**: Hive local database
- **Architecture**: Layered (Screens → Providers → Services → Firestore)

**Notification Model Already Exists**: The app has a well-designed `NotificationModel` but no service/provider yet to manage notifications.

---

## 1. FLUTTER PROJECT STRUCTURE

### Directory Layout
```
/home/user/elearning_app/lib/
├── config/
│   ├── app_constants.dart          # All constants (notification types, collections, etc.)
│   ├── app_theme.dart              # UI theming
│   └── firebase_options.dart        # Firebase config
│
├── models/                          # Data models (17 files)
│   ├── user_model.dart             # Student/Instructor users
│   ├── announcement_model.dart      # Announcements with comments
│   ├── assignment_model.dart        # Assignments with submissions
│   ├── quiz_model.dart              # Quizzes
│   ├── question_model.dart          # Quiz questions
│   ├── course_model.dart            # Courses
│   ├── group_model.dart             # Student groups
│   ├── message_model.dart           # Direct messages
│   ├── forum_topic_model.dart       # Forum topics
│   ├── forum_reply_model.dart       # Forum replies
│   └── notification_model.dart      # *** NOTIFICATION MODEL EXISTS ***
│
├── services/                        # Business logic (16 services, 8169 lines total)
│   ├── firestore_service.dart       # Generic CRUD operations
│   ├── auth_service.dart            # Authentication (admin + student login)
│   ├── storage_service.dart         # Firebase Storage file uploads
│   ├── hive_service.dart            # Local caching
│   ├── announcement_service.dart    # Announcements CRUD
│   ├── assignment_service.dart      # Assignments & submissions
│   ├── quiz_service.dart            # Quizzes management
│   ├── course_service.dart          # Courses & groups
│   ├── student_service.dart         # Student management
│   ├── message_service.dart         # Direct messaging
│   ├── forum_service.dart           # Forum topics/replies
│   ├── material_service.dart        # Study materials
│   └── ... (6 more services)
│
├── providers/                       # State management (10 providers)
│   ├── announcement_provider.dart
│   ├── assignment_provider.dart
│   ├── quiz_provider.dart
│   ├── course_provider.dart
│   ├── message_provider.dart
│   ├── forum_provider.dart
│   └── ... (4 more providers)
│
├── screens/
│   ├── auth/
│   │   └── login_screen.dart        # Login for admin/students
│   ├── instructor/
│   │   ├── instructor_dashboard_screen.dart
│   │   ├── create_course_screen.dart
│   │   ├── create_announcement_screen.dart
│   │   ├── create_assignment_screen.dart
│   │   ├── create_quiz_screen.dart
│   │   └── ... (more instructor screens)
│   ├── student/
│   │   ├── student_home_screen.dart  # 4-tab home (Home, Dashboard, Forum, Profile)
│   │   ├── course_space_screen.dart  # 3-tab course view (Stream, Classwork, People)
│   │   └── ... (more student screens)
│   └── shared/
│       ├── forum/
│       │   ├── forum_list_screen.dart
│       │   ├── forum_topic_detail_screen.dart
│       │   └── create_topic_screen.dart
│       └── messaging/
│           ├── conversations_list_screen.dart
│           └── chat_screen.dart
│
├── widgets/                         # Reusable UI components
├── utils/                           # Utility functions
└── main.dart                        # Entry point with MultiProvider setup

Total Dart Files: 70+ files
Total Services Code: 8,169 lines
```

### Key Architecture Pattern
```
Screens (UI)
    ↓ (context.read<>)
Providers (State Management with ChangeNotifier)
    ↓ (calls methods from)
Services (Business Logic)
    ↓ (queries/writes to)
Firestore Collections
    ↓ (offline backup)
Hive Local Database
```

---

## 2. CURRENT NOTIFICATION IMPLEMENTATION

### What Exists:

#### NotificationModel (/lib/models/notification_model.dart)
```dart
@HiveType(typeId: 14)  // Already registered with Hive
class NotificationModel extends HiveObject {
  String id;
  String userId;           // Who receives it
  String type;             // announcement, assignment, quiz, material, message, forum, grade, deadline
  String title;
  String message;
  String? relatedId;       // ID of related entity
  String? relatedType;     // Type of related entity
  bool isRead;
  DateTime createdAt;
  DateTime? readAt;
  Map<String, dynamic>? data;  // Additional flexible data
}
```

**Built-in Methods**:
- `icon` getter - Returns emoji based on type
- `isRecent` getter - Checks if within 24 hours
- `relativeTime` getter - Human-readable time ("2 hours ago")
- `toJson()` / `fromJson()` - Firestore serialization
- `copyWith()` - Immutable updates

#### AppConstants Already Defined
- `notificationTypeAnnouncement`
- `notificationTypeAssignment`
- `notificationTypeQuiz`
- `notificationTypeMaterial`
- `notificationTypeMessage`
- `notificationTypeForum`
- `notificationTypeGrade`
- `notificationTypeDeadline`
- Firebase collection: `collectionNotifications = 'notifications'`
- Hive box: `hiveBoxNotifications = 'notifications_box'`

### What's Missing:

**NO Service Layer**: No `NotificationService` exists
- No methods to create notifications
- No methods to fetch user notifications
- No real-time listener setup
- No notification triggering from announcements/assignments/quizzes

**NO Provider Layer**: No `NotificationProvider` for state management

**NO UI**: No notification UI screens/widgets

**NO Email Integration**: `mailer` package is in pubspec.yaml but not used

---

## 3. FIREBASE & FIRESTORE SETUP

### Firestore Collections Structure

```
Firestore Database
├── users/
│   └── {userId}
│       ├── id, username, fullName, email
│       ├── role: "instructor" | "student"
│       ├── studentId (only for students)
│       └── timestamps (createdAt, updatedAt)
│
├── courses/
│   └── {courseId}
│       ├── code, name, semesterId
│       ├── sessions (10 or 15)
│       ├── instructorId, instructorName
│       └── timestamps
│
├── semesters/
│   └── {semesterId}
│       ├── code, name
│       └── timestamps
│
├── groups/
│   └── {groupId}
│       ├── name, courseId
│       ├── studentIds: [list of student IDs]
│       └── timestamps
│
├── announcements/
│   └── {announcementId}
│       ├── courseId, title, content (rich text)
│       ├── attachments: [{id, url, filename, size, type}]
│       ├── groupIds (scope: which groups see it)
│       ├── instructorId, instructorName
│       ├── viewedBy: [userId list]
│       ├── downloadedBy: {attachmentId: [userId list]}
│       ├── comments: [{id, userId, content, createdAt}]
│       └── timestamps
│
├── assignments/
│   └── {assignmentId}
│       ├── courseId, title, description
│       ├── startDate, deadline, lateDeadline
│       ├── allowLateSubmission: boolean
│       ├── maxAttempts, allowedFileFormats, maxFileSize
│       ├── groupIds (scope)
│       ├── instructorId, instructorName
│       └── timestamps
│
├── assignment_submissions/
│   └── {submissionId}
│       ├── assignmentId, studentId
│       ├── fileUrl, filename, submittedAt
│       ├── grade, feedback
│       ├── isLate: boolean
│       └── timestamps
│
├── quizzes/
│   └── {quizId}
│       ├── courseId, title, description
│       ├── openDate, closeDate, durationMinutes
│       ├── maxAttempts
│       ├── questionStructure: {easy: 5, medium: 3, hard: 2}
│       ├── groupIds (scope)
│       ├── instructorId, instructorName
│       └── timestamps
│
├── questions/
│   └── {questionId}
│       ├── courseId, questionText
│       ├── difficulty: easy | medium | hard
│       ├── type: multiple_choice | short_answer | essay
│       ├── options: [for multiple choice]
│       ├── correctAnswer
│       └── timestamps
│
├── quiz_submissions/
│   └── {submissionId}
│       ├── quizId, studentId
│       ├── answers: [{questionId, answer, isCorrect}]
│       ├── score, grade
│       ├── status: in_progress | completed
│       └── timestamps
│
├── forum_topics/
│   └── {topicId}
│       ├── courseId, title, content
│       ├── authorId, authorName, authorRole
│       ├── attachments: [files]
│       ├── replyCount, isPinned: boolean
│       ├── readBy: [userId list]
│       └── timestamps
│
├── forum_replies/
│   └── {replyId}
│       ├── topicId, authorId, authorName
│       ├── content, attachments: [files]
│       └── timestamps
│
├── materials/
│   └── {materialId}
│       ├── courseId, title, description
│       ├── fileUrl, downloadCount
│       └── timestamps
│
├── messages/
│   └── {messageId}
│       ├── senderId, senderName, senderRole
│       ├── receiverId, receiverName, receiverRole
│       ├── content, attachments: [files]
│       ├── isRead: boolean, readAt: timestamp
│       └── timestamps
│
└── notifications/  ← **TARGET COLLECTION** (EMPTY - TO BE POPULATED)
    └── {notificationId}
        ├── userId, type, title, message
        ├── relatedId, relatedType
        ├── isRead: boolean, readAt: timestamp
        ├── data: {} (flexible additional data)
        └── timestamps
```

### Firebase Storage Structure
```
Firebase Storage
├── users/{userId}/
│   └── profile_images/
├── courses/{courseId}/
│   └── cover_images/
├── announcements/{announcementId}/
│   └── {attachmentId}
├── assignments/{assignmentId}/
│   ├── materials/
│   └── submissions/{studentId}/{submissionId}
├── materials/{materialId}/
├── messages/{messageId}/
└── forums/{topicId}/
```

### Real-Time Listeners Setup
The app uses Firestore's `.snapshots()` streams for real-time updates. See examples:
- `forum_service.dart` streams topics in real-time
- `message_service.dart` streams messages
- `announcement_service.dart` could stream announcements (not currently implemented)

---

## 4. STUDENT & INSTRUCTOR MODELS

### User Model (Single Model for Both)
**File**: `/lib/models/user_model.dart`

```dart
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  String id;                          // Firebase Auth UID
  String username;                    // Login username
  String fullName;                    // Display name
  String email;                       // Contact email
  String role;                        // "instructor" or "student"
  String? avatarUrl;                  // Profile picture
  String? studentId;                  // Only populated for students (e.g., "522i0001")
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? additionalInfo;  // Flexible extra fields
}

// Getter methods:
bool get isInstructor => role == 'instructor';
bool get isStudent => role == 'student';
String get displayName => fullName.isNotEmpty ? fullName : username;
```

### Student-Specific Relationships
```
User (role="student")
├── StudentId: "522i0001" (unique identifier for enrollment)
├── Groups: Stored in GroupModel.studentIds array
│   └── Groups can be queried via: groups where studentIds contains userId
├── Courses: Derived from groups
│   └── Course access = Any course whose groups contain this student
├── Enrollments: Implicit (no separate enrollment table)
│   └── Students auto-enrolled when added to a group
└── Email: Stored in user profile
```

### Instructor-Specific Relationships
```
User (role="instructor")
├── Courses: All courses where instructorId == userId
├── Authority: Can create/edit announcements, assignments, quizzes for their courses
├── Student Access: Can view all students in their courses
└── Email: Stored in user profile (for notification sending)
```

### How Groups Connect Students to Courses
```dart
GroupModel {
  id: "group-1"
  name: "Group A"
  courseId: "CS101"
  studentIds: ["user-123", "user-456", "user-789"]  // ← Student enrollment
  createdAt: ...
  updatedAt: ...
}

// To get all students in a course:
final groups = await groupService.getGroupsByCourse(courseId);
final allStudentIds = groups.expand((g) => g.studentIds).toSet();

// To get all courses for a student:
final groups = await groupService.getGroupsByStudent(studentId);
final courseIds = groups.map((g) => g.courseId).toSet();
```

---

## 5. AUTHENTICATION SETUP

### Authentication Service
**File**: `/lib/services/auth_service.dart`

#### Credential Methods:
1. **Hardcoded Admin Login**:
   - Username: `admin`
   - Password: `admin`
   - Auto-creates admin user with role="instructor"

2. **Student Login** (from Firestore):
   - Queries `users` collection for username match
   - Validates password (currently plain text in Firestore, should be hashed in production)
   - Default password for new students = their username

#### How It Works:
```dart
// Admin login
final user = await authService.login('admin', 'admin');
// Creates UserModel with id='admin', role='instructor'

// Student login
final user = await authService.login('student_username', 'password');
// Queries Firestore users collection
```

#### Session Management:
- Anonymous Firebase Auth sign-in for Storage access
- User object stored in memory (`_currentUser`)
- Session validation via `validateSession()` on app start
- No persistent session storage (logs out on app restart)

#### User Registration:
- Only instructors can create student accounts
- Instructor calls: `authService.registerStudent(...)`
- Creates user in Firestore with role="student"

### Current Auth Limitations:
- Passwords stored as plain text (should be hashed)
- Anonymous Firebase Auth (not proper user auth)
- No real session persistence
- No password hashing/salting

---

## 6. SERVICES & PROVIDERS ARCHITECTURE

### Services Layer (16 total)

#### Core Services:
1. **FirestoreService** (426 lines)
   - Generic CRUD operations
   - Query building with filters
   - Streaming (real-time listeners)
   - Batch operations
   - Used by: All domain services

2. **AuthService** (404 lines)
   - Login/Logout
   - User registration
   - Profile management
   - Session validation
   - Used by: Main app initialization

3. **StorageService** (775 lines)
   - File uploads to Firebase Storage
   - File deletion
   - Used by: Announcement, Assignment, Forum, Material services

4. **HiveService** (439 lines)
   - Local caching for offline support
   - Box management
   - Used by: All other services

#### Domain Services (Built on FirestoreService):

5. **AnnouncementService** (582 lines)
   - CRUD announcements
   - Filter by course/group/student
   - Track views and downloads
   - Manage comments
   - Real-time listening

6. **AssignmentService** (1007 lines - largest!)
   - CRUD assignments
   - Submission management
   - Grading
   - Track attempts
   - CSV export for submissions

7. **QuizService** (535 lines)
   - CRUD quizzes
   - Question selection
   - Submission management
   - Scoring

8. **CourseService** (491 lines)
   - CRUD courses
   - Link to semesters
   - Instructor assignment

9. **StudentService** (468 lines)
   - CRUD students (user creation)
   - Email validation
   - Student ID management
   - CSV import

10. **GroupService** (552 lines)
    - CRUD groups
    - Student enrollment/removal
    - Group membership queries
    - CSV import

11. **ForumService** (606 lines)
    - CRUD forum topics
    - CRUD forum replies
    - Topic pinning
    - Real-time listeners
    - Search/filtering

12. **MessageService** (457 lines)
    - Send messages
    - Mark as read
    - Conversation grouping
    - Real-time listeners
    - File attachments

13. **MaterialService** (417 lines)
    - CRUD study materials
    - File uploads
    - Download tracking

14. **QuestionService** (298 lines)
    - CRUD quiz questions
    - Question bank management
    - Difficulty distribution

15. **SemesterService** (381 lines)
    - CRUD semesters
    - Current semester tracking

16. **CsvService** (331 lines)
    - CSV parsing
    - Validation
    - Bulk import

### Providers Layer (10 total)

All follow same pattern:
```dart
class AnnouncementProvider extends ChangeNotifier {
  final AnnouncementService _announcementService;
  
  // State
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Methods
  Future<void> loadAnnouncements() async { ... }
  Future<void> createAnnouncement(...) async { ... }
  Future<void> updateAnnouncement(...) async { ... }
  Future<void> deleteAnnouncement(String id) async { ... }
  
  // Private helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

**10 Providers**:
1. SemesterProvider
2. CourseProvider
3. StudentProvider
4. GroupProvider
5. AnnouncementProvider
6. AssignmentProvider
7. MaterialProvider
8. QuizProvider
9. ForumProvider
10. MessageProvider

### Main Dependency Injection Setup
**File**: `/lib/main.dart`

Uses Provider's `MultiProvider` with:
- `Provider<Service>` for stateless services
- `ProxyProvider` for services that depend on other services
- `ChangeNotifierProxyProvider` for providers

```dart
MultiProvider(
  providers: [
    // Core services
    Provider<AuthService>(...),
    Provider<FirestoreService>(...),
    Provider<StorageService>(...),
    
    // Services that depend on core services
    ProxyProvider3<FirestoreService, HiveService, StorageService, 
        AnnouncementService>(...),
    
    // State management providers
    ChangeNotifierProxyProvider<AnnouncementService, AnnouncementProvider>(...),
  ],
  child: MaterialApp(...)
)
```

---

## 7. WHERE ANNOUNCEMENTS, ASSIGNMENTS & QUIZZES ARE CREATED/MANAGED

### Announcements

**Creation Flow**:
```
InstructorDashboardScreen
├── Click "Create Announcement" button
└── → CreateAnnouncementScreen
    ├── Input: title, content, attachments
    ├── Select: course, target groups
    └── Submit
        → AnnouncementService.createAnnouncement()
        → Firestore: announcements/{announcementId}
        → Notify students (WHERE NOTIFICATIONS SHOULD TRIGGER)

Firestore Collection: announcements/
Read Operations: AnnouncementService.getAnnouncementsByCourse(courseId)
Update Operations: AnnouncementService.updateAnnouncement(id, data)
Delete Operations: AnnouncementService.deleteAnnouncement(id)
Filtering: By course, by group, by student group membership
```

**Student View**:
```
StudentHomeScreen (Home tab)
→ Click course
→ CourseSpaceScreen (Stream tab)
→ Displays announcements via AnnouncementProvider
→ Can view, comment, download files
→ Track views (viewedBy array updated)
```

**Files Involved**:
- `/lib/screens/instructor/create_announcement_screen.dart` - Creation UI
- `/lib/services/announcement_service.dart` - Business logic
- `/lib/providers/announcement_provider.dart` - State management
- `/lib/models/announcement_model.dart` - Data model

---

### Assignments

**Creation Flow**:
```
InstructorDashboardScreen
├── Click "Create Assignment" button
└── → CreateAssignmentScreen
    ├── Input: title, description, attachments
    ├── Set: startDate, deadline, lateDeadline
    ├── Configure: maxAttempts, allowedFormats, maxFileSize
    ├── Select: course, target groups
    └── Submit
        → AssignmentService.createAssignment()
        → Firestore: assignments/{assignmentId}
        → Notify students (WHERE NOTIFICATIONS SHOULD TRIGGER)

Student Submission Flow:
StudentHomeScreen
→ CourseSpaceScreen (Classwork tab)
→ Click assignment
→ AssignmentDetailScreen
→ Click "Submit"
→ SubmitAssignmentScreen
  ├── Upload file
  └── Submit
    → AssignmentService.submitAssignment()
    → Firestore: assignment_submissions/{submissionId}
    → Notify instructor (WHERE NOTIFICATIONS SHOULD TRIGGER)

Grading Flow:
InstructorDashboardScreen
→ View Submissions
→ ReviewSubmissionScreen
  ├── View student file
  ├── Enter grade/feedback
  └── Submit grade
    → AssignmentService.gradeSubmission()
    → Update assignment_submissions/{submissionId}
    → Notify student (WHERE NOTIFICATIONS SHOULD TRIGGER)
```

**Firestore Collections**:
- `assignments/` - Assignment metadata
- `assignment_submissions/` - Student submissions
- `assignment_submissions/` subcollection tracking per assignment

**Files Involved**:
- `/lib/services/assignment_service.dart` (1007 lines - complex!)
- `/lib/providers/assignment_provider.dart`
- `/lib/models/assignment_model.dart`
- `/lib/models/assignment_submission_model.dart`
- `/lib/screens/instructor/create_assignment_screen.dart`
- `/lib/screens/student/assignment_detail_screen.dart`

---

### Quizzes

**Creation Flow**:
```
InstructorDashboardScreen
├── Click "Create Quiz" button
└── → CreateQuizScreen
    ├── Input: title, description
    ├── Set: openDate, closeDate, durationMinutes
    ├── Configure: maxAttempts, questionStructure
    │   └── Example: {easy: 5, medium: 3, hard: 2} = 10 total questions
    ├── Select: course, target groups
    └── Submit
        → QuizService.createQuiz()
        → Validates question bank has enough questions
        → Firestore: quizzes/{quizId}
        → Notify students (WHERE NOTIFICATIONS SHOULD TRIGGER)

Question Bank Setup (Prerequisite):
InstructorDashboardScreen
→ Manage Questions
→ AddQuestionScreen
  ├── Input: question text, options, correct answer
  ├── Set: difficulty (easy|medium|hard)
  └── Save
    → QuestionService.createQuestion()
    → Firestore: questions/{courseId}/{questionId}

Student Quiz Attempt:
StudentHomeScreen
→ CourseSpaceScreen (Classwork tab)
→ Click quiz
→ QuizDetailScreen
  ├── Shows status (upcoming|open|closed)
  ├── Click "Start Quiz"
  └── → QuizScreen
    ├── Questions randomly selected based on structure
    ├── Timer counts down
    ├── Submit answers
    └── Submission
        → QuizService.submitQuiz()
        → Firestore: quiz_submissions/{submissionId}
        → Auto-score (multiple choice)
        → Notify student with score (WHERE NOTIFICATIONS SHOULD TRIGGER)
```

**Firestore Collections**:
- `quizzes/` - Quiz metadata
- `questions/` - Question bank (global for course)
- `quiz_submissions/` - Student attempts

**Files Involved**:
- `/lib/services/quiz_service.dart` (535 lines)
- `/lib/services/question_service.dart` (298 lines)
- `/lib/providers/quiz_provider.dart`
- `/lib/models/quiz_model.dart`
- `/lib/models/question_model.dart`
- `/lib/models/quiz_submission_model.dart`
- `/lib/screens/instructor/create_quiz_screen.dart`
- `/lib/screens/student/quiz_detail_screen.dart`

---

## 8. EMAIL SERVICE INTEGRATION

### Current Status: **NOT IMPLEMENTED**

**Package Added** (in pubspec.yaml):
```yaml
mailer: ^6.1.0  # Email sending library
```

### Where to Add Email Integration

Email notifications should trigger when:

1. **New Announcement** → Email all students in target groups
2. **New Assignment** → Email all students in target groups
3. **Assignment Due Soon** → Email students (24-hour reminder)
4. **Assignment Graded** → Email student with grade/feedback
5. **Quiz Available** → Email all students in target groups
6. **Quiz Closes** → Email reminder
7. **New Message** → Email recipient (optional, can be in-app only)
8. **Forum Reply** → Email topic author (optional)

### Recommended Implementation

Create new service: `/lib/services/email_service.dart`

```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String _smtpServer = 'smtp.gmail.com';  // Or your email provider
  final int _smtpPort = 587;
  final String _senderEmail = 'your-app@gmail.com';
  final String _senderPassword = 'app-specific-password';  // Use env vars in production!
  
  // Method to send notification email
  Future<void> sendNotificationEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    required String notificationType,  // For template selection
  }) async {
    try {
      final smtpServer = gmail(_senderEmail, _senderPassword);
      
      final message = Message()
        ..from = Address(_senderEmail, 'E-Learning System')
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..html = _buildEmailTemplate(body, notificationType);
      
      await send(message, smtpServer);
      print('Email sent to $recipientEmail');
    } catch (e) {
      print('Error sending email: $e');
      // Don't crash the app if email fails
    }
  }
  
  String _buildEmailTemplate(String body, String type) {
    // Return styled HTML email
    return '''
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>E-Learning Notification</h2>
        <p>$body</p>
        <p><small>Please do not reply to this email.</small></p>
      </body>
    </html>
    ''';
  }
}
```

### Integration Points

Each service that creates actionable items should also trigger notifications:

```dart
// In AnnouncementService.createAnnouncement()
await _firestoreService.create(...);  // Create announcement

// NEW: Get all recipients
final recipientIds = getAllRecipientsForGroups(groupIds);

// NEW: Create notifications for each recipient
for (final recipientId in recipientIds) {
  final notification = NotificationModel(
    id: _uuid.v4(),
    userId: recipientId,
    type: 'announcement',
    title: announcement.title,
    message: announcement.content.substring(0, 100),
    relatedId: announcement.id,
    relatedType: 'announcement',
    isRead: false,
    createdAt: DateTime.now(),
  );
  
  await _firestoreService.create(
    collection: 'notifications',
    data: notification.toJson(),
  );
}

// NEW: Send emails if enabled
if (_preferences.emailNotificationsEnabled) {
  for (final recipientId in recipientIds) {
    final recipient = await _getUserById(recipientId);
    await _emailService.sendNotificationEmail(
      recipientEmail: recipient.email,
      subject: 'New Announcement: ${announcement.title}',
      body: announcement.content,
      notificationType: 'announcement',
    );
  }
}
```

---

## RECOMMENDED NOTIFICATION SYSTEM ARCHITECTURE

### What You Need to Build:

```
1. NotificationService (/lib/services/notification_service.dart)
   ├── Create notifications for users
   ├── Mark notifications as read
   ├── Get user notifications (paginated)
   ├── Stream user notifications (real-time)
   ├── Delete old notifications
   └── Send email notifications

2. NotificationProvider (/lib/providers/notification_provider.dart)
   ├── State: List<NotificationModel> notifications
   ├── State: int unreadCount
   ├── Methods: loadNotifications()
   ├── Methods: markAsRead()
   ├── Methods: streamNotifications()
   └── Real-time unread badge updates

3. Add to Main DI Setup (main.dart)
   ├── Register NotificationService
   ├── Register NotificationProvider
   └── Initialize real-time listeners on app start

4. Create Notification UI
   ├── NotificationBellIconWidget (unread badge)
   ├── NotificationsListScreen (full notifications page)
   ├── NotificationCard (individual notification display)
   └── Notification sound/vibration on receive

5. Hook into Trigger Points
   ├── In AnnouncementService.createAnnouncement()
   ├── In AssignmentService.submitAssignment()
   ├── In AssignmentService.gradeSubmission()
   ├── In QuizService.createQuiz()
   ├── In MessageService.sendMessage()
   ├── In ForumService.createTopic()
   ├── In ForumService.createReply()
   └── Other relevant operations

6. LocalNotifications Integration (flutter_local_notifications)
   └── Show local device notifications when app is open/closed
```

### Data Flow for Notifications

```
Event Triggered (e.g., new announcement)
  ↓
Service Method Called (AnnouncementService.createAnnouncement)
  ├─ Create announcement in Firestore
  └─ Create notification for each recipient
    ├─ Save to Firestore notifications/{notificationId}
    ├─ Trigger real-time update via .snapshots()
    ├─ NotificationProvider listener receives update
    ├─ UI updates automatically (unread badge, notification list)
    ├─ Show local notification (flutter_local_notifications)
    └─ Send email (EmailService) - async, non-blocking

User Opens App
  ↓
NotificationProvider initializes real-time stream
  ├─ Listens to: notifications where userId == currentUserId
  └─ Real-time updates as new notifications arrive

User Clicks Notification
  ├─ Mark as read in Firestore
  ├─ Navigation to related entity (announcement, assignment, etc.)
  └─ NotificationProvider updates state
```

---

## QUICK IMPLEMENTATION CHECKLIST

### Phase 1: Create Core Notification System (Week 1)
- [ ] Create NotificationService
- [ ] Create NotificationProvider
- [ ] Add real-time listener for user notifications
- [ ] Register in main.dart DI
- [ ] Create NotificationsListScreen UI
- [ ] Add notification bell icon to app bar

### Phase 2: Integrate Notification Triggers (Week 2)
- [ ] Hook into AnnouncementService
- [ ] Hook into AssignmentService (submit + grade)
- [ ] Hook into QuizService
- [ ] Hook into MessageService
- [ ] Hook into ForumService

### Phase 3: Local & Email Notifications (Week 3)
- [ ] Implement local device notifications
- [ ] Implement email service
- [ ] Add notification preferences to user settings
- [ ] Email templates for each notification type

### Phase 4: Polish & Testing (Week 4)
- [ ] Notification pagination for performance
- [ ] Notification archival/cleanup
- [ ] Testing with real Firestore data
- [ ] Performance optimization
- [ ] Analytics tracking

---

## FILE PATHS (ABSOLUTE) FOR QUICK REFERENCE

```
Models:
- /home/user/elearning_app/lib/models/notification_model.dart

Services:
- /home/user/elearning_app/lib/services/announcement_service.dart
- /home/user/elearning_app/lib/services/assignment_service.dart
- /home/user/elearning_app/lib/services/quiz_service.dart
- /home/user/elearning_app/lib/services/firestore_service.dart
- /home/user/elearning_app/lib/services/auth_service.dart

Providers:
- /home/user/elearning_app/lib/providers/announcement_provider.dart
- /home/user/elearning_app/lib/providers/assignment_provider.dart

Configuration:
- /home/user/elearning_app/lib/config/app_constants.dart
- /home/user/elearning_app/lib/main.dart

Entry Point:
- /home/user/elearning_app/lib/main.dart
```

