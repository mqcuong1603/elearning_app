# Frontend Architecture - Quick Summary

## Framework: Flutter (Dart)

### Current Status of Forum & Messaging:
```
✅ BACKEND IMPLEMENTATION: Complete
  - Database models with Firestore collections
  - Services with full CRUD operations
  - State management with Providers
  - UI screens fully built

❌ FRONTEND INTEGRATION: Incomplete
  - Not wired into main navigation
  - Not accessible from student home
  - Not integrated into course space
```

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                   FLUTTER APP (Dart)                │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │         SCREENS (UI Layer)                    │  │
│  │  ├─ StudentHomeScreen (4 tabs)                │  │
│  │  │  ├─ Home Tab                               │  │
│  │  │  ├─ Dashboard Tab                          │  │
│  │  │  ├─ Forum Tab (Placeholder - NOT WIRED)   │  │
│  │  │  └─ Profile Tab                            │  │
│  │  ├─ CourseSpaceScreen (3 tabs)               │  │
│  │  │  ├─ Stream (Announcements)                │  │
│  │  │  ├─ Classwork (Assignments/Quizzes)       │  │
│  │  │  └─ People (Groups/Students)              │  │
│  │  ├─ ForumListScreen ✅                        │  │
│  │  ├─ ForumTopicDetailScreen ✅                │  │
│  │  ├─ CreateTopicScreen ✅                     │  │
│  │  ├─ ConversationsListScreen ✅               │  │
│  │  └─ ChatScreen ✅                            │  │
│  └──────────────────────────────────────────────┘  │
│           ↓ Uses (context.read<>)                   │
│  ┌──────────────────────────────────────────────┐  │
│  │      PROVIDERS (State Management)             │  │
│  │  - ForumProvider ✅                           │  │
│  │  - MessageProvider ✅                         │  │
│  │  - CourseProvider ✅                          │  │
│  │  - AnnouncementProvider ✅                    │  │
│  │  - AssignmentProvider ✅                      │  │
│  │  - + 5 more providers                         │  │
│  └──────────────────────────────────────────────┘  │
│           ↓ Calls methods from                      │
│  ┌──────────────────────────────────────────────┐  │
│  │         SERVICES (Business Logic)             │  │
│  │  - ForumService ✅                            │  │
│  │  - MessageService ✅                          │  │
│  │  - CourseService ✅                           │  │
│  │  - FirestoreService (Raw API)                │  │
│  │  - StorageService (File uploads)             │  │
│  │  - + 11 more services                        │  │
│  └──────────────────────────────────────────────┘  │
│           ↓ Queries & Writes                       │
│  ┌──────────────────────────────────────────────┐  │
│  │         FIREBASE COLLECTIONS                 │  │
│  │  - forum_topics ✅                            │  │
│  │  - forum_replies ✅                           │  │
│  │  - messages ✅                                │  │
│  │  - courses, users, assignments, etc          │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  OFFLINE SUPPORT: Hive caching layer (local DB)   │
└─────────────────────────────────────────────────────┘
```

---

## Forum Component Overview

### Files Location:
```
lib/
├── models/forum_topic_model.dart       [Data structure]
├── models/forum_reply_model.dart       [Comment structure]
├── services/forum_service.dart         [Business logic]
├── providers/forum_provider.dart       [State management]
└── screens/shared/forum/
    ├── forum_list_screen.dart          [Topic list]
    ├── forum_topic_detail_screen.dart  [Topic + replies]
    └── create_topic_screen.dart        [Create new topic]
```

### Features:
```
✅ Create forum topics with attachments
✅ Reply to topics (nested comments)
✅ Pin important topics (instructor only)
✅ Search & filter topics
✅ File uploads support
✅ Offline caching via Hive
✅ Read/unread tracking
✅ Author role display (instructor/student)
```

### Database Schema:
```
forum_topics {
  id: string
  courseId: string           [Links to course]
  title: string
  content: string
  authorId: string
  authorName: string
  authorRole: "instructor" | "student"
  attachments: []            [Files]
  createdAt: timestamp
  updatedAt: timestamp
  replyCount: int
  isPinned: boolean
}

forum_replies {
  id: string
  topicId: string            [Links to parent topic]
  authorId: string
  content: string
  attachments: []            [Files]
  createdAt: timestamp
}
```

---

## Messaging Component Overview

### Files Location:
```
lib/
├── models/message_model.dart           [Message structure]
├── services/message_service.dart       [Business logic]
├── providers/message_provider.dart     [State management]
└── screens/shared/messaging/
    ├── conversations_list_screen.dart  [All conversations]
    └── chat_screen.dart                [1-to-1 chat]
