import '../database_config.dart';

class QuizTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableQuizzes} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      course_id TEXT NOT NULL,
      created_by TEXT NOT NULL,
      target_group_ids TEXT NOT NULL,
      open_time INTEGER NOT NULL,
      close_time INTEGER NOT NULL,
      max_attempts INTEGER NOT NULL,
      duration_minutes INTEGER NOT NULL,
      easy_questions_count INTEGER NOT NULL,
      medium_questions_count INTEGER NOT NULL,
      hard_questions_count INTEGER NOT NULL,
      fixed_question_ids TEXT,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_quizzes_course_id ON ${DatabaseConfig.tableQuizzes}(course_id)
  ''';

  static const String indexCreatedBy = '''
    CREATE INDEX idx_quizzes_created_by ON ${DatabaseConfig.tableQuizzes}(created_by)
  ''';

  static const String indexOpenTime = '''
    CREATE INDEX idx_quizzes_open_time ON ${DatabaseConfig.tableQuizzes}(open_time)
  ''';

  static const String indexCloseTime = '''
    CREATE INDEX idx_quizzes_close_time ON ${DatabaseConfig.tableQuizzes}(close_time)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexCreatedBy,
        indexOpenTime,
        indexCloseTime,
      ];
}
