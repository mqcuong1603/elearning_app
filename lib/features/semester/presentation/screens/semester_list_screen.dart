import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_list_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';
import 'package:intl/intl.dart';

/// Semester List Screen
/// PDF Requirement: Admin manages semesters, sets current semester
class SemesterListScreen extends ConsumerWidget {
  const SemesterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(allSemestersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Management'),
        actions: [
          // CSV Import Button
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import from CSV',
            onPressed: () => context.push('/semesters/import'),
          ),
          // Add New Semester
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Semester',
            onPressed: () => context.push('/semesters/new'),
          ),
        ],
      ),
      body: semestersAsync.when(
        data: (semesters) {
          if (semesters.isEmpty) {
            return _buildEmptyState(context);
          }

          // Sort: current first, then by start date descending
          final sortedSemesters = List<SemesterEntity>.from(semesters)
            ..sort((a, b) {
              if (a.isCurrent && !b.isCurrent) return -1;
              if (!a.isCurrent && b.isCurrent) return 1;
              return b.startDate.compareTo(a.startDate);
            });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allSemestersProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedSemesters.length,
              itemBuilder: (context, index) {
                return _SemesterCard(
                  semester: sortedSemesters[index],
                  onTap: () => context.push('/semesters/${sortedSemesters[index].id}/edit'),
                  onSetCurrent: () => _setCurrentSemester(context, ref, sortedSemesters[index]),
                  onDelete: () => _deleteSemester(context, ref, sortedSemesters[index]),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading semesters',
                style: TextStyle(color: Colors.red[700], fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(allSemestersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Semesters Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first semester to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/semesters/new'),
            icon: const Icon(Icons.add),
            label: const Text('Create Semester'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setCurrentSemester(
    BuildContext context,
    WidgetRef ref,
    SemesterEntity semester,
  ) async {
    if (semester.isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is already the current semester')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Current Semester'),
        content: Text(
          'Set "${semester.name}" as the current semester?\n\n'
          'This will update all views to show this semester by default.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Set Current'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final repository = ref.read(semesterRepositoryProvider);
      final success = await repository.setCurrentSemester(semester.id);

      if (!context.mounted) return;

      if (success) {
        ref.invalidate(allSemestersProvider);
        ref.invalidate(currentSemesterProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${semester.name} is now the current semester'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set current semester'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSemester(
    BuildContext context,
    WidgetRef ref,
    SemesterEntity semester,
  ) async {
    if (semester.isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the current semester'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text(
          'Are you sure you want to delete "${semester.name}"?\n\n'
          'This will also delete all courses, groups, and enrollments in this semester. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final repository = ref.read(semesterRepositoryProvider);
      final success = await repository.deleteSemester(semester.id);

      if (!context.mounted) return;

      if (success) {
        ref.invalidate(allSemestersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semester deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete semester'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Semester Card Widget
class _SemesterCard extends StatelessWidget {
  final SemesterEntity semester;
  final VoidCallback onTap;
  final VoidCallback onSetCurrent;
  final VoidCallback onDelete;

  const _SemesterCard({
    required this.semester,
    required this.onTap,
    required this.onSetCurrent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: semester.isCurrent ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Semester Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: semester.isCurrent
                          ? Colors.blue
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: semester.isCurrent ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Semester Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                semester.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (semester.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${semester.code}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(semester.startDate)} - ${dateFormat.format(semester.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),

              // Course & Student Count
              if (semester.courseCount != null || semester.studentCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (semester.courseCount != null) ...[
                        Icon(Icons.book, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${semester.courseCount} courses',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (semester.studentCount != null) ...[
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${semester.studentCount} students',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!semester.isCurrent)
                    TextButton.icon(
                      onPressed: onSetCurrent,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set as Current'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  if (!semester.isCurrent)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
