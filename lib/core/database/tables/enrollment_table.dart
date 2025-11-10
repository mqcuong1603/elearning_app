import '../database_config.dart';

class EnrollmentTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableStudentEnrollments} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      group_id TEXT NOT NULL,
      course_id TEXT NOT NULL,
      semester_id TEXT NOT NULL,
      enrolled_at INTEGER NOT NULL,
      ${DatabaseConfig.columnUpdatedAt} INTEGER,
      FOREIGN KEY (student_id) REFERENCES ${DatabaseConfig.tableUsers}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (group_id) REFERENCES ${DatabaseConfig.tableGroups}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (course_id) REFERENCES ${DatabaseConfig.tableCourses}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      FOREIGN KEY (semester_id) REFERENCES ${DatabaseConfig.tableSemesters}(${DatabaseConfig.columnId}) ON DELETE CASCADE,
      UNIQUE(student_id, course_id, semester_id)
    )
  ''';

  static const String indexStudent = '''
    CREATE INDEX idx_enrollments_student_id ON ${DatabaseConfig.tableStudentEnrollments}(student_id)
  ''';

  static const String indexGroup = '''
    CREATE INDEX idx_enrollments_group_id ON ${DatabaseConfig.tableStudentEnrollments}(group_id)
  ''';

  static const String indexCourse = '''
    CREATE INDEX idx_enrollments_course_id ON ${DatabaseConfig.tableStudentEnrollments}(course_id)
  ''';

  static const String indexSemester = '''
    CREATE INDEX idx_enrollments_semester_id ON ${DatabaseConfig.tableStudentEnrollments}(semester_id)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexStudent,
        indexGroup,
        indexCourse,
        indexSemester,
      ];
}
