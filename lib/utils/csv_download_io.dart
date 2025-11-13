import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// IO-specific CSV download implementation (Desktop/Mobile)
/// Saves the CSV file to the documents directory
Future<String> downloadCsv(String csvString, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(csvString);
  return file.path;
}