```

### Features:
```
✅ Direct messaging (Student ↔ Instructor)
✅ Conversation grouping (many messages = 1 conversation)
✅ Unread count tracking
✅ Read receipts (readAt timestamp)
✅ Message attachments support
✅ File uploads & storage
✅ Last message preview in list
✅ Offline caching via Hive
```

### Database Schema:
```
messages {
  id: string
  senderId: string           [Who sent]
  senderName: string
  senderRole: "instructor" | "student"
  receiverId: string         [Who received]
  receiverName: string
  receiverRole: "instructor" | "student"
  content: string
  attachments: []            [Files]
  isRead: boolean
  createdAt: timestamp
  readAt: timestamp?         [When was it read]
}
```

---

## Current Navigation Flow

### Students:
```
┌─────────────────────────────┐
│  SplashScreen               │
│  (Check if logged in)       │
└──────────────┬──────────────┘
               │
        ┌──────▼──────┐
        │  Login      │◄─────────┐
        └──────┬──────┘          │
               │                 │
        ┌──────▼────────────────┐│
        │ StudentHomeScreen     ││
        │ BottomNavBar (4 tabs)  ││
        ├─────────────────────┤ ││
        │ 0. Home             │ ││
        │    ├─ My Courses    │ ││
        │    └─ CourseCard ──┐│ ││
        │                    │ │ │
        │ 1. Dashboard       │ │ │
        │    └─ Stats        │ │ │
        │                    │ │ │
        │ 2. Forum ⚠️         │ │ │
        │    └─ Coming Soon  │ │ │
        │    (NOT WIRED UP)  │ │ │
        │                    │ │ │
        │ 3. Profile         │ │ │
        │    └─ User Info    │ │ │
        └────────┬───────────┘ │ │
                 │             │ │
                 └─────────────┘ │
                 │               │
            ┌────▼──────────────┐│
            │ CourseSpaceScreen ││
            │ TabBar (3 tabs)   ││
            ├──────────────────┤│
            │ 0. Stream        ││
            │    └─ Announc.   ││
            │                  ││
            │ 1. Classwork     ││
            │    ├─ Assignments││
            │    ├─ Quizzes    ││
            │    └─ Materials  ││
            │                  ││
            │ 2. People        ││
            │    └─ Groups     ││
            │                  ││
            │ NO FORUM/MESSAGE  ││
            │ TABS HERE YET ⚠️   ││
            └──────────────────┘│
                   Logout ──────┘
```

### Forum Screens (Not Wired):
```
ForumListScreen
  ├─ [Topic 1]
  │  └─ TAP → ForumTopicDetailScreen
  │         └─ Replies
  │         └─ Reply button → Reply compose
  ├─ [Topic 2]
  └─ FAB to Create → CreateTopicScreen

These exist but are NOT accessible from main navigation!
```

### Messaging Screens (Not Wired):
```
ConversationsListScreen
  ├─ [User 1] (3 unread)
  │  └─ TAP → ChatScreen (with User 1)
  │        └─ Messages
  │        └─ Compose box
  ├─ [User 2] (0 unread)
  │  └─ TAP → ChatScreen (with User 2)
  └─ Last message preview shown

These exist but are NOT accessible from main navigation!
```

---

## Integration Roadmap

### Phase 1: Wire up existing screens (CURRENT NEED)
```
1. Replace forum placeholder in StudentHomeScreen
   └─ Button → ForumListScreen or CourseSelector → ForumListScreen

2. Add messaging access
   └─ New BottomNavBar tab OR menu drawer option
   └─ Navigate to ConversationsListScreen

3. Add course context
   └─ ForumListScreen receives courseId
   └─ Filter topics by course
```

### Phase 2: Course-level integration
```
1. Add Forum & Messages tabs to CourseSpaceScreen
   └─ Change TabBar from 3 to 5 tabs
   └─ Add forum_topics & messages tabs

2. Course-specific filtering
   └─ Show only topics for this course
   └─ Show only messages in this course context
```

### Phase 3: Instructor enhancements
```
1. Add messaging dashboard
   └─ Quick access to student messages
   └─ Unread count badge

2. Forum moderation
   └─ Pin/unpin topics
   └─ Delete topics/replies
   └─ Moderator actions
```

---

## What Works Right Now

### Forum ✅
- Firestore integration complete
- Models & adapters ready
- Service methods working
- Provider state management ready
- UI screens built and tested
- File attachment support
- Search & filtering
- Topic pinning

### Messaging ✅
- Firestore integration complete
- Models & adapters ready
- Service methods working
- Provider state management ready
- UI screens built and tested
- File attachment support
- Conversation grouping
- Unread tracking

### What's Missing ❌
- **UI Navigation**: Screens not wired into main app navigation
- **Integration**: Not accessible from StudentHomeScreen
- **Course Context**: Need to pass courseId to forum
- **User Experience**: No entry point for messaging

---

## Quick File References

### To Access Forum:
```dart
// Import
import 'screens/shared/forum/forum_list_screen.dart';

// Navigate
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ForumListScreen(course: courseModel),
  ),
);
```

### To Access Messaging:
```dart
// Import
import 'screens/shared/messaging/conversations_list_screen.dart';

// Navigate
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ConversationsListScreen(),
  ),
);
```

### Key Provider Usage:
```dart
// Forum
final forumProvider = context.read<ForumProvider>();
await forumProvider.loadTopicsByCourse(courseId);
final topics = forumProvider.topics;

// Messaging
final messageProvider = context.read<MessageProvider>();
await messageProvider.loadConversationsList(userId);
final conversations = messageProvider.conversationsList;
```

---

## Bottom Line

**Status**: 85% Complete ✅✅✅✅❌

- Backend/Services: 100% ✅
- Database Models: 100% ✅
- State Management: 100% ✅
- UI Screens: 100% ✅
- Navigation Integration: 0% ❌

**To finish**: Just need to wire up the screens into the main app navigation!
