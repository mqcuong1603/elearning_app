import '../database_config.dart';

class QuestionTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableQuestions} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      course_id TEXT NOT NULL,
      question_text TEXT NOT NULL,
      choices TEXT NOT NULL,
      correct_answer_index INTEGER NOT NULL,
      difficulty TEXT NOT NULL,
      explanation TEXT,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE
    )
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_questions_course_id ON ${DatabaseConfig.tableQuestions}(course_id)
  ''';

  static const String indexDifficulty = '''
    CREATE INDEX idx_questions_difficulty ON ${DatabaseConfig.tableQuestions}(difficulty)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexCourse,
        indexDifficulty,
      ];
}
