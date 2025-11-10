import '../database_config.dart';

class MaterialTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableMaterials} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      course_id TEXT NOT NULL,
      created_by TEXT NOT NULL,
      file_urls TEXT,
      link_urls TEXT,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_materials_course_id ON ${DatabaseConfig.tableMaterials}(course_id)
  ''';

  static const String indexCreatedBy = '''
    CREATE INDEX idx_materials_created_by ON ${DatabaseConfig.tableMaterials}(created_by)
  ''';

  static const String indexCreatedAt = '''
    CREATE INDEX idx_materials_created_at ON ${DatabaseConfig.tableMaterials}(${DatabaseConfig.columnCreatedAt} DESC)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexCreatedBy,
        indexCreatedAt,
      ];
}
