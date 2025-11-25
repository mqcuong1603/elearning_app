import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/filter_model.dart';

/// Reusable sort dropdown widget
class SortDropdownWidget extends StatelessWidget {
  final SortOptions currentSort;
  final Function(SortOptions) onSortChanged;
  final List<SortField> availableFields;

  const SortDropdownWidget({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.availableFields,
  });

  String _getSortFieldLabel(SortField field) {
    switch (field) {
      case SortField.name:
        return 'Name';
      case SortField.deadline:
        return 'Deadline';
      case SortField.score:
        return 'Score';
      case SortField.date:
        return 'Date';
      case SortField.status:
        return 'Status';
    }
  }

  IconData _getSortFieldIcon(SortField field) {
    switch (field) {
      case SortField.name:
        return Icons.sort_by_alpha;
      case SortField.deadline:
        return Icons.event;
      case SortField.score:
        return Icons.grade;
      case SortField.date:
        return Icons.calendar_today;
      case SortField.status:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          DropdownButton<SortField>(
            value: currentSort.field,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
            ),
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            items: availableFields.map((field) {
              return DropdownMenuItem<SortField>(
                value: field,
                child: Row(
                  children: [
                    Icon(
                      _getSortFieldIcon(field),
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(_getSortFieldLabel(field)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (field) {
              if (field != null) {
                onSortChanged(SortOptions(
                  field: field,
                  order: currentSort.order,
                ));
              }
            },
          ),
          const SizedBox(width: AppTheme.spacingS),
          IconButton(
            icon: Icon(
              currentSort.order == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              onSortChanged(currentSort.toggleOrder());
            },
            tooltip: currentSort.order == SortOrder.ascending
                ? 'Ascending'
                : 'Descending',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
