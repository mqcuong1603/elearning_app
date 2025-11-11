import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:elearning_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:elearning_app/features/auth/presentation/screens/login_screen.dart';
import 'package:elearning_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:elearning_app/features/dashboard/presentation/screens/student_dashboard_screen.dart';
import 'package:elearning_app/features/dashboard/presentation/screens/instructor_dashboard_screen.dart';
import 'package:elearning_app/features/course/presentation/screens/course_home_screen.dart';
import 'package:elearning_app/features/course/presentation/screens/course_list_screen.dart';
import 'package:elearning_app/features/course/presentation/screens/course_detail_screen.dart';
import 'package:elearning_app/features/course/presentation/screens/course_form_screen.dart';
import 'package:elearning_app/features/semester/presentation/screens/semester_list_screen.dart';
import 'package:elearning_app/features/semester/presentation/screens/semester_form_screen.dart';
import 'package:elearning_app/features/semester/presentation/screens/semester_csv_import_screen.dart';
import 'package:elearning_app/features/group/presentation/screens/group_list_screen.dart';
import 'package:elearning_app/features/group/presentation/screens/group_form_screen.dart';
import 'package:elearning_app/features/student/presentation/screens/student_list_screen.dart';
import 'package:elearning_app/features/student/presentation/screens/student_form_screen.dart';
import 'package:elearning_app/features/student/presentation/screens/student_import_screen.dart';
import 'package:elearning_app/features/announcement/presentation/screens/announcement_list_screen.dart';
import 'package:elearning_app/features/assignment/presentation/screens/assignment_list_screen.dart';
import 'package:elearning_app/features/quiz/presentation/screens/quiz_list_screen.dart';
import 'package:elearning_app/features/material/presentation/screens/material_list_screen.dart';

/// Router configuration provider
/// PDF Requirement: Role-based navigation (Admin vs Student)
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final isStudent = authState.isStudent;
      final isLoading = authState.isLoading;

      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      // If still loading, stay on splash
      if (isLoading && !isSplash) {
        return '/splash';
      }

      // If not authenticated and not on login/splash, redirect to login
      if (!isAuthenticated && !isLogin && !isSplash) {
        return '/login';
      }

      // If authenticated and on splash/login, redirect based on role
      if (isAuthenticated && (isSplash || isLogin)) {
        if (isAdmin) {
          return '/dashboard';
        } else if (isStudent) {
          return '/';
        }
      }

      return null; // No redirect needed
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Student Home (Course List)
      // PDF Requirement: "For students, the homepage displays enrolled courses as cards"
      GoRoute(
        path: '/',
        builder: (context, state) => const CourseHomeScreen(),
      ),

      // Admin/Instructor Dashboard
      // PDF Requirement: Admin can manage semesters, courses, groups, students
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const InstructorDashboardScreen(),
      ),

      // Student Dashboard (if separate from course home)
      GoRoute(
        path: '/student-dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),

      // Profile Screen
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ===== Course Routes =====
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CourseListScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/new',
        builder: (context, state) {
          final semesterId = state.uri.queryParameters['semesterId'];
          return CourseFormScreen(semesterId: semesterId);
        },
      ),
      GoRoute(
        path: '/courses/:id/edit',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseFormScreen(courseId: courseId);
        },
      ),

      // ===== Semester Routes =====
      GoRoute(
        path: '/semesters',
        builder: (context, state) => const SemesterListScreen(),
      ),
      GoRoute(
        path: '/semesters/new',
        builder: (context, state) => const SemesterFormScreen(),
      ),
      GoRoute(
        path: '/semesters/:id/edit',
        builder: (context, state) {
          final semesterId = state.pathParameters['id']!;
          return SemesterFormScreen(semesterId: semesterId);
        },
      ),
      GoRoute(
        path: '/semesters/import',
        builder: (context, state) => const SemesterCsvImportScreen(),
      ),

      // ===== Group Routes =====
      GoRoute(
        path: '/courses/:courseId/groups',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return GroupListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/groups/new',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return GroupFormScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/groups/:id/edit',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final groupId = state.pathParameters['id']!;
          return GroupFormScreen(courseId: courseId, groupId: groupId);
        },
      ),

      // ===== Student Routes =====
      GoRoute(
        path: '/courses/:courseId/students',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return StudentListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/students/new',
        builder: (context, state) => const StudentFormScreen(),
      ),
      GoRoute(
        path: '/students/import',
        builder: (context, state) => const StudentImportScreen(),
      ),

      // ===== Content Routes (Announcements, Assignments, Quizzes, Materials) =====
      GoRoute(
        path: '/courses/:courseId/announcements',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return AnnouncementListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/assignments',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return AssignmentListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/quizzes',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return QuizListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:courseId/materials',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return MaterialListScreen(courseId: courseId);
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('The page ${state.uri} does not exist.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
