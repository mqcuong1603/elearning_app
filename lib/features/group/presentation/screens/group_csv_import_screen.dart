import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:elearning_app/features/group/domain/entities/group_entity.dart';
import 'package:elearning_app/features/group/presentation/providers/group_repository_provider.dart';
import 'package:elearning_app/features/group/presentation/providers/group_list_provider.dart';
import 'package:elearning_app/features/course/presentation/providers/course_repository_provider.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';

/// Group CSV Import Screen
/// Expected CSV format: name,course_code
/// PDF Requirement: One group per course - enforces during import
/// Shows smart preview with validation status
class GroupCsvImportScreen extends ConsumerStatefulWidget {
  final String courseId;

  const GroupCsvImportScreen({super.key, required this.courseId});

  @override
  ConsumerState<GroupCsvImportScreen> createState() => _GroupCsvImportScreenState();
}

class _GroupCsvImportScreenState extends ConsumerState<GroupCsvImportScreen> {
  String? _fileName;
  List<List<dynamic>>? _csvData;
  List<_GroupImportRow> _parsedRows = [];
  bool _hasHeader = true;
  bool _isImporting = false;
  CourseEntity? _course;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    final repository = ref.read(courseRepositoryProvider);
    final course = await repository.getCourseById(widget.courseId);
    if (mounted) {
      setState(() {
        _course = course;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Groups from CSV'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Context Card
            if (_course != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _course!.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _course!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Importing groups for this course',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'CSV Format Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Expected CSV format:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'name,course_code\n'
                        'Group 1,CS101\n'
                        'Group A,CS102',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'PDF Requirement: One group per course. Courses with existing groups will be skipped.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Picker Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select CSV File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),

            if (_fileName != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_fileName!),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _fileName = null;
                        _csvData = null;
                        _parsedRows = [];
                      });
                    },
                  ),
                ),
              ),
            ],

            // Header Checkbox
            if (_csvData != null) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('First row is header'),
                value: _hasHeader,
                onChanged: (value) {
                  setState(() {
                    _hasHeader = value ?? true;
                    _parseData();
                  });
                },
              ),
            ],

            // Preview Section
            if (_parsedRows.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildPreviewSection(),
              const SizedBox(height: 24),
              _buildImportButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final validRows = _parsedRows.where((r) => r.isValid).toList();
    final invalidRows = _parsedRows.where((r) => !r.isValid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Stats
        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBadge(
                  label: 'Valid',
                  count: validRows.length,
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                _StatBadge(
                  label: 'Invalid',
                  count: invalidRows.length,
                  color: Colors.red,
                  icon: Icons.error,
                ),
                _StatBadge(
                  label: 'Total',
                  count: _parsedRows.length,
                  color: Colors.blue,
                  icon: Icons.list_alt,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Preview List
        const Text(
          'Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parsedRows.length,
          itemBuilder: (context, index) {
            final row = _parsedRows[index];
            return _GroupImportCard(row: row);
          },
        ),
      ],
    );
  }

  Widget _buildImportButton() {
    final validRows = _parsedRows.where((r) => r.isValid).toList();

    if (validRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isImporting ? null : _importData,
        icon: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(_isImporting ? 'Importing...' : 'Import ${validRows.length} Groups'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes);
        final csvData = const CsvToListConverter().convert(csvString);

        setState(() {
          _fileName = result.files.single.name;
          _csvData = csvData;
        });

        await _parseData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseData() async {
    if (_csvData == null || _csvData!.isEmpty) return;

    final courseRepository = ref.read(courseRepositoryProvider);
    final groupRepository = ref.read(groupRepositoryProvider);

    // Get all courses and existing groups for validation
    final allCourses = await courseRepository.getAllCourses();
    final courseMap = {for (var c in allCourses) c.code.toLowerCase(): c};

    final rows = <_GroupImportRow>[];
    final startIndex = _hasHeader ? 1 : 0;

    for (int i = startIndex; i < _csvData!.length; i++) {
      final row = _csvData![i];
      if (row.length < 2) continue;

      final parsedRow = _GroupImportRow(rowNumber: i + 1, rawData: row);

      // Parse name
      parsedRow.name = row[0].toString().trim();
      if (parsedRow.name!.isEmpty) {
        parsedRow.errors.add('Name is required');
      }

      // Parse and validate course code
      final courseCode = row[1].toString().trim();
      parsedRow.courseCode = courseCode;

      final course = courseMap[courseCode.toLowerCase()];
      if (course == null) {
        parsedRow.errors.add('Course "$courseCode" not found');
      } else {
        parsedRow.course = course;

        // Check if course already has a group (ONE GROUP PER COURSE rule)
        final existingGroups = await groupRepository.getGroupsByCourse(course.id);
        if (existingGroups.isNotEmpty) {
          parsedRow.errors.add('Course already has group "${existingGroups.first.name}"');
          parsedRow.hasExistingGroup = true;
        }
      }

      rows.add(parsedRow);
    }

    if (mounted) {
      setState(() {
        _parsedRows = rows;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final repository = ref.read(groupRepositoryProvider);
      final validRows = _parsedRows.where((r) => r.isValid).toList();

      if (validRows.isEmpty) {
        throw Exception('No valid groups to import');
      }

      // Convert to entities
      final entities = validRows.map((row) {
        return GroupEntity(
          id: const Uuid().v4(),
          name: row.name!,
          courseId: row.course!.id,
          semesterId: row.course!.semesterId,
          createdAt: DateTime.now(),
        );
      }).toList();

      // Batch insert
      final insertedIds = await repository.insertBatch(entities);

      final skippedCount = _parsedRows.length - validRows.length;

      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        // Show results dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Import Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultRow(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: 'Successfully imported',
                  count: insertedIds.length,
                ),
                if (skippedCount > 0) ...[
                  const SizedBox(height: 8),
                  _ResultRow(
                    icon: Icons.warning,
                    color: Colors.orange,
                    label: 'Skipped (invalid/duplicate)',
                    count: skippedCount,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Groups have been created. Students can now be assigned to these groups.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop(); // Go back to group list
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );

        // Refresh the groups list
        ref.invalidate(groupsByCourseWithCountsProvider(widget.courseId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper Models and Widgets

class _GroupImportRow {
  final int rowNumber;
  final List<dynamic> rawData;
  String? name;
  String? courseCode;
  CourseEntity? course;
  bool hasExistingGroup = false;
  List<String> errors = [];

  _GroupImportRow({
    required this.rowNumber,
    required this.rawData,
  });

  bool get isValid => errors.isEmpty && name != null && course != null;
}

class _GroupImportCard extends StatelessWidget {
  final _GroupImportRow row;

  const _GroupImportCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final isValid = row.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isValid ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Row ${row.rowNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isValid ? 'VALID' : 'INVALID',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Name: ${row.name ?? 'N/A'}'),
            Text('Course: ${row.courseCode ?? 'N/A'}'),
            if (row.course != null)
              Text(
                'Course Name: ${row.course!.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            if (row.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...row.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
