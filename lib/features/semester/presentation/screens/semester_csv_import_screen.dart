import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_repository_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/semester_list_provider.dart';
import 'package:elearning_app/features/semester/presentation/providers/current_semester_provider.dart';
import 'package:intl/intl.dart';

/// Semester CSV Import Screen
/// Allows importing semesters from CSV with preview and validation
///
/// Expected CSV Format:
/// code,name,start_date,end_date,is_current
/// 2025-1,Semester 1 - Academic Year 2025-2026,2025-01-15,2025-06-30,true
/// 2025-2,Semester 2 - Academic Year 2025-2026,2025-08-01,2025-12-20,false
class SemesterCsvImportScreen extends ConsumerStatefulWidget {
  const SemesterCsvImportScreen({super.key});

  @override
  ConsumerState<SemesterCsvImportScreen> createState() =>
      _SemesterCsvImportScreenState();
}

class _SemesterCsvImportScreenState
    extends ConsumerState<SemesterCsvImportScreen> {
  List<List<dynamic>> _csvData = [];
  List<_SemesterImportRow> _parsedRows = [];
  bool _isLoading = false;
  String? _fileName;
  bool _hasHeader = true;

  final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final csvString = await file.readAsString();

        // Parse CSV
        final csvData = const CsvToListConverter().convert(csvString);

        if (csvData.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV file is empty'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _csvData = csvData;
          _fileName = result.files.first.name;
          _parsedRows = _parseRows(csvData);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<_SemesterImportRow> _parseRows(List<List<dynamic>> csvData) {
    final rows = <_SemesterImportRow>[];
    final startIndex = _hasHeader ? 1 : 0;

    for (int i = startIndex; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }

      final parsedRow = _SemesterImportRow(
        rowNumber: i + 1,
        rawData: row,
      );

      // Validate and parse
      if (row.length < 5) {
        parsedRow.errors.add('Insufficient columns (expected 5: code, name, start_date, end_date, is_current)');
      } else {
        // Parse code
        final code = row[0].toString().trim();
        if (code.isEmpty) {
          parsedRow.errors.add('Code is required');
        } else {
          parsedRow.code = code;
        }

        // Parse name
        final name = row[1].toString().trim();
        if (name.isEmpty) {
          parsedRow.errors.add('Name is required');
        } else {
          parsedRow.name = name;
        }

        // Parse start date
        try {
          final startDateStr = row[2].toString().trim();
          parsedRow.startDate = _dateFormat.parse(startDateStr);
        } catch (e) {
          parsedRow.errors.add('Invalid start date format (expected yyyy-MM-dd)');
        }

        // Parse end date
        try {
          final endDateStr = row[3].toString().trim();
          parsedRow.endDate = _dateFormat.parse(endDateStr);
        } catch (e) {
          parsedRow.errors.add('Invalid end date format (expected yyyy-MM-dd)');
        }

        // Validate date range
        if (parsedRow.startDate != null &&
            parsedRow.endDate != null &&
            parsedRow.endDate!.isBefore(parsedRow.startDate!)) {
          parsedRow.errors.add('End date must be after start date');
        }

        // Parse isCurrent
        final isCurrentStr = row[4].toString().trim().toLowerCase();
        if (isCurrentStr == 'true' || isCurrentStr == '1' || isCurrentStr == 'yes') {
          parsedRow.isCurrent = true;
        } else if (isCurrentStr == 'false' || isCurrentStr == '0' || isCurrentStr == 'no') {
          parsedRow.isCurrent = false;
        } else {
          parsedRow.errors.add('Invalid is_current value (expected true/false, 1/0, yes/no)');
        }
      }

      rows.add(parsedRow);
    }

    return rows;
  }

  Future<void> _importData() async {
    final validRows = _parsedRows.where((row) => row.isValid).toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid rows to import'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for duplicate codes
    final repository = ref.read(semesterRepositoryProvider);
    final duplicates = <String>[];

    for (final row in validRows) {
      final existing = await repository.getSemesterByCode(row.code!);
      if (existing != null) {
        duplicates.add(row.code!);
      }
    }

    if (duplicates.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Codes Found'),
          content: Text(
            'The following semester codes already exist:\n\n'
            '${duplicates.join(', ')}\n\n'
            'These rows will be skipped. Continue with remaining rows?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final entities = validRows
          .where((row) => !duplicates.contains(row.code))
          .map((row) => SemesterEntity(
                id: '', // Will be generated by database
                code: row.code!,
                name: row.name!,
                startDate: row.startDate!,
                endDate: row.endDate!,
                isCurrent: row.isCurrent!,
                createdAt: DateTime.now(),
              ))
          .toList();

      final ids = await repository.insertBatch(entities);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ref.invalidate(allSemestersProvider);
      ref.invalidate(currentSemesterProvider);

      if (!mounted) return;

      // Show results dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Successfully imported: ${ids.length}'),
                ],
              ),
              if (duplicates.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.skip_next, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Skipped (duplicates): ${duplicates.length}'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                      'Failed (invalid): ${_parsedRows.length - validRows.length}'),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop(); // Return to semester list
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _parsedRows.where((row) => row.isValid).length;
    final invalidCount = _parsedRows.length - validCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Semesters from CSV'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Instructions Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'CSV Format Requirements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Expected columns (in order):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1. code (e.g., "2025-1")\n'
                          '2. name (e.g., "Semester 1 - Academic Year 2025-2026")\n'
                          '3. start_date (format: yyyy-MM-dd)\n'
                          '4. end_date (format: yyyy-MM-dd)\n'
                          '5. is_current (true/false)',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _hasHeader,
                              onChanged: (value) {
                                setState(() {
                                  _hasHeader = value ?? true;
                                  if (_csvData.isNotEmpty) {
                                    _parsedRows = _parseRows(_csvData);
                                  }
                                });
                              },
                            ),
                            const Text('First row is header'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // File Selection
                if (_fileName == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Select CSV File'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // File info and stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fileName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _csvData = [];
                                  _parsedRows = [];
                                  _fileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              icon: Icons.list_alt,
                              label: 'Total',
                              value: _parsedRows.length.toString(),
                              color: Colors.blue,
                            ),
                            _StatChip(
                              icon: Icons.check_circle,
                              label: 'Valid',
                              value: validCount.toString(),
                              color: Colors.green,
                            ),
                            _StatChip(
                              icon: Icons.error,
                              label: 'Invalid',
                              value: invalidCount.toString(),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Preview Table
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _parsedRows.length,
                      itemBuilder: (context, index) {
                        final row = _parsedRows[index];
                        return _ImportRowCard(row: row, dateFormat: _dateFormat);
                      },
                    ),
                  ),

                  // Import Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickFile,
                            child: const Text('Choose Different File'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: validCount > 0 ? _importData : null,
                            icon: const Icon(Icons.upload),
                            label: Text('Import $validCount Semesters'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Import row data model
class _SemesterImportRow {
  final int rowNumber;
  final List<dynamic> rawData;
  final List<String> errors = [];

  String? code;
  String? name;
  DateTime? startDate;
  DateTime? endDate;
  bool? isCurrent;

  _SemesterImportRow({
    required this.rowNumber,
    required this.rawData,
  });

  bool get isValid => errors.isEmpty && code != null && name != null;
}

/// Stat chip widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Import row card widget
class _ImportRowCard extends StatelessWidget {
  final _SemesterImportRow row;
  final DateFormat dateFormat;

  const _ImportRowCard({
    required this.row,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: row.isValid ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  row.isValid ? Icons.check_circle : Icons.error,
                  color: row.isValid ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Row ${row.rowNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: row.isValid ? Colors.green[900] : Colors.red[900],
                  ),
                ),
                const Spacer(),
                if (row.isCurrent == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            if (row.code != null) ...[
              const SizedBox(height: 8),
              Text(
                '${row.code} - ${row.name ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            if (row.startDate != null && row.endDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '${dateFormat.format(row.startDate!)} to ${dateFormat.format(row.endDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
            if (row.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...row.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
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
