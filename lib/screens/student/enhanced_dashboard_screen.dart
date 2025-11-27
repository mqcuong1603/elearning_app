import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/student/progress_card_widget.dart';
import '../../widgets/student/deadline_timeline_widget.dart';

/// Enhanced Dashboard Screen with comprehensive learning progress tracking
class EnhancedDashboardTab extends StatefulWidget {
  final String studentId;
  final List<String> courseIds;
  final List<String> studentGroupIds;
  final bool isReadOnly;

  const EnhancedDashboardTab({
    super.key,
    required this.studentId,
    required this.courseIds,
    required this.studentGroupIds,
    this.isReadOnly = false,
  });

  @override
  State<EnhancedDashboardTab> createState() => _EnhancedDashboardTabState();
}

class _EnhancedDashboardTabState extends State<EnhancedDashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.loadDashboardData(
      studentId: widget.studentId,
      courseIds: widget.courseIds,
      studentGroupIds: widget.studentGroupIds,
    );
  }

  Future<void> _refreshData() async {
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.refresh(
      studentId: widget.studentId,
      courseIds: widget.courseIds,
      studentGroupIds: widget.studentGroupIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (dashboardProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Error loading dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  dashboardProvider.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = dashboardProvider.getProgressStats();

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.isReadOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              'Read Only',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Assignment Progress Cards
                Text(
                  'Assignment Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: ProgressCardWidget(
                        title: 'Submitted',
                        completed: stats['submittedAssignments'] as int,
                        total: stats['totalAssignments'] as int,
                        color: AppTheme.successColor,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: ProgressCardWidget(
                        title: 'Pending',
                        completed: stats['pendingAssignments'] as int,
                        total: stats['totalAssignments'] as int,
                        color: AppTheme.warningColor,
                        icon: Icons.pending_actions,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Quick Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: StatCardWidget(
                        title: 'Late',
                        value: '${stats['lateAssignments']}',
                        icon: Icons.schedule,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StatCardWidget(
                        title: 'Graded',
                        value: '${stats['gradedAssignments']}',
                        icon: Icons.grade,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StatCardWidget(
                        title: 'Overdue',
                        value: '${stats['overdueAssignments']}',
                        icon: Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Quiz Progress
                Text(
                  'Quiz Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                ProgressCardWidget(
                  title: 'Quizzes Completed',
                  completed: stats['completedQuizzes'] as int,
                  total: stats['totalQuizzes'] as int,
                  color: AppTheme.primaryColor,
                  icon: Icons.quiz,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Average Scores
                Row(
                  children: [
                    Expanded(
                      child: StatCardWidget(
                        title: 'Avg Assignment Grade',
                        value: stats['averageAssignmentGrade'] != null
                            ? (stats['averageAssignmentGrade'] as double)
                                .toStringAsFixed(1)
                            : 'N/A',
                        icon: Icons.trending_up,
                        color: AppTheme.successColor,
                        subtitle: stats['averageAssignmentGrade'] != null
                            ? '${stats['gradedAssignments']} graded'
                            : 'No grades yet',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StatCardWidget(
                        title: 'Avg Quiz Score',
                        value: stats['averageQuizScore'] != null
                            ? '${(stats['averageQuizScore'] as double).toStringAsFixed(1)}%'
                            : 'N/A',
                        icon: Icons.assessment,
                        color: AppTheme.primaryColor,
                        subtitle: stats['averageQuizScore'] != null
                            ? '${stats['completedQuizzes']} completed'
                            : 'No quizzes yet',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Upcoming Deadlines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Deadlines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (dashboardProvider
                                .getUpcomingAssignments(limit: 10)
                                .length +
                            dashboardProvider
                                .getUpcomingQuizzes(limit: 10)
                                .length >
                        5)
                      TextButton(
                        onPressed: () {
                          _showAllDeadlines(context, dashboardProvider);
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                DeadlineTimelineWidget(
                  assignments:
                      dashboardProvider.getUpcomingAssignments(limit: 5),
                  quizzes: dashboardProvider.getUpcomingQuizzes(limit: 5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllDeadlines(BuildContext context, DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Upcoming Deadlines',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        DeadlineTimelineWidget(
                          assignments:
                              provider.getUpcomingAssignments(limit: 0),
                          quizzes: provider.getUpcomingQuizzes(limit: 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
