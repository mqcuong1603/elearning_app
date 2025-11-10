import '../database_config.dart';

class SemesterTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableSemesters} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      start_date INTEGER NOT NULL,
      end_date INTEGER NOT NULL,
      is_current INTEGER NOT NULL DEFAULT 0,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER
    )
  ''';

  static const String indexCode = '''
    CREATE INDEX idx_semesters_code ON ${DatabaseConfig.tableSemesters}(code)
  ''';

  static const String indexCurrent = '''
    CREATE INDEX idx_semesters_is_current ON ${DatabaseConfig.tableSemesters}(is_current)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCode,
        indexCurrent,
      ];
}
