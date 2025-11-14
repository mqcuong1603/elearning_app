import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'config/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/hive_service.dart';
import 'services/csv_service.dart';
import 'services/semester_service.dart';
import 'services/course_service.dart';
import 'services/student_service.dart';
import 'services/group_service.dart';
import 'services/announcement_service.dart';
import 'services/assignment_service.dart';
import 'services/material_service.dart';
import 'services/quiz_service.dart';
import 'services/question_service.dart';
import 'services/forum_service.dart';
import 'services/message_service.dart';
import 'services/notification_service.dart';
import 'services/email_service.dart';
import 'services/deadline_monitoring_service.dart';
import 'providers/semester_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/course_provider.dart';
import 'providers/student_provider.dart';
import 'providers/group_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/material_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/forum_provider.dart';
import 'providers/message_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/instructor/instructor_dashboard_screen.dart';
import 'screens/student/student_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase (check if not already initialized)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized');
    }

    // Initialize Hive for offline caching
    await HiveService.instance.initialize();
    print('Hive initialized successfully');

    // Configure Email Service for notifications
    final emailService = EmailService();
    emailService.configureSMTP(
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      senderEmail: 'cuongcfvipss4@gmail.com',
      senderPassword: 'vspazecbnujrpwev',
      senderName: 'E-Learning System',
    );
    print('Email service configured successfully');
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<HiveService>(
          create: (_) => HiveService.instance,
        ),
        Provider<CsvService>(
          create: (_) => CsvService(),
        ),
        Provider<EmailService>(
          create: (_) {
            final emailService = EmailService();
            emailService.configureSMTP(
              smtpHost: 'smtp.gmail.com',
              smtpPort: 587,
              senderEmail: 'cuongcfvipss4@gmail.com',
              senderPassword: 'vspazecbnujrpwev',
              senderName: 'E-Learning System',
            );
            return emailService;
          },
        ),
        ProxyProvider2<FirestoreService, HiveService, SemesterService>(
          update: (_, firestoreService, hiveService, __) => SemesterService(
            firestoreService: firestoreService,
            hiveService: hiveService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, AuthService,
            CourseService>(
          update: (_, firestoreService, hiveService, authService, __) =>
              CourseService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            authService: authService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, AuthService,
            StudentService>(
          update: (_, firestoreService, hiveService, authService, __) =>
              StudentService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            authService: authService,
          ),
        ),
        ProxyProvider2<FirestoreService, HiveService, GroupService>(
          update: (_, firestoreService, hiveService, __) => GroupService(
            firestoreService: firestoreService,
            hiveService: hiveService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, StorageService,
            AnnouncementService>(
          update: (_, firestoreService, hiveService, storageService, __) =>
              AnnouncementService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            storageService: storageService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, StorageService,
            AssignmentService>(
          update: (_, firestoreService, hiveService, storageService, __) =>
              AssignmentService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            storageService: storageService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, StorageService,
            MaterialService>(
          update: (_, firestoreService, hiveService, storageService, __) =>
              MaterialService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            storageService: storageService,
          ),
        ),
        Provider<QuizService>(
          create: (_) => QuizService(),
        ),
        Provider<QuestionService>(
          create: (_) => QuestionService(),
        ),
        ProxyProvider3<FirestoreService, HiveService, StorageService,
            ForumService>(
          update: (_, firestoreService, hiveService, storageService, __) =>
              ForumService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            storageService: storageService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, StorageService,
            MessageService>(
          update: (_, firestoreService, hiveService, storageService, __) =>
              MessageService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            storageService: storageService,
          ),
        ),
        ProxyProvider2<FirestoreService, HiveService, NotificationService>(
          update: (_, firestoreService, hiveService, __) => NotificationService(
            firestoreService: firestoreService,
            hiveService: hiveService,
          ),
        ),
        ProxyProvider2<NotificationService, EmailService, DeadlineMonitoringService>(
          update: (_, notificationService, emailService, previous) {
            if (previous != null) {
              return previous;
            }
            final service = DeadlineMonitoringService(
              notificationService: notificationService,
              emailService: emailService,
            );
            // Start monitoring deadlines
            service.startMonitoring();
            return service;
          },
          dispose: (_, service) => service.dispose(),
        ),

        // Providers (State Management)
        ChangeNotifierProxyProvider<SemesterService, SemesterProvider>(
          create: (context) => SemesterProvider(
            semesterService: context.read<SemesterService>(),
          ),
          update: (_, semesterService, previous) =>
              previous ?? SemesterProvider(semesterService: semesterService),
        ),
        ChangeNotifierProxyProvider<CourseService, CourseProvider>(
          create: (context) => CourseProvider(
            courseService: context.read<CourseService>(),
          ),
          update: (_, courseService, previous) =>
              previous ?? CourseProvider(courseService: courseService),
        ),
        ChangeNotifierProxyProvider<StudentService, StudentProvider>(
          create: (context) => StudentProvider(
            studentService: context.read<StudentService>(),
          ),
          update: (_, studentService, previous) =>
              previous ?? StudentProvider(studentService: studentService),
        ),
        ChangeNotifierProxyProvider<GroupService, GroupProvider>(
          create: (context) => GroupProvider(
            groupService: context.read<GroupService>(),
          ),
          update: (_, groupService, previous) =>
              previous ?? GroupProvider(groupService: groupService),
        ),
        ChangeNotifierProxyProvider<AnnouncementService, AnnouncementProvider>(
          create: (context) => AnnouncementProvider(
            announcementService: context.read<AnnouncementService>(),
          ),
          update: (_, announcementService, previous) => previous ??
              AnnouncementProvider(announcementService: announcementService),
        ),
        ChangeNotifierProxyProvider<AssignmentService, AssignmentProvider>(
          create: (context) => AssignmentProvider(
            assignmentService: context.read<AssignmentService>(),
          ),
          update: (_, assignmentService, previous) => previous ??
              AssignmentProvider(assignmentService: assignmentService),
        ),
        ChangeNotifierProxyProvider<MaterialService, MaterialProvider>(
          create: (context) => MaterialProvider(
            materialService: context.read<MaterialService>(),
          ),
          update: (_, materialService, previous) => previous ??
              MaterialProvider(materialService: materialService),
        ),
        ChangeNotifierProvider<QuizProvider>(
          create: (context) => QuizProvider(),
        ),
        ChangeNotifierProxyProvider<ForumService, ForumProvider>(
          create: (context) => ForumProvider(
            forumService: context.read<ForumService>(),
          ),
          update: (_, forumService, previous) =>
              previous ?? ForumProvider(forumService: forumService),
        ),
        ChangeNotifierProxyProvider<MessageService, MessageProvider>(
          create: (context) => MessageProvider(
            messageService: context.read<MessageService>(),
          ),
          update: (_, messageService, previous) =>
              previous ?? MessageProvider(messageService: messageService),
        ),
        ChangeNotifierProxyProvider<NotificationService, NotificationProvider>(
          create: (context) => NotificationProvider(
            notificationService: context.read<NotificationService>(),
          ),
          update: (_, notificationService, previous) => previous ??
              NotificationProvider(notificationService: notificationService),
        ),
      ],
      child: MaterialApp(
        title: 'E-Learning Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}

/// Splash Screen - Initial screen that checks auth state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = context.read<AuthService>();

    // Check if user is already logged in
    final isLoggedIn = await authService.validateSession();

    if (!mounted) return;

    if (isLoggedIn) {
      // Navigate to appropriate screen based on role
      if (authService.isInstructor) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const InstructorDashboardScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const StudentHomeScreen(),
          ),
        );
      }
    } else {
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Icon(
              Icons.school,
              size: 100,
              color: AppTheme.textOnPrimaryColor,
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'E-Learning Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faculty of Information Technology',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textOnPrimaryColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.textOnPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
