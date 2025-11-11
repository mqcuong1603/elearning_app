import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_list_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';
import 'package:intl/intl.dart';

/// Semester Form Screen
/// Handles both Create and Edit modes for semesters
class SemesterFormScreen extends ConsumerStatefulWidget {
  final String? semesterId; // null = create mode, non-null = edit mode

  const SemesterFormScreen({super.key, this.semesterId});

  @override
  ConsumerState<SemesterFormScreen> createState() => _SemesterFormScreenState();
}

class _SemesterFormScreenState extends ConsumerState<SemesterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isLoading = false;
  SemesterEntity? _originalSemester;

  bool get _isEditMode => widget.semesterId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadSemesterData();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesterData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(semesterRepositoryProvider);
      final semester = await repository.getSemesterById(widget.semesterId!);

      if (!mounted) return;

      if (semester != null) {
        setState(() {
          _originalSemester = semester;
          _codeController.text = semester.code;
          _nameController.text = semester.name;
          _startDate = semester.startDate;
          _endDate = semester.endDate;
          _isCurrent = semester.isCurrent;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semester not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading semester: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, reset it
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 120)) ?? DateTime.now().add(const Duration(days: 120)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveSemester() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(semesterRepositoryProvider);
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();

      // Check for duplicate code (only if code changed in edit mode)
      if (!_isEditMode || (_isEditMode && code != _originalSemester!.code)) {
        final existing = await repository.getSemesterByCode(code);
        if (existing != null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Semester code "$code" already exists'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final entity = SemesterEntity(
        id: _isEditMode ? _originalSemester!.id : '', // Empty ID for create
        code: code,
        name: name,
        startDate: _startDate!,
        endDate: _endDate!,
        isCurrent: _isCurrent,
        createdAt: _isEditMode ? _originalSemester!.createdAt : DateTime.now(),
        updatedAt: _isEditMode ? DateTime.now() : null,
      );

      final success = _isEditMode
          ? await repository.updateSemester(entity)
          : await repository.createSemester(entity);

      if (!mounted) return;

      if (success) {
        // If marked as current, set it
        if (_isCurrent && (!_isEditMode || !_originalSemester!.isCurrent)) {
          await repository.setCurrentSemester(entity.id);
        }

        ref.invalidate(allSemestersProvider);
        ref.invalidate(currentSemesterProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Semester updated successfully'
                  : 'Semester created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Failed to update semester'
                  : 'Failed to create semester',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSemester() async {
    if (_originalSemester?.isCurrent == true) {
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
          'Are you sure you want to delete "${_originalSemester?.name}"?\n\n'
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

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(semesterRepositoryProvider);
      final success = await repository.deleteSemester(widget.semesterId!);

      if (!mounted) return;

      if (success) {
        ref.invalidate(allSemestersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semester deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete semester'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Semester' : 'Create Semester'),
        actions: [
          if (_isEditMode && _originalSemester?.isCurrent != true)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Semester',
              onPressed: _isLoading ? null : _deleteSemester,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Semester Code
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Semester Code *',
                        hintText: 'e.g., 2025-1, 2025-2',
                        helperText: 'Unique identifier for the semester',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Semester code is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Semester Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Semester Name *',
                        hintText: 'e.g., Semester 1 - Academic Year 2025-2026',
                        helperText: 'Full name of the semester',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Semester name is required';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Date Range Section
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Start Date
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        title: const Text('Start Date *'),
                        subtitle: Text(
                          _startDate != null
                              ? dateFormat.format(_startDate!)
                              : 'Not selected',
                          style: TextStyle(
                            color: _startDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // End Date
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available, color: Colors.green),
                        title: const Text('End Date *'),
                        subtitle: Text(
                          _endDate != null
                              ? dateFormat.format(_endDate!)
                              : 'Not selected',
                          style: TextStyle(
                            color: _endDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectEndDate,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Set as Current Checkbox
                    Card(
                      child: SwitchListTile(
                        value: _isCurrent,
                        onChanged: (value) {
                          setState(() => _isCurrent = value);
                        },
                        title: const Text('Set as Current Semester'),
                        subtitle: const Text(
                          'This will be the default semester shown throughout the app',
                        ),
                        secondary: Icon(
                          _isCurrent ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _isCurrent ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSemester,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_isEditMode ? 'Update' : 'Create'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Help Text
                    if (!_isEditMode)
                      Text(
                        'After creating the semester, you can add courses and groups to it.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
