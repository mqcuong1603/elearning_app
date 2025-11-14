# Frontend - Quick Reference Guide

## Project Overview
- **Framework**: Flutter (Dart)
- **Architecture Pattern**: Provider + Service Layer
- **Backend**: Firebase (Firestore + Storage)
- **Status**: Forum & Messaging 85% complete (UI not integrated into navigation)

---

## File Locations Summary

### Forum Implementation
```
Core Files:
  lib/models/forum_topic_model.dart
  lib/models/forum_reply_model.dart
  lib/services/forum_service.dart
  lib/providers/forum_provider.dart
  
Screens:
  lib/screens/shared/forum/forum_list_screen.dart
  lib/screens/shared/forum/forum_topic_detail_screen.dart
  lib/screens/shared/forum/create_topic_screen.dart
```

### Messaging Implementation
```
Core Files:
  lib/models/message_model.dart
  lib/services/message_service.dart
  lib/providers/message_provider.dart
  
Screens:
  lib/screens/shared/messaging/conversations_list_screen.dart
  lib/screens/shared/messaging/chat_screen.dart
```

### Main Application Structure
```
Navigation Hub:
  lib/main.dart
  lib/screens/student/student_home_screen.dart
  lib/screens/instructor/instructor_dashboard_screen.dart
  lib/screens/shared/course_space_screen.dart

Configuration:
  lib/config/app_constants.dart
  lib/config/app_theme.dart
  lib/config/firebase_options.dart
```

---

## Key Firestore Collections

### Forum Topics
```
Collection: forum_topics
Schema:
{
  id: string (UUID)
  courseId: string
  title: string
  content: string
  authorId: string
  authorName: string
  authorRole: "instructor" | "student"
  attachments: []
  createdAt: timestamp
  updatedAt: timestamp
  replyCount: integer
  isPinned: boolean
}
```

### Forum Replies
```
Collection: forum_replies
Schema:
{
  id: string (UUID)
  topicId: string
  authorId: string
  authorName: string
  authorRole: "instructor" | "student"
  content: string
  attachments: []
  createdAt: timestamp
  parentReplyId?: string (for nested replies)
}
```

### Messages
```
Collection: messages
Schema:
{
  id: string (UUID)
  senderId: string
  senderName: string
  senderRole: "instructor" | "student"
  receiverId: string
  receiverName: string
  receiverRole: "instructor" | "student"
  content: string
  attachments: []
  isRead: boolean
  createdAt: timestamp
  readAt?: timestamp
}
```

---

## Service Layer API

### ForumService Methods
```dart
// Get all topics for a course
Future<List<ForumTopicModel>> getTopicsByCourse(String courseId)

// Get single topic by ID
Future<ForumTopicModel?> getTopicById(String topicId)

// Create new forum topic
Future<ForumTopicModel> createTopic({
  required String courseId,
  required String title,
  required String content,
  required String authorId,
  required String authorName,
  required String authorRole,
  List<PlatformFile>? attachmentFiles,
})

// Add reply to topic
Future<ForumReplyModel> createReply({
  required String topicId,
  required String content,
  required String authorId,
  required String authorName,
  required String authorRole,
  List<PlatformFile>? attachmentFiles,
})

// Pin/unpin topic (instructor only)
Future<void> pinTopic(String topicId, bool isPinned)

// Search topics
Future<List<ForumTopicModel>> searchTopics(String courseId, String query)

// Delete reply
Future<void> deleteReply(String replyId)
```

### MessageService Methods
```dart
// Get all messages for a user
Future<List<MessageModel>> getMessagesForUser(String userId)

// Get conversation between two users
Future<List<MessageModel>> getConversation(String userId1, String userId2)

// Get list of unique conversation partners
Future<List<Map<String, dynamic>>> getConversationsList(String userId)

// Send message
Future<MessageModel> sendMessage({
  required String senderId,
  required String senderName,
  required String senderRole,
  required String receiverId,
  required String receiverName,
  required String receiverRole,
  required String content,
  List<PlatformFile>? attachmentFiles,
})

// Mark message as read
Future<void> markAsRead(String messageId)

// Delete message (soft delete)
Future<void> deleteMessage(String messageId)

// Get unread count
Future<int> getUnreadCount(String userId)
```

---

## Provider API Usage

### ForumProvider
```dart
// Get provider
final provider = context.read<ForumProvider>();

// Properties
List<ForumTopicModel> get topics;
ForumTopicModel? get selectedTopic;
bool get isLoadingTopics;
String? get topicsError;
List<ForumReplyModel> get replies;
int get topicsCount;

// Methods
Future<void> loadTopicsByCourse(String courseId);
Future<void> loadTopicById(String topicId);
Future<ForumTopicModel?> createTopic({...});
Future<ForumReplyModel?> createReply({...});
Future<void> pinTopic(String topicId, bool isPinned);
void setSearchQuery(String query);
void clearTopicsError();
```

