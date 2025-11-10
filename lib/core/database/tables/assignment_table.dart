import '../database_config.dart';

class AssignmentTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableAssignments} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      course_id TEXT NOT NULL,
      created_by TEXT NOT NULL,
      attachment_urls TEXT,
      target_group_ids TEXT NOT NULL,
      start_date INTEGER NOT NULL,
      deadline INTEGER NOT NULL,
      allow_late_submission INTEGER NOT NULL DEFAULT 0,
      late_deadline INTEGER,
      max_submission_attempts INTEGER NOT NULL,
      allowed_file_formats TEXT NOT NULL,
      max_file_size_mb INTEGER NOT NULL,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_assignments_course_id ON ${DatabaseConfig.tableAssignments}(course_id)
  ''';

  static const String indexCreatedBy = '''
    CREATE INDEX idx_assignments_created_by ON ${DatabaseConfig.tableAssignments}(created_by)
  ''';

  static const String indexDeadline = '''
    CREATE INDEX idx_assignments_deadline ON ${DatabaseConfig.tableAssignments}(deadline)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexCreatedBy,
        indexDeadline,
      ];
}
