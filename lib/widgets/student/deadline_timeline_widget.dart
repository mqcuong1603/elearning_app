import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';

/// Timeline widget for upcoming deadlines
class DeadlineTimelineWidget extends StatelessWidget {
  final List<AssignmentModel> assignments;
  final List<QuizModel> quizzes;
  final Function(AssignmentModel)? onAssignmentTap;
  final Function(QuizModel)? onQuizTap;

  const DeadlineTimelineWidget({
    super.key,
    required this.assignments,
    this.quizzes = const [],
    this.onAssignmentTap,
    this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    // Combine assignments and quizzes into deadline items
    final List<_DeadlineItem> deadlineItems = [
      ...assignments.map((a) => _DeadlineItem(
            title: a.title,
            deadline: a.deadline,
            type: 'Assignment',
            icon: Icons.assignment,
            data: a,
          )),
      ...quizzes.map((q) => _DeadlineItem(
            title: q.title,
            deadline: q.closeDate,
            type: 'Quiz',
            icon: Icons.quiz,
            data: q,
          )),
    ];

    // Sort by deadline
    deadlineItems.sort((a, b) => a.deadline.compareTo(b.deadline));

    if (deadlineItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No upcoming deadlines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'You\'re all caught up!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textDisabledColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deadlineItems.length,
      itemBuilder: (context, index) {
        final item = deadlineItems[index];
        final now = DateTime.now();
        final daysUntil = item.deadline.difference(now).inDays;
        final hoursUntil = item.deadline.difference(now).inHours;

        String timeText;
        Color timeColor;
        IconData timeIcon;

        if (daysUntil < 0) {
          timeText = 'Overdue';
          timeColor = AppTheme.errorColor;
          timeIcon = Icons.error;
        } else if (hoursUntil < 24) {
          timeText = 'Due today';
          timeColor = AppTheme.errorColor;
          timeIcon = Icons.warning;
        } else if (daysUntil == 1) {
          timeText = 'Due tomorrow';
          timeColor = AppTheme.warningColor;
          timeIcon = Icons.access_time;
        } else if (daysUntil <= 3) {
          timeText = 'Due in $daysUntil days';
          timeColor = AppTheme.warningColor;
          timeIcon = Icons.schedule;
        } else if (daysUntil <= 7) {
          timeText = 'Due in $daysUntil days';
          timeColor = AppTheme.infoColor;
          timeIcon = Icons.event;
        } else {
          timeText = 'Due in $daysUntil days';
          timeColor = AppTheme.textSecondaryColor;
          timeIcon = Icons.event_available;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          child: InkWell(
            onTap: () {
              if (item.type == 'Assignment' && onAssignmentTap != null) {
                onAssignmentTap!(item.data as AssignmentModel);
              } else if (item.type == 'Quiz' && onQuizTap != null) {
                onQuizTap!(item.data as QuizModel);
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  // Timeline indicator
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: timeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              DateFormat('MMM dd, yyyy - HH:mm')
                                  .format(item.deadline),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: timeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: timeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          timeIcon,
                          size: 14,
                          color: timeColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: timeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Internal class to represent a deadline item (assignment or quiz)
class _DeadlineItem {
  final String title;
  final DateTime deadline;
  final String type; // 'Assignment' or 'Quiz'
  final IconData icon;
  final dynamic data; // The actual AssignmentModel or QuizModel

  _DeadlineItem({
    required this.title,
    required this.deadline,
    required this.type,
    required this.icon,
    required this.data,
  });
}
