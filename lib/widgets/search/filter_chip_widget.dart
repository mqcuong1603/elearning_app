import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable filter chip widget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function() onTap;
  final IconData? icon;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppTheme.textOnPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: AppTheme.spacingXS),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.textOnPrimaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter section with multiple chips
class FilterSectionWidget extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String) onToggle;
  final bool allowMultiple;

  const FilterSectionWidget({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onToggle,
    this.allowMultiple = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChipWidget(
              label: option,
              isSelected: isSelected,
              onTap: () => onToggle(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
