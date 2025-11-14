import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/course_model.dart';
import '../../models/announcement_model.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_submission_model.dart';
import '../../models/material_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/group_service.dart';
import '../../services/student_service.dart';
import '../../services/auth_service.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/material_provider.dart';
import '../../providers/forum_provider.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/announcement_form_dialog.dart';
import '../../widgets/assignment_form_dialog.dart';
import '../../widgets/material_form_dialog.dart';
import '../student/assignment_submission_screen.dart';
import '../instructor/assignment_tracking_screen.dart';
import '../instructor/quiz_management_screen.dart';
import '../instructor/question_bank_screen.dart';
import '../student/quiz_taking_screen.dart';
import './material_details_screen.dart';
import './forum/forum_list_screen.dart';
import './messaging/conversations_list_screen.dart';

/// Course Space Screen with 3 Tabs: Stream, Classwork, People
/// Forum integrated into People tab, Messages accessible via AppBar
/// Based on PDF requirements (Interface requirement - 2 pts)
class CourseSpaceScreen extends StatefulWidget {
  final CourseModel course;
  final String currentUserId;
  final String currentUserRole;

  const CourseSpaceScreen({
    super.key,
    required this.course,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<CourseSpaceScreen> createState() => _CourseSpaceScreenState();
}

class _CourseSpaceScreenState extends State<CourseSpaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists (will be populated from services later)
  List<AnnouncementModel> _announcements = [];
  List<AssignmentModel> _assignments = [];
  List<QuizModel> _quizzes = [];
  List<MaterialModel> _materials = [];
  List<GroupModel> _groups = [];
  List<UserModel> _students = [];

  // Track quiz submissions for students (quizId -> best submission)
  Map<String, QuizSubmissionModel> _quizSubmissions = {};

  // Track which group the current user belongs to (for students)
  String? _currentUserGroupId;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Defer loading to after the first frame to avoid build-phase conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get services from context
      final groupService = context.read<GroupService>();
      final studentService = context.read<StudentService>();
      final announcementProvider = context.read<AnnouncementProvider>();
      final assignmentProvider = context.read<AssignmentProvider>();
      final quizProvider = context.read<QuizProvider>();

      // Load groups for this course
      _groups = await groupService.getGroupsByCourse(widget.course.id);

      // Find which group the current user belongs to (if they are a student)
      List<String> studentGroupIds = [];
      if (widget.currentUserRole == AppConstants.roleStudent) {
        for (var group in _groups) {
          if (group.hasStudent(widget.currentUserId)) {
            _currentUserGroupId = group.id;
            studentGroupIds.add(group.id);
          }
        }
      }

      // Load announcements based on role
      if (widget.currentUserRole == AppConstants.roleInstructor) {
        // Instructors see all announcements for the course
        await announcementProvider.loadAnnouncementsByCourse(widget.course.id);
      } else {
        // Students see only announcements scoped to their groups
        await announcementProvider.loadAnnouncementsForStudent(
          courseId: widget.course.id,
          studentId: widget.currentUserId,
          studentGroupIds: studentGroupIds,
        );
      }
      _announcements = announcementProvider.announcements;

      // Collect all unique student IDs from all groups in this course
      final Set<String> studentIds = {};
      for (var group in _groups) {
        studentIds.addAll(group.studentIds);
      }

      // Load student details for all student IDs
      _students = [];
      for (var studentId in studentIds) {
        final student = await studentService.getStudentById(studentId);
        if (student != null) {
          _students.add(student);
        }
      }

      // Sort students by name for better UX
      _students.sort((a, b) => a.fullName.compareTo(b.fullName));

      // Load assignments based on role
      if (widget.currentUserRole == AppConstants.roleInstructor) {
        // Instructors see all assignments for the course
        await assignmentProvider.loadAssignmentsByCourse(widget.course.id);
      } else {
        // Students see only assignments scoped to their groups
        await assignmentProvider.loadAssignmentsForStudent(
          courseId: widget.course.id,
          studentId: widget.currentUserId,
          studentGroupIds: studentGroupIds,
        );
      }
      _assignments = assignmentProvider.assignments;

      // Load quizzes based on role
      if (widget.currentUserRole == AppConstants.roleInstructor) {
        // Instructors see all quizzes for the course
        await quizProvider.loadQuizzesForCourse(widget.course.id);
      } else {
        // Students see only quizzes available to their groups
        await quizProvider.loadAvailableQuizzes(
          courseId: widget.course.id,
          studentGroupIds: studentGroupIds,
        );

        // Load student's best submissions for each quiz
        _quizSubmissions = {};
        for (var quiz in quizProvider.quizzes) {
          try {
            final bestSubmission = await quizProvider.checkQuizEligibility(
              quizId: quiz.id,
              studentId: widget.currentUserId,
              studentGroupIds: studentGroupIds,
            );

            // If student has taken the quiz, load their best submission
            final attemptCount = await quizProvider.getAttemptCount(
              quizId: quiz.id,
              studentId: widget.currentUserId,
            );

            if (attemptCount > 0) {
              final submissions = await quizProvider.checkQuizEligibility(
                quizId: quiz.id,
                studentId: widget.currentUserId,
                studentGroupIds: studentGroupIds,
              );
              // Load student submissions directly from service
              await quizProvider.loadStudentSubmissions(
                quizId: quiz.id,
                studentId: widget.currentUserId,
              );

              // Get the best submission
              if (quizProvider.submissions.isNotEmpty) {
                // Sort by score to get the best one
                final sortedSubmissions = List<QuizSubmissionModel>.from(quizProvider.submissions)
                  ..sort((a, b) => b.score.compareTo(a.score));
                _quizSubmissions[quiz.id] = sortedSubmissions.first;
              }
            }
          } catch (e) {
            // Ignore errors for individual quiz submission loading
          }
        }
      }
      _quizzes = quizProvider.quizzes;

      // Load materials (automatically visible to all students in the course)
      final materialProvider = context.read<MaterialProvider>();
      await materialProvider.loadMaterialsByCourse(widget.course.id);
      _materials = materialProvider.materials;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.course.code,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textOnPrimaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsListScreen(),
                ),
              );
            },
            tooltip: 'Messages',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.textOnPrimaryColor,
          labelColor: AppTheme.textOnPrimaryColor,
          unselectedLabelColor: AppTheme.textOnPrimaryColor.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.stream), text: 'Stream'),
            Tab(icon: Icon(Icons.assignment), text: 'Classwork'),
            Tab(icon: Icon(Icons.people), text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamTab(),
          _buildClassworkTab(),
          _buildPeopleTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Stream Tab: Displays recent announcements with comment threads
  Widget _buildStreamTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.campaign,
        message: 'No announcements yet',
        description: widget.currentUserRole == AppConstants.roleInstructor
            ? 'Create your first announcement to get started'
            : 'Your instructor will post announcements here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  // Classwork Tab: Centralizes assignments, quizzes, and materials with search/sort
  Widget _buildClassworkTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Combine all classwork items
    final totalItems =
        _assignments.length + _quizzes.length + _materials.length;

    if (totalItems == 0) {
      return _buildEmptyState(
        icon: Icons.school,
        message: 'No classwork yet',
        description: widget.currentUserRole == AppConstants.roleInstructor
            ? 'Add assignments, quizzes, or materials'
            : 'Your instructor will add classwork here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Search and filter bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search classwork...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                      ),
                      onChanged: (value) {
                        // TODO: Implement search
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      _showFilterDialog();
                    },
                    tooltip: 'Filter & Sort',
                  ),
                ],
              ),
            ),
          ),

          // Assignments Section
          if (_assignments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingM,
                  AppTheme.spacingM,
                  AppTheme.spacingM,
                  AppTheme.spacingS,
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Assignments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '${_assignments.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildAssignmentCard(_assignments[index]);
                },
                childCount: _assignments.length,
              ),
            ),
          ],

          // Quizzes Section
          if (_quizzes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingM,
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                  AppTheme.spacingS,
                ),
                child: Row(
                  children: [
                    Icon(Icons.quiz, color: AppTheme.infoColor, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Quizzes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoLightColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '${_quizzes.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildQuizCard(_quizzes[index]);
                },
                childCount: _quizzes.length,
              ),
            ),
          ],

          // Materials Section
          if (_materials.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingM,
                  AppTheme.spacingL,
                  AppTheme.spacingM,
                  AppTheme.spacingS,
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Materials',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLightColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '${_materials.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildMaterialCard(_materials[index]);
                },
                childCount: _materials.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingXL),
          ),
        ],
      ),
    );
  }

  // People Tab: Lists groups and students enrolled in the course
  Widget _buildPeopleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Instructor Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school,
                          color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Instructor',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        widget.course.instructorName
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.textOnPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(widget.course.instructorName),
                    subtitle: const Text('Course Instructor'),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConversationsListScreen(),
                          ),
                        );
                      },
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Forum Section
          Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ForumListScreen(course: widget.course),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: const Icon(
                        Icons.forum,
                        color: Colors.purple,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course Forum',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Discuss course topics with classmates',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Groups Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Groups',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLightColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Text(
                              '${_groups.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.currentUserRole == AppConstants.roleInstructor)
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Manage groups
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Manage'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  if (_groups.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Text(
                          'No groups created yet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_groups.length, (index) {
                      final group = _groups[index];
                      return _buildGroupCard(group);
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Students Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Students',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLightColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Text(
                              '${_students.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        onPressed: () {
                          // TODO: Search students
                        },
                        tooltip: 'Search students',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  if (_students.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Text(
                          'No students enrolled yet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_students.length, (index) {
                      final student = _students[index];
                      return _buildStudentListTile(student);
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Announcement Card
  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    return AnnouncementCard(
      announcement: announcement,
      isInstructor: widget.currentUserRole == AppConstants.roleInstructor,
      onEdit: widget.currentUserRole == AppConstants.roleInstructor
          ? () => _showEditAnnouncementDialog(announcement)
          : null,
      onDelete: widget.currentUserRole == AppConstants.roleInstructor
          ? () => _confirmDeleteAnnouncement(announcement)
          : null,
    );
  }

  // Show create announcement dialog
  Future<void> _showCreateAnnouncementDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        groups: _groups,
        courseId: widget.course.id,
      ),
    );

    if (result != null && mounted) {
      final announcementProvider = context.read<AnnouncementProvider>();
      final announcement = await announcementProvider.createAnnouncement(
        courseId: widget.course.id,
        title: result['title'],
        content: result['content'],
        groupIds: result['groupIds'],
        instructorId: widget.currentUserId,
        instructorName: widget.course.instructorName,
        attachmentFiles: result['attachmentFiles'],
      );

      if (announcement != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
        await _loadData(); // Reload to show new announcement
      } else if (mounted) {
        final error = announcementProvider.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create announcement')),
        );
      }
    }
  }

  // Show edit announcement dialog
  Future<void> _showEditAnnouncementDialog(
      AnnouncementModel announcement) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        announcement: announcement,
        groups: _groups,
        courseId: widget.course.id,
      ),
    );

    if (result != null && mounted) {
      final updatedAnnouncement = announcement.copyWith(
        title: result['title'],
        content: result['content'],
        groupIds: result['groupIds'],
      );

      final newAttachmentFiles = result['attachmentFiles'] as List<PlatformFile>?;

      bool success;
      if (newAttachmentFiles != null && newAttachmentFiles.isNotEmpty) {
        // Use the method that handles file uploads
        success = await context
            .read<AnnouncementProvider>()
            .updateAnnouncementWithFiles(
              announcement: updatedAnnouncement,
              newAttachmentFiles: newAttachmentFiles,
            );
      } else {
        // No new files, just update basic info
        success = await context
            .read<AnnouncementProvider>()
            .updateAnnouncement(updatedAnnouncement);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
        await _loadData();
      } else if (mounted) {
        final error = context.read<AnnouncementProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to update announcement')),
        );
      }
    }
  }

  // Confirm delete announcement
  Future<void> _confirmDeleteAnnouncement(
      AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete "${announcement.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<AnnouncementProvider>()
          .deleteAnnouncement(announcement.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
        await _loadData();
      } else if (mounted) {
        final error = context.read<AnnouncementProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to delete announcement')),
        );
      }
    }
  }

  // Confirm and delete assignment
  Future<void> _confirmDeleteAssignment(AssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"?\n\n'
          'This will also delete all student submissions and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<AssignmentProvider>()
          .deleteAssignment(assignment.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment deleted successfully')),
        );
        await _loadData();
      } else if (mounted) {
        final error = context.read<AssignmentProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to delete assignment')),
        );
      }
    }
  }

  // Show create assignment dialog
  Future<void> _showCreateAssignmentDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AssignmentFormDialog(
        groups: _groups,
        courseId: widget.course.id,
      ),
    );

    if (result != null && mounted) {
      final assignmentProvider = context.read<AssignmentProvider>();
      final assignment = await assignmentProvider.createAssignment(
        courseId: widget.course.id,
        title: result['title'],
        description: result['description'],
        startDate: result['startDate'],
        deadline: result['deadline'],
        allowLateSubmission: result['allowLateSubmission'],
        lateDeadline: result['lateDeadline'],
        maxAttempts: result['maxAttempts'],
        allowedFileFormats: result['allowedFileFormats'],
        maxFileSize: result['maxFileSize'],
        groupIds: result['groupIds'],
        instructorId: widget.currentUserId,
        instructorName: widget.course.instructorName,
        attachmentFiles: result['attachmentFiles'],
      );

      if (assignment != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully')),
        );
        await _loadData(); // Reload to show new assignment
      } else if (mounted) {
        final error = assignmentProvider.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create assignment')),
        );
      }
    }
  }

  // Show Create Material Dialog
  Future<void> _showCreateMaterialDialog() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MaterialFormDialog(
        courseId: widget.course.id,
      ),
    );

    if (result != null && mounted) {
      final materialProvider = context.read<MaterialProvider>();
      final materialId = await materialProvider.createMaterial(
        courseId: widget.course.id,
        title: result['title'],
        description: result['description'],
        instructorId: currentUser.id,
        instructorName: currentUser.fullName,
        files: result['newFiles'],
        links: result['links'],
      );

      if (materialId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material created successfully')),
        );
        await _loadData(); // Reload to show new material
      } else if (mounted) {
        final error = materialProvider.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create material')),
        );
      }
    }
  }

  // Build Assignment Card
  Widget _buildAssignmentCard(AssignmentModel assignment) {
    Color statusColor = AppTheme.successColor;
    String statusText = 'Open';
    IconData statusIcon = Icons.check_circle;

    if (assignment.isClosed) {
      statusColor = AppTheme.errorColor;
      statusText = 'Closed';
      statusIcon = Icons.cancel;
    } else if (assignment.isUpcoming) {
      statusColor = AppTheme.infoColor;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else if (assignment.isInLatePeriod) {
      statusColor = AppTheme.warningColor;
      statusText = 'Late Period';
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: InkWell(
        onTap: () {
          if (widget.currentUserRole == AppConstants.roleInstructor) {
            // Instructor: Navigate to tracking dashboard
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AssignmentTrackingScreen(
                  assignment: assignment,
                  courseId: widget.course.id,
                ),
              ),
            );
          } else {
            // Student: Navigate to submission screen
            final authService = context.read<AuthService>();
            final currentUser = authService.currentUser;

            if (currentUser != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AssignmentSubmissionScreen(
                    assignment: assignment,
                    student: currentUser,
                  ),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  Icons.assignment,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          statusText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Due: ${AppConstants.formatDateTime(assignment.deadline)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add action buttons for instructors
              if (widget.currentUserRole == AppConstants.roleInstructor) ...[
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteAssignment(assignment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // Build Quiz Card
  Widget _buildQuizCard(QuizModel quiz) {
    Color statusColor = AppTheme.successColor;
    String statusText = 'Available';
    IconData statusIcon = Icons.check_circle;

    // Check if student has completed this quiz
    final submission = widget.currentUserRole == AppConstants.roleStudent
        ? _quizSubmissions[quiz.id]
        : null;

    if (submission != null) {
      // Student has completed the quiz
      statusColor = Colors.purple;
      statusText = 'Completed • ${submission.formattedScore}';
      statusIcon = Icons.check_circle;
    } else if (quiz.isClosed) {
      statusColor = AppTheme.errorColor;
      statusText = 'Closed';
      statusIcon = Icons.cancel;
    } else if (quiz.isUpcoming) {
      statusColor = AppTheme.infoColor;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: InkWell(
        onTap: () {
          if (widget.currentUserRole == AppConstants.roleInstructor) {
            // Instructors go to quiz management
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizManagementScreen(
                  courseId: widget.course.id,
                  courseName: widget.course.name,
                ),
              ),
            ).then((_) => _loadData());
          } else {
            // Students can take the quiz if it's available
            if (quiz.isAvailable) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizTakingScreen(
                    quizId: quiz.id,
                    courseId: widget.course.id,
                  ),
                ),
              ).then((_) => _loadData());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(quiz.isUpcoming
                      ? 'Quiz will be available on ${quiz.openDate}'
                      : 'Quiz is closed'),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  Icons.quiz,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          statusText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        if (submission == null)
                          Text(
                            '${quiz.totalQuestions} questions • ${quiz.durationMinutes} min',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // Build Material Card
  Widget _buildMaterialCard(MaterialModel material) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MaterialDetailsScreen(material: material),
            ),
          ).then((_) => _loadData()); // Reload data when returning
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.warningLightColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  Icons.folder,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        if (material.hasFiles) ...[
                          Icon(
                            Icons.attach_file,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            '${material.files.length} files',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                          ),
                        ],
                        if (material.hasFiles && material.hasLinks)
                          const Text(' • '),
                        if (material.hasLinks) ...[
                          Icon(
                            Icons.link,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            '${material.links.length} links',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // Build Group Card
  Widget _buildGroupCard(GroupModel group) {
    final isCurrentUserGroup = _currentUserGroupId == group.id;

    return Container(
      decoration: isCurrentUserGroup
          ? BoxDecoration(
              color: AppTheme.primaryLightColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            )
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUserGroup
              ? AppTheme.primaryColor
              : AppTheme.primaryLightColor,
          child: Icon(
            Icons.group,
            color: isCurrentUserGroup
                ? AppTheme.textOnPrimaryColor
                : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(group.name),
            if (isCurrentUserGroup) ...[
              const SizedBox(width: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  'Your Group',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textOnPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('${group.studentIds.length} students'),
        trailing: widget.currentUserRole == AppConstants.roleInstructor
            ? IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  // TODO: Edit group
                },
              )
            : null,
        onTap: () {
          // TODO: View group details
        },
      ),
    );
  }

  // Build Student List Tile
  Widget _buildStudentListTile(UserModel student) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          student.fullName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: AppTheme.textOnPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(student.fullName),
      subtitle: Text('ID: ${student.studentId ?? "N/A"}'),
      trailing: widget.currentUserRole == AppConstants.roleInstructor
          ? IconButton(
              icon: const Icon(Icons.message, size: 20),
              onPressed: () {
                // TODO: Send message to student
              },
            )
          : null,
    );
  }

  // Build Empty State
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textDisabledColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDisabledColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build Floating Action Button (for instructors only)
  Widget? _buildFloatingActionButton() {
    if (widget.currentUserRole != AppConstants.roleInstructor) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () {
        _showAddContentDialog();
      },
      tooltip: 'Add Content',
      child: const Icon(Icons.add),
    );
  }

  // Show Add Content Dialog
  void _showAddContentDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('Create Announcement'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAnnouncementDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Create Assignment'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAssignmentDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('Manage Quizzes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizManagementScreen(
                        courseId: widget.course.id,
                        courseName: widget.course.name,
                      ),
                    ),
                  ).then((_) => _loadData()); // Reload data when returning
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('Question Bank'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionBankScreen(
                        courseId: widget.course.id,
                        courseName: widget.course.name,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Add Material'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateMaterialDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Filter Dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter & Sort'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                title: const Text('Date (Newest first)'),
                value: 'date_desc',
                groupValue: 'date_desc',
                onChanged: (value) {
                  // TODO: Implement sorting
                },
              ),
              RadioListTile(
                title: const Text('Date (Oldest first)'),
                value: 'date_asc',
                groupValue: 'date_desc',
                onChanged: (value) {
                  // TODO: Implement sorting
                },
              ),
              RadioListTile(
                title: const Text('Title (A-Z)'),
                value: 'title_asc',
                groupValue: 'date_desc',
                onChanged: (value) {
                  // TODO: Implement sorting
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Filter by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: const Text('Assignments'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement filtering
                },
              ),
              CheckboxListTile(
                title: const Text('Quizzes'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement filtering
                },
              ),
              CheckboxListTile(
                title: const Text('Materials'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement filtering
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Apply filters
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
