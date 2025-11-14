/// Stub file for CSV download functionality
/// This file is used when neither web nor IO implementations are available
Future<String?> downloadCsv(String csvString, String filename) async {
  throw UnsupportedError('CSV download is not supported on this platform');
}
