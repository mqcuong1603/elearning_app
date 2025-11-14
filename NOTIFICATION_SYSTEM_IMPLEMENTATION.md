# Notification System Implementation

## Overview
This document describes the complete notification system implementation for the E-Learning application, including email notifications and deadline monitoring.

## Components Implemented

### 1. Email Service Configuration
**File:** `lib/main.dart`

The SMTP email service has been configured with the following settings:
- **SMTP Host:** smtp.gmail.com
- **SMTP Port:** 587 (TLS)
- **Sender Email:** cuongcfvipss4@gmail.com
- **Sender Password:** vspazecbnujrpwev
- **Sender Name:** E-Learning System

The email service is initialized in two places:
1. In the `main()` function for early initialization
2. As a Provider for dependency injection throughout the app

### 2. Services and Providers Registered

#### Services Added to Main.dart:
- **EmailService:** Handles sending emails via SMTP
- **NotificationService:** Manages in-app notifications (Firestore + Hive)
- **DeadlineMonitoringService:** Monitors deadlines and sends notifications

#### Providers Added to Main.dart:
- **NotificationProvider:** State management for notifications with real-time updates
- **DeadlineMonitoringService:** Auto-starts monitoring when app launches

### 3. Notification Triggers

#### QuizService Integration
**File:** `lib/services/quiz_service.dart`

**Triggers added:**
1. **Quiz Creation** (Line 89-114):
   - Sends notifications to all students in assigned groups
   - Notification includes quiz title, open date, and close date
   - Related data includes courseId, quizTitle, openDate, closeDate

2. **Quiz Submission** (Line 360-380):
   - Sends confirmation notification to student
   - Includes score and submission details
   - Related data includes quizTitle, score, attemptNumber, submittedAt

**Helper Method:**
- `_getStudentIdsFromGroups()` (Line 596-619): Fetches student IDs from group documents

#### MessageService Integration
**File:** `lib/services/message_service.dart`

**Triggers added:**
1. **New Message** (Line 240-259):
   - Sends notification to message receiver
   - Truncates long messages to 100 characters
   - Includes sender information and conversation ID
   - Related data includes senderId, senderName, conversationId

### 4. Notification Bell Icon Widget
**File:** `lib/widgets/notification_bell_icon.dart`

**Features:**
- Displays bell icon with customizable color and size
- Shows red badge with unread count
- Badge displays "99+" for counts over 99
- Uses Consumer pattern to listen to NotificationProvider
- Accepts onTap callback for navigation

**Usage Example:**
```dart
NotificationBellIcon(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen()),
    );
  },
  iconColor: Colors.white,
  iconSize: 28.0,
)
```

### 5. Notifications List Screen
**File:** `lib/screens/common/notifications_screen.dart`

**Features:**
- Real-time notification updates using StreamBuilder
- Filter notifications by type (all, announcement, assignment, quiz, message, grade, deadline)
- Toggle to show unread notifications only
- Mark individual notification as read
- Mark all notifications as read
- Delete individual notification (swipe to dismiss)
- Delete all notifications
- Pull-to-refresh functionality
- Color-coded notification types
- Relative time display ("2 hours ago", etc.)
- Empty state UI for no notifications

**Filters Available:**
- All Notifications
- Announcements
- Assignments
- Quizzes
- Messages
- Grades
- Deadlines

### 6. Deadline Monitoring Service
**File:** `lib/services/deadline_monitoring_service.dart`

**Features:**
- Automatically monitors assignment and quiz deadlines
- Checks every 1 hour for approaching deadlines
- Sends notifications at 24h, 12h, 6h, and 3h before deadline
- Only notifies students who haven't submitted/completed
- Sends both in-app notifications and emails
- Handles both assignments and quizzes

**Notification Thresholds:**
- 24 hours before deadline
- 12 hours before deadline
- 6 hours before deadline
- 3 hours before deadline

**Logic:**
1. Queries Firestore for items with deadlines in next 24 hours
2. For each item, identifies students who need to be notified
3. Checks if current time matches notification threshold
4. Sends in-app notification to all relevant students
5. Sends email if email service is configured and student has email