### MessageProvider
```dart
// Get provider
final provider = context.read<MessageProvider>();

// Properties
List<MessageModel> get messages;
List<MessageModel> get conversation;
List<Map<String, dynamic>> get conversationsList;
bool get isLoadingMessages;
bool get isLoadingConversations;
String? get error;
int get unreadCount;
int get messagesCount;
int get conversationsCount;

// Methods
Future<void> loadMessagesForUser(String userId);
Future<void> loadConversationsList(String userId);
Future<void> loadConversation(String userId1, String userId2);
Future<MessageModel?> sendMessage({...});
Future<void> markAsRead(String messageId);
Future<void> deleteMessage(String messageId);
```

---

## Navigation Examples

### Navigate to Forum
```dart
import 'package:elearning_app/screens/shared/forum/forum_list_screen.dart';

// Navigate to forum list for a specific course
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ForumListScreen(course: courseModel),
  ),
);
```

### Navigate to Messaging
```dart
import 'package:elearning_app/screens/shared/messaging/conversations_list_screen.dart';

// Navigate to conversations list
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ConversationsListScreen(),
  ),
);
```

### Navigate to Chat
```dart
import 'package:elearning_app/screens/shared/messaging/chat_screen.dart';

// Navigate to specific conversation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatScreen(
      partnerId: instructorId,
      partnerName: instructorName,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    ),
  ),
);
```

---

## Data Flow Example

### Creating a Forum Topic
```
1. UI (CreateTopicScreen) → User fills form
2. User taps "Submit"
3. CreateTopicScreen calls → ForumProvider.createTopic()
4. ForumProvider calls → ForumService.createTopic()
5. ForumService calls → FirestoreService.create()
6. FirestoreService writes to → Firestore DB
7. Also writes to → Hive (offline cache)
8. Response bubbles back up
9. ForumProvider updates state → topics list
10. Screen rebuilds with new topic
```

### Sending a Message
```
1. UI (ChatScreen) → User types message
2. User taps "Send"
3. ChatScreen calls → MessageProvider.sendMessage()
4. MessageProvider calls → MessageService.sendMessage()
5. MessageService calls → FirestoreService.create()
6. FirestoreService writes to → Firestore DB
7. Also writes to → Hive (offline cache)
8. MessageProvider updates state
9. Screen rebuilds with new message
```

---

## Current Integration Status

### Working ✅
- All service methods
- All provider state management
- All UI screens
- Database models & Firestore collections
- File upload/attachment support
- Offline caching via Hive

### Not Working ❌
- Navigation menu items for forum/messaging
- Links from StudentHomeScreen
- Course integration
- Instructor dashboard integration

### Files Needing Changes
To complete integration, modify:
1. `lib/screens/student/student_home_screen.dart` - Wire up forum tab
2. `lib/screens/shared/course_space_screen.dart` - Add forum/message tabs
3. `lib/screens/instructor/instructor_dashboard_screen.dart` - Add messaging access

---

## Testing Checklist

### Forum Features
- [ ] Create topic with title & content
- [ ] Upload attachment to topic
- [ ] View topic details
- [ ] Add reply to topic
- [ ] Pin topic (as instructor)
- [ ] Search topics
- [ ] Load topics for course

### Messaging Features
- [ ] Load conversations list
- [ ] View conversation with partner
- [ ] Send message
- [ ] Send message with attachment
- [ ] Mark message as read
- [ ] See unread count

### Integration
- [ ] Forum accessible from home screen
- [ ] Messaging accessible from home screen
- [ ] Forum accessible from course page
- [ ] Messaging accessible from course page
- [ ] Proper navigation back button

---

## Environment Setup

```yaml
# pubspec.yaml requirements

dependencies:
  flutter: ^3.0.0
  firebase_core: ^4.2.1
  cloud_firestore: ^6.1.0
  firebase_storage: ^13.0.4
  provider: ^6.1.2
  file_picker: ^10.3.6
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

---

## Useful Commands

```bash
# Run tests
flutter test

# Generate Hive adapters
dart run build_runner build

# Watch for changes
dart run build_runner watch

# Clean build
flutter clean
flutter pub get
flutter run

# Build APK
flutter build apk --release
```

---

## Documentation Files

- `FRONTEND_ARCHITECTURE_ANALYSIS.md` - Detailed architecture breakdown
- `FRONTEND_SUMMARY.md` - Visual diagrams and quick reference
- `FRONTEND_QUICK_REFERENCE.md` - This file

---

## Support Resources

### Models (with Hive serialization)
- ForumTopicModel: Fields, JSON conversion, Hive adapter
- ForumReplyModel: Reply structure with timestamps
- MessageModel: Sender/receiver info, read status

### Services (Firestore integration)
- Full CRUD operations
- Error handling & fallbacks
- File upload support
- Query optimization

### Providers (State management)
- ChangeNotifier pattern
- Loading states
- Error handling
- Data caching

### Screens (Material UI)
- Complete user flows
- Form validation
- Empty states
- Error handling
- Offline support

