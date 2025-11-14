# E-Learning App Architecture - Quick Summary

## Key Findings at a Glance

### Project Type
- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore + Storage)
- **State Management**: Provider pattern
- **Offline Support**: Hive local database
- **Total Code**: 70+ Dart files, 8,169+ lines in services alone

### Architecture Layer
```
UI Screens → Providers (ChangeNotifier) → Services → Firestore/Hive
```

---

## 1. Project Structure

```
lib/
├── models/              (17 files) - Data structures
├── services/            (16 files) - Business logic  ← **KEY LAYER**
├── providers/           (10 files) - State management
├── screens/             (40+ files) - UI layer
│   ├── instructor/
│   ├── student/
│   ├── shared/
│   └── auth/
├── config/              - Constants & theme
├── widgets/             - Reusable components
└── main.dart            - Entry point with DI setup
```

---

## 2. Current Notification System

### GOOD NEWS: NotificationModel Already Exists!
- Location: `/lib/models/notification_model.dart`
- Hive-registered (typeId: 14)
- Has all necessary fields: userId, type, title, message, relatedId, isRead, createdAt, readAt
- Built-in helper methods (icon, relativeTime, isRecent)
- Firebase collection prepared: `notifications`

### MISSING: Service & Provider Layers
- NO NotificationService (for CRUD operations)
- NO NotificationProvider (for state management)
- NO real-time listener setup
- NO notification triggers in existing services
- NO UI screens

---

## 3. Firestore Collections

16 collections in Firestore:
- users, courses, semesters, groups
- announcements, assignments, assignment_submissions
- quizzes, questions, quiz_submissions
- forum_topics, forum_replies
- messages, materials
- notifications ← **EMPTY, TO BE POPULATED**

Each collection has read/write patterns established via services.

---

## 4. User Model

**Single model for both students and instructors:**
```dart
UserModel {
  id,              // User ID
  username,        // Login username
  fullName,        // Display name
  email,           // Email address
  role,            // "instructor" or "student"
  avatarUrl,
  studentId,       // Only for students (e.g., "522i0001")
  createdAt, updatedAt
}
```

**Student enrollment via Groups:**
```
GroupModel {
  courseId,
  studentIds: [userId, userId, ...]  ← Students enrolled here
}
```

---

## 5. Authentication

- **Admin Login**: Hardcoded (admin/admin)
- **Student Login**: From Firestore users collection
- **Passwords**: Currently plain text (should be hashed)
- **Session**: In-memory only, no persistence
- **Anonymous Auth**: Used for Storage access

---

## 6. Existing Services

### Core:
1. **FirestoreService** - Generic CRUD + queries + streaming
2. **AuthService** - Login, registration, session
3. **StorageService** - File uploads
4. **HiveService** - Local caching

### Domain (built on Firestore):
5. **AnnouncementService** - Announcement CRUD
6. **AssignmentService** - Largest service (1007 lines)
7. **QuizService** - Quiz management
8. **CourseService**, **StudentService**, **GroupService**
9. **MessageService**, **ForumService**
10. **MaterialService**, **QuestionService**
11. **SemesterService**, **CsvService**

### Pattern:
All services:
- Use FirestoreService for data access
- Use HiveService for caching
- Provide domain-specific CRUD + filtering
- Some use StorageService for files

---

## 7. Notification Trigger Points

### Where Notifications Should Be Created:

1. **Announcement Created**
   - File: `announcement_service.dart`
   - Method: `createAnnouncement()`
   - Recipients: All students in target groups
   - Type: `notificationTypeAnnouncement`

2. **Assignment Created**
   - File: `assignment_service.dart`
   - Method: `createAssignment()`
   - Recipients: All students in target groups
   - Type: `notificationTypeAssignment`

3. **Assignment Submitted**
   - File: `assignment_service.dart`
   - Method: `submitAssignment()`
   - Recipients: Instructor
   - Type: `notificationTypeAssignment`

4. **Assignment Graded**
   - File: `assignment_service.dart`
   - Method: `gradeSubmission()`
   - Recipients: Student who submitted
   - Type: `notificationTypeGrade`

5. **Quiz Created**
   - File: `quiz_service.dart`
   - Method: `createQuiz()`
   - Recipients: All students in target groups
   - Type: `notificationTypeQuiz`

6. **Quiz Submitted**
   - File: `quiz_service.dart`
   - Method: `submitQuiz()`
   - Recipients: Student (with score)
   - Type: `notificationTypeGrade`

7. **Message Sent**
   - File: `message_service.dart`
   - Method: `sendMessage()`
   - Recipients: Message receiver
   - Type: `notificationTypeMessage`

8. **Forum Topic Created/Replied**
   - File: `forum_service.dart`
   - Methods: `createTopic()`, `createReply()`
   - Recipients: Topic author (on reply), interested users
   - Type: `notificationTypeForum`

