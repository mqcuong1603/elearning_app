import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_constants.dart';

/// CSV Service
/// Handles CSV import/export with preview and validation
class CsvService {
  /// Pick and parse CSV file
  Future<List<Map<String, String>>> pickAndParseCsv({
    required List<String> expectedHeaders,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = result.files.first;
      String csvString;

      // Handle different platforms
      if (kIsWeb) {
        // Web: Use bytes
        if (file.bytes == null) {
          throw Exception('Could not read file');
        }
        csvString = utf8.decode(file.bytes!);
      } else {
        // Desktop/Mobile: Use path
        if (file.path == null) {
          throw Exception('Could not get file path');
        }
        final fileContent = File(file.path!);
        csvString = await fileContent.readAsString();
      }

      return parseCsvString(
        csvString: csvString,
        expectedHeaders: expectedHeaders,
      );
    } catch (e) {
      print('Pick and parse CSV error: $e');
      throw Exception('Failed to read CSV file: ${e.toString()}');
    }
  }

  /// Parse CSV string
  List<Map<String, String>> parseCsvString({
    required String csvString,
    required List<String> expectedHeaders,
  }) {
    try {
      final csvConverter = const CsvToListConverter();
      final List<List<dynamic>> csvData = csvConverter.convert(csvString);

      if (csvData.isEmpty) {
        throw Exception(AppConstants.errorCsvEmpty);
      }

      // Get headers from first row
      final headers = csvData.first.map((e) => e.toString().trim()).toList();

      // Validate headers
      if (!_validateHeaders(headers, expectedHeaders)) {
        throw Exception(
          'Invalid CSV format. Expected headers: ${expectedHeaders.join(", ")}, but got: ${headers.join(", ")}',
        );
      }

      // Parse data rows
      final result = <Map<String, String>>[];

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];

        // Skip empty rows
        if (row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        final rowData = <String, String>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowData[headers[j]] = row[j].toString().trim();
        }

        result.add(rowData);
      }