**Methods:**
- `startMonitoring()`: Begins periodic deadline checks
- `stopMonitoring()`: Stops deadline monitoring
- `_checkAssignmentDeadlines()`: Checks assignment deadlines
- `_checkQuizDeadlines()`: Checks quiz deadlines
- `_getStudentsWithoutSubmission()`: Finds students who haven't submitted
- `_getStudentsWithoutQuizSubmission()`: Finds students who haven't completed quiz
- `_getStudentsInGroups()`: Retrieves student details from groups

## Email Templates

The EmailService includes the following email templates:

### 1. Announcement Email
- Subject: [Course Name] New Announcement: {Title}
- Includes announcement content with HTML formatting

### 2. Assignment Deadline Email
- Subject: ⏰ [Course Name] Assignment Deadline Approaching: {Title}
- Displays hours remaining and deadline date/time

### 3. Quiz Deadline Email
- Subject: ⏰ [Course Name] Quiz Deadline Approaching: {Title}
- Displays hours remaining and deadline date/time

### 4. Assignment Submission Confirmation
- Subject: ✅ [Course Name] Assignment Submitted: {Title}
- Confirms submission with timestamp

### 5. Quiz Submission Confirmation
- Subject: ✅ [Course Name] Quiz Submitted: {Title}
- Confirms submission with score if available

### 6. Feedback/Grade Email
- Subject: ⭐ [Course Name] You received feedback on: {Title}
- Displays grade and instructor feedback

## Integration Points

### To Use Notifications in Your App:

#### 1. Add Notification Bell to AppBar
```dart
AppBar(
  title: Text('My Screen'),
  actions: [
    NotificationBellIcon(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationsScreen()),
        );
      },
    ),
  ],
)
```

#### 2. Initialize Notifications for a User
```dart
// In your screen's initState or didChangeDependencies
final authService = context.read<AuthService>();
final userId = authService.currentUserId;
if (userId != null) {
  context.read<NotificationProvider>().initializeRealTimeListener(userId);
}
```

#### 3. Set Notification Service in Other Services
To enable notification triggers in QuizService and MessageService, you need to inject NotificationService:

```dart
// Example: After creating QuizService
final quizService = context.read<QuizService>();
final notificationService = context.read<NotificationService>();
quizService.setNotificationService(notificationService);

// Same for MessageService
final messageService = context.read<MessageService>();
messageService.setNotificationService(notificationService);
```

**Note:** This should be done once during app initialization, preferably in the SplashScreen or main dashboard after user login.

## Testing Checklist

### Manual Testing Steps:

#### 1. Email Configuration Test
- [ ] App starts without errors
- [ ] Check console logs for "Email service configured successfully"

#### 2. Quiz Notifications Test
- [ ] Create a new quiz as instructor
- [ ] Check that students in assigned groups receive in-app notification
- [ ] Verify notification appears in NotificationsScreen
- [ ] Verify unread badge appears on notification bell icon

#### 3. Quiz Submission Test
- [ ] Submit a quiz as student
- [ ] Verify student receives submission confirmation notification
- [ ] Check that score is included in notification

#### 4. Message Notifications Test
- [ ] Send a message from instructor to student (or vice versa)
- [ ] Verify receiver gets notification
- [ ] Check that message preview appears in notification

#### 5. Notifications Screen Test
- [ ] Open NotificationsScreen
- [ ] Verify real-time updates work (create new notification and see it appear)
- [ ] Test filter by type (assignments, quizzes, messages, etc.)
- [ ] Test "show unread only" toggle
- [ ] Mark individual notification as read
- [ ] Mark all as read
- [ ] Swipe to delete notification
- [ ] Delete all notifications

#### 6. Deadline Monitoring Test
- [ ] Create assignment with deadline in next 24 hours
- [ ] Wait for hourly check (or adjust check interval for faster testing)
- [ ] Verify students receive deadline notification
- [ ] Check that students who already submitted don't receive notification
- [ ] Verify email is sent (check spam folder)

#### 7. Unread Badge Test
- [ ] Create multiple notifications for a user
- [ ] Verify badge count is correct
- [ ] Mark some as read, verify badge count decreases
- [ ] Mark all as read, verify badge disappears

## Database Structure

