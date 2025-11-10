import '../database_config.dart';

class CourseTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableCourses} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      code TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      semester_id TEXT NOT NULL,
      instructor_id TEXT NOT NULL,
      cover_image_url TEXT,
      sessions INTEGER NOT NULL,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (semester_id) REFERENCES ${DatabaseConfig.tableSemesters}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (instructor_id) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCode = '''
    CREATE INDEX idx_courses_code ON ${DatabaseConfig.tableCourses}(code)
  ''';

  static const String indexSemester = '''
    CREATE INDEX idx_courses_semester_id ON ${DatabaseConfig.tableCourses}(semester_id)
  ''';

  static const String indexInstructor = '''
    CREATE INDEX idx_courses_instructor_id ON ${DatabaseConfig.tableCourses}(instructor_id)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCode,
        indexSemester,
        indexInstructor,
      ];
}
