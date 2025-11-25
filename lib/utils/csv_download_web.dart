import 'dart:html' as html;
import 'dart:convert';

/// Web-specific CSV download implementation
/// Triggers a browser download using the HTML Blob API
/// Returns null since web doesn't have a file path
Future<String?> downloadCsv(String csvString, String filename) async {
  final bytes = utf8.encode(csvString);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null; // No file path on web
}
