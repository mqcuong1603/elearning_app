import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/assignment_model.dart';

/// Timeline widget for upcoming deadlines
class DeadlineTimelineWidget extends StatelessWidget {
  final List<AssignmentModel> assignments;
  final Function(AssignmentModel)? onAssignmentTap;

  const DeadlineTimelineWidget({
    super.key,
    required this.assignments,
    this.onAssignmentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
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
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        final now = DateTime.now();
        final daysUntil = assignment.deadline.difference(now).inDays;
        final hoursUntil = assignment.deadline.difference(now).inHours;

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
              if (onAssignmentTap != null) {
                onAssignmentTap!(assignment);
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
                        Text(
                          assignment.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                  .format(assignment.deadline),
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