      return result;
    } catch (e) {
      print('Parse CSV string error: $e');
      throw Exception(e.toString());
    }
  }

  /// Validate CSV headers
  bool _validateHeaders(List<String> actualHeaders, List<String> expectedHeaders) {
    if (actualHeaders.length != expectedHeaders.length) {
      print('Header length mismatch: expected ${expectedHeaders.length}, got ${actualHeaders.length}');
      return false;
    }

    for (int i = 0; i < expectedHeaders.length; i++) {
      if (actualHeaders[i].toLowerCase() != expectedHeaders[i].toLowerCase()) {
        print('Header mismatch at position $i: expected "${expectedHeaders[i]}", got "${actualHeaders[i]}"');
        return false;
      }
    }

    return true;
  }

  /// Preview CSV data with validation
  Map<String, dynamic> previewCsvData({
    required List<Map<String, String>> data,
    required List<String> requiredFields,
    Future<bool> Function(Map<String, String>)? checkExists,
  }) {
    final preview = <Map<String, dynamic>>[];

    for (final row in data) {
      final previewRow = <String, dynamic>{
        'data': row,
        'status': AppConstants.csvStatusWillBeAdded,
        'error': null,
      };

      // Validate required fields
      for (final field in requiredFields) {
        if (row[field] == null || row[field]!.isEmpty) {
          previewRow['status'] = AppConstants.csvStatusError;
          previewRow['error'] = 'Missing required field: $field';
          break;
        }
      }

      preview.add(previewRow);
    }

    return {
      'total': data.length,
      'preview': preview,
      'willBeAdded': preview.where((p) => p['status'] == AppConstants.csvStatusWillBeAdded).length,
      'errors': preview.where((p) => p['status'] == AppConstants.csvStatusError).length,
    };
  }

  /// Export data to CSV string
  String exportToCsvString({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    try {
      final csvData = [headers, ...rows];
      final csvConverter = const ListToCsvConverter();
      return csvConverter.convert(csvData);
    } catch (e) {
      print('Export to CSV string error: $e');
      throw Exception('Failed to export CSV: ${e.toString()}');
    }
  }

  /// Export data to CSV file
  Future<void> exportToCsv(
    List<Map<String, dynamic>> data,
    String filename,
  ) async {
    try {
      if (data.isEmpty) {
        throw Exception('No data to export');
      }

      // Extract headers from first row
      final headers = data.first.keys.toList();

      // Convert data to rows
      final rows = data.map((row) {
        return headers.map((header) => row[header] ?? '').toList();
      }).toList();

      // Generate CSV string
      final csvString = exportToCsvString(
        headers: headers,
        rows: rows,
      );

      // Download file
      downloadCsvFile(csvString: csvString, filename: filename);
    } catch (e) {
      print('Export to CSV error: $e');
      throw Exception('Failed to export CSV: ${e.toString()}');
    }
  }

  /// Download CSV file (for web)
  void downloadCsvFile({
    required String csvString,
    required String filename,
  }) {
    // This will be implemented differently for web vs mobile
    // For now, just log
    print('Download CSV: $filename');
    // TODO: Implement platform-specific download
  }

  /// Generate sample CSV template
  String generateSampleCsv({
    required List<String> headers,
    List<List<String>>? sampleData,
  }) {
    final csvData = [
      headers,
      if (sampleData != null) ...sampleData,
    ];

    final csvConverter = const ListToCsvConverter();
    return csvConverter.convert(csvData);
  }

  /// Validate semester CSV data
  Map<String, dynamic> validateSemesterCsv(List<Map<String, String>> data) {
    return previewCsvData(
      data: data,
      requiredFields: AppConstants.csvHeadersSemesters,
    );
  }

  /// Validate course CSV data
  Map<String, dynamic> validateCourseCsv(List<Map<String, String>> data) {
    final preview = previewCsvData(
      data: data,
      requiredFields: AppConstants.csvHeadersCourses,
    );

    // Additional validation for courses
    for (final row in preview['preview']) {
      final sessions = int.tryParse(row['data']['sessions'] ?? '');
      if (sessions == null || !AppConstants.allowedCourseSessions.contains(sessions)) {
        row['status'] = AppConstants.csvStatusError;
        row['error'] = 'Sessions must be 10 or 15';
      }
    }

    return preview;
  }

  /// Validate student CSV data
  Map<String, dynamic> validateStudentCsv(List<Map<String, String>> data) {
    final preview = previewCsvData(
      data: data,
      requiredFields: AppConstants.csvHeadersStudents,
    );

    // Additional validation for students
    for (final row in preview['preview']) {
      final email = row['data']['email'] ?? '';
      if (!_isValidEmail(email)) {
        row['status'] = AppConstants.csvStatusError;
        row['error'] = 'Invalid email format';
      }
    }

    return preview;
  }

  /// Validate group CSV data
  Map<String, dynamic> validateGroupCsv(List<Map<String, String>> data) {
    return previewCsvData(
      data: data,
      requiredFields: AppConstants.csvHeadersGroups,
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Get CSV template for semesters
  String getSemesterCsvTemplate() {
    return generateSampleCsv(
      headers: AppConstants.csvHeadersSemesters,
      sampleData: [
        ['2024-1', 'Fall 2024'],
        ['2024-2', 'Spring 2025'],
      ],
    );
  }

  /// Get CSV template for courses
  String getCourseCsvTemplate() {
    return generateSampleCsv(
      headers: AppConstants.csvHeadersCourses,
      sampleData: [
        ['CS101', 'Introduction to Programming', '15', 'semester-id'],
        ['CS102', 'Data Structures', '15', 'semester-id'],
      ],
    );
  }

  /// Get CSV template for students
  String getStudentCsvTemplate() {
    return generateSampleCsv(
      headers: AppConstants.csvHeadersStudents,
      sampleData: [
        ['2024001', 'John Doe', 'john.doe@university.edu', 'password123'],
        ['2024002', 'Jane Smith', 'jane.smith@university.edu', 'password456'],
      ],
    );
  }

  /// Get CSV template for groups
  String getGroupCsvTemplate() {
    return generateSampleCsv(
      headers: AppConstants.csvHeadersGroups,
      sampleData: [
        ['Group 1', 'course-id'],
        ['Group 2', 'course-id'],
      ],
    );
  }
}
