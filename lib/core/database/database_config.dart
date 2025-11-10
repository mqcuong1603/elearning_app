/// Database configuration constants
class DatabaseConfig {
  // Database info
  static const String databaseName = 'elearning.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableUsers = 'users';
  static const String tableSemesters = 'semesters';
  static const String tableCourses = 'courses';
  static const String tableGroups = 'groups';
  static const String tableStudentEnrollments = 'student_enrollments';
  static const String tableAnnouncements = 'announcements';
  static const String tableAssignments = 'assignments';
  static const String tableQuizzes = 'quizzes';
  static const String tableQuestions = 'questions';
  static const String tableMaterials = 'materials';
  static const String tableSubmissions = 'submissions';
  static const String tableQuizAttempts = 'quiz_attempts';
  static const String tableForums = 'forums';
  static const String tableForumPosts = 'forum_posts';
  static const String tableMessages = 'messages';
  static const String tableNotifications = 'notifications';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableViewTracking = 'view_tracking';
  static const String tableDownloadTracking = 'download_tracking';

  // Common column names
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Prevent instantiation
  DatabaseConfig._();
}