---

## 8. Email Service

### Current Status
- Package installed: `mailer: ^6.1.0`
- NOT USED anywhere in the codebase

### Implementation Needed
Create `/lib/services/email_service.dart` with:
- SMTP configuration
- Email templates for each notification type
- Methods to send emails async (don't block UI)

---

## What You Need to Build

### Phase 1: Notification Service & Provider (FOUNDATION)
```
1. NotificationService (/lib/services/notification_service.dart)
   - createNotification(userId, type, title, message, relatedId)
   - markAsRead(notificationId)
   - getNotifications(userId, limit)
   - streamNotifications(userId)  ← Real-time
   - deleteOldNotifications()

2. NotificationProvider (/lib/providers/notification_provider.dart)
   - State: List<NotificationModel> notifications
   - State: int unreadCount
   - Methods: loadNotifications(), markAsRead(), streamNotifications()
   - Real-time updates via provider listener

3. Register in main.dart
   - Add to MultiProvider
   - Initialize real-time listener on app startup
```

### Phase 2: Hook into Existing Services
Update these 8 services to trigger notifications:
- announcement_service.dart
- assignment_service.dart
- quiz_service.dart
- message_service.dart
- forum_service.dart
- (and others as needed)

### Phase 3: UI Components
- NotificationBellIcon (with unread badge)
- NotificationsListScreen (full list)
- NotificationCard (individual display)
- Navigate to related entity when clicked

### Phase 4: Email Integration
- EmailService with SMTP setup
- Templates for each notification type
- Async sending (non-blocking)
- User preferences for email notifications

---

## Critical Code Patterns to Follow

### Service Pattern
```dart
class YourNewService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  
  YourNewService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService;
}
```

### Provider Pattern
```dart
class YourNewProvider extends ChangeNotifier {
  final YourNewService _service;
  
  List<YourModel> _items = [];
  bool _isLoading = false;
  
  List<YourModel> get items => _items;
  bool get isLoading => _isLoading;
  
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _items = await _service.getItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Real-time Streaming
```dart
// In Service
Stream<List<T>> streamItems(String userId) {
  return _firestoreService.streamQuery(
    collection: 'items',
    filters: [QueryFilter(field: 'userId', isEqualTo: userId)],
  ).map((data) => data.map((json) => T.fromJson(json)).toList());
}

// In Provider
void initializeRealTimeListener(String userId) {
  _streamSubscription = _service.streamItems(userId).listen((items) {
    _items = items;
    notifyListeners();
  });
}
```

---

## Performance Considerations

1. **Pagination**: Don't load all notifications at once
2. **Caching**: Use Hive for offline support
3. **Real-time**: Use Firestore streams (already set up for Forum/Messages)
4. **Cleanup**: Archive/delete old notifications periodically
5. **Batch Operations**: For bulk notification creation
6. **Email**: Send async, don't block notification creation

---

## Firestore Security Rules

When implementing notifications, ensure Firestore rules allow:
- Users can read their own notifications
- Only services/functions can write notifications
- Consider adding admin dashboard for viewing all notifications

---

## Next Steps

1. Read full document: `NOTIFICATION_SYSTEM_ARCHITECTURE.md` (1017 lines)
2. Study existing services (AnnouncementService is a good example)
3. Study existing providers (AnnouncementProvider is a good template)
4. Create NotificationService first (foundation)
5. Create NotificationProvider (state management)
6. Add real-time listener in main.dart
7. Hook into announcement/assignment/quiz services
8. Build UI screens
9. Implement email integration

---

## Files to Create/Modify

### New Files
- `/lib/services/notification_service.dart` (150-200 lines)
- `/lib/providers/notification_provider.dart` (100-150 lines)
- `/lib/services/email_service.dart` (100-150 lines)
- `/lib/screens/notifications_screen.dart` (200-300 lines)
- `/lib/widgets/notification_card.dart` (50-100 lines)
- `/lib/widgets/notification_bell_icon.dart` (50-100 lines)

### Files to Modify
- `/lib/main.dart` (add service + provider registration)
- `/lib/services/announcement_service.dart` (add notification triggers)
- `/lib/services/assignment_service.dart` (add notification triggers)
- `/lib/services/quiz_service.dart` (add notification triggers)
- `/lib/services/message_service.dart` (add notification triggers)
- `/lib/services/forum_service.dart` (add notification triggers)
- Various screen files (add bell icon to app bar)

---

## Estimated Effort

- **Phase 1 (Service + Provider)**: 4-6 hours
- **Phase 2 (Hook triggers)**: 3-4 hours
- **Phase 3 (UI)**: 4-6 hours
- **Phase 4 (Email + Polish)**: 4-6 hours
- **Total**: 15-22 hours for complete system

