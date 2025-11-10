import '../database_config.dart';

class GroupTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableGroups} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      course_id TEXT NOT NULL,
      semester_id TEXT NOT NULL,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (semester_id) REFERENCES ${DatabaseConfig.tableSemesters}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_groups_course_id ON ${DatabaseConfig.tableGroups}(course_id)
  ''';

  static const String indexSemester = '''
    CREATE INDEX idx_groups_semester_id ON ${DatabaseConfig.tableGroups}(semester_id)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexSemester,
      ];
}
