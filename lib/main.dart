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
import 'providers/semester_provider.dart';
import 'providers/course_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/instructor/instructor_dashboard_screen.dart';
import 'screens/student/student_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize Hive for offline caching
    await HiveService.instance.initialize();
    print('Hive initialized successfully');
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
        ProxyProvider2<FirestoreService, HiveService, SemesterService>(
          update: (_, firestoreService, hiveService, __) => SemesterService(
            firestoreService: firestoreService,
            hiveService: hiveService,
          ),
        ),
        ProxyProvider3<FirestoreService, HiveService, AuthService, CourseService>(
          update: (_, firestoreService, hiveService, authService, __) => CourseService(
            firestoreService: firestoreService,
            hiveService: hiveService,
            authService: authService,
          ),
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