### Firestore Collection: `notifications`
```
notifications/{notificationId}
  - id: string
  - userId: string
  - type: string (announcement, assignment, quiz, material, message, forum, grade, deadline)
  - title: string
  - message: string
  - relatedId: string (optional)
  - relatedType: string (optional)
  - isRead: boolean
  - createdAt: string (ISO8601)
  - readAt: string (ISO8601, optional)
  - data: map (additional data)
```

### Recommended Firestore Indexes
For optimal performance, create these composite indexes:

1. **User notifications query:**
   - Collection: `notifications`
   - Fields: `userId` (Ascending), `createdAt` (Descending)

2. **Unread notifications query:**
   - Collection: `notifications`
   - Fields: `userId` (Ascending), `isRead` (Ascending)

## Performance Considerations

1. **Hive Caching:** Notifications are cached locally using Hive for offline access
2. **Real-time Updates:** Uses Firestore streams for instant notification delivery
3. **Batch Operations:** Bulk notification creation uses Firestore batch writes
4. **Deadline Monitoring:** Runs every hour to minimize database queries
5. **Email Async:** Emails are sent asynchronously to avoid blocking the UI

## Security Considerations

**IMPORTANT:** The SMTP credentials are currently hardcoded in the source code. For production:

1. **Move credentials to environment variables or secure configuration**
2. **Use Firebase Cloud Functions for email sending** (recommended)
3. **Implement rate limiting** to prevent email spam
4. **Add email verification** before sending to student emails
5. **Encrypt sensitive data** in Hive cache

## Future Enhancements

1. **Push Notifications:** Integrate Firebase Cloud Messaging for mobile push notifications
2. **Notification Preferences:** Allow users to customize which notifications they receive
3. **Notification Channels:** Group notifications by importance/priority
4. **Rich Notifications:** Add images, actions, and deep links
5. **Notification Analytics:** Track delivery and read rates
6. **Email Templates:** Move templates to Firestore for easy editing
7. **Scheduled Notifications:** Allow instructors to schedule notifications
8. **Notification Sound:** Add custom sounds for different notification types

## Troubleshooting

### Notifications not appearing:
1. Check that NotificationProvider is initialized with correct userId
2. Verify Firestore rules allow read/write to notifications collection
3. Check console logs for errors
4. Ensure real-time listener is started in screen's initState

### Emails not sending:
1. Verify SMTP credentials are correct
2. Check "Less secure app access" is enabled for Gmail account (or use App Password)
3. Check spam folder
4. Review console logs for email errors
5. Verify email service is configured: `emailService.isConfigured`

### Deadline notifications not working:
1. Check DeadlineMonitoringService is started (look for console log)
2. Verify check interval allows enough time for testing
3. Ensure assignments/quizzes have deadlines in the future
4. Check that students are properly assigned to groups
5. Verify Firestore date queries are working correctly

### Badge count incorrect:
1. Force refresh NotificationProvider
2. Check Hive cache is synchronized with Firestore
3. Verify stream subscription is active
4. Clear app data and restart

## Files Modified/Created

### Modified Files:
1. `lib/main.dart` - Added services and providers
2. `lib/services/quiz_service.dart` - Added notification triggers
3. `lib/services/message_service.dart` - Added notification triggers

### Created Files:
1. `lib/services/notification_service.dart` - Core notification service
2. `lib/services/email_service.dart` - Email sending service
3. `lib/services/deadline_monitoring_service.dart` - Deadline monitoring
4. `lib/providers/notification_provider.dart` - Notification state management
5. `lib/widgets/notification_bell_icon.dart` - Notification bell widget
6. `lib/screens/common/notifications_screen.dart` - Notifications list screen
7. `lib/models/notification_model.dart` - Notification data model
8. `lib/models/notification_model.g.dart` - Generated Hive adapter

## Conclusion

The notification system is now fully integrated into the E-Learning application with:
- ✅ Email service configured
- ✅ Notification triggers in QuizService and MessageService
- ✅ Notification bell icon with unread badge
- ✅ Notifications list screen with filtering
- ✅ Deadline monitoring service
- ✅ All services and providers registered

The system is ready for testing and deployment!
