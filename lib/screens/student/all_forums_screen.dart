import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../services/auth_service.dart';
import '../shared/forum/forum_list_screen.dart';

/// All Forums Screen
/// Shows forums from all enrolled courses
class AllForumsScreen extends StatefulWidget {
  const AllForumsScreen({super.key});

  @override
  State<AllForumsScreen> createState() => _AllForumsScreenState();
}

class _AllForumsScreenState extends State<AllForumsScreen> {
  List<CourseModel> _enrolledCourses = [];
  CourseModel? _selectedCourse;
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrolledCourses();
    });
  }

  Future<void> _loadEnrolledCourses() async {
    if (!mounted) return;

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final courseProvider = context.read<CourseProvider>();
      final courses =
          await courseProvider.loadCoursesForStudent(currentUser.id);

      if (mounted) {
        setState(() {
          _enrolledCourses = courses;
          if (_enrolledCourses.isNotEmpty) {
            _selectedCourse = _enrolledCourses.first;
          }
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_enrolledCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum,
                size: 80,
                color: AppTheme.textDisabledColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'No courses enrolled',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Enroll in a course to access forums',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDisabledColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Course selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightColor.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.class_,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CourseModel>(
                    value: _selectedCourse,
                    isExpanded: true,
                    items: _enrolledCourses.map((course) {
                      return DropdownMenuItem<CourseModel>(
                        value: course,
                        child: Text(
                          '${course.code} - ${course.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (CourseModel? newValue) {
                      setState(() {
                        _selectedCourse = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Forum content
        Expanded(
          child: _selectedCourse != null
              ? ForumListScreen(course: _selectedCourse!)
              : const Center(
                  child: Text('Please select a course'),
                ),
        ),
      ],
    );
  }
}
