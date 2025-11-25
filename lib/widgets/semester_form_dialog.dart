import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';
import '../models/semester_model.dart';
import '../providers/semester_provider.dart';

class SemesterFormDialog extends StatefulWidget {
  final SemesterModel? semester;

  const SemesterFormDialog({
    super.key,
    this.semester,
  });

  @override
  State<SemesterFormDialog> createState() => _SemesterFormDialogState();
}

class _SemesterFormDialogState extends State<SemesterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late bool _isCurrent;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditMode => widget.semester != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.semester?.code ?? '');
    _nameController = TextEditingController(text: widget.semester?.name ?? '');
    _isCurrent = widget.semester?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<SemesterProvider>();
      bool success;

      if (_isEditMode) {
        // Update existing semester
        final updatedSemester = widget.semester!.copyWith(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          isCurrent: _isCurrent,
          updatedAt: DateTime.now(),
        );
        success = await provider.updateSemester(updatedSemester);
      } else {
        // Create new semester
        success = await provider.createSemester(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          isCurrent: _isCurrent,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _errorMessage = provider.errorMessage ?? 'Operation failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? 'Edit Semester' : 'Create New Semester'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Code field
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Semester Code',
                  hintText: 'e.g., 2024-1',
                  prefixIcon: Icon(Icons.tag),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.validationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Semester Name',
                  hintText: 'e.g., Fall 2024',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.validationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Mark as current checkbox
              CheckboxListTile(
                value: _isCurrent,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isCurrent = value ?? false;
                        });
                      },
                title: const Text('Mark as current semester'),
                subtitle: const Text(
                  'This will unmarked all other semesters',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isEditMode ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
