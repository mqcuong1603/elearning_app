import '../database_config.dart';

class AnnouncementTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableAnnouncements} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      course_id TEXT NOT NULL,
      created_by TEXT NOT NULL,
      attachment_urls TEXT,
      target_group_ids TEXT NOT NULL,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_announcements_course_id ON ${DatabaseConfig.tableAnnouncements}(course_id)
  ''';

  static const String indexCreatedBy = '''
    CREATE INDEX idx_announcements_created_by ON ${DatabaseConfig.tableAnnouncements}(created_by)
  ''';

  static const String indexCreatedAt = '''
    CREATE INDEX idx_announcements_created_at ON ${DatabaseConfig.tableAnnouncements}(${DatabaseConfig.columnCreatedAt} DESC)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexCreatedBy,
        indexCreatedAt,
      ];
}
