/// App-wide constants for the E-Learning Management Application
class AppConstants {
  // App Info
  static const String appName = 'E-Learning Management';
  static const String appVersion = '1.0.0';

  // Admin Credentials (Hardcoded as per requirement)
  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin';

  // User Roles
  static const String roleInstructor = 'instructor';
  static const String roleStudent = 'student';

  // File Upload Limits
  static const int maxFileSizeMB = 50; // 50 MB
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> allowedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv'
  ];
  static const List<String> allowedVideoFormats = ['mp4', 'avi', 'mov', 'wmv'];
  static const List<String> allowedArchiveFormats = ['zip', 'rar', '7z'];

  // Assignment Defaults
  static const int defaultMaxAttempts = 3;
  static const int defaultMaxSubmissionSizeMB = 25;

  // Quiz Defaults
  static const int defaultQuizDurationMinutes = 60;
  static const int defaultMaxQuizAttempts = 2;
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';

  // Course Defaults
  static const int defaultCourseSessions = 15;
  static const List<int> allowedCourseSessions = [10, 15];

  // Pagination
  static const int itemsPerPage = 20;
  static const int searchDebounceMilliseconds = 500;

  // Cache Duration
  static const Duration cacheValidDuration = Duration(hours: 6);
  static const Duration shortCacheDuration = Duration(minutes: 15);

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // CSV Headers
  static const List<String> csvHeadersStudents = [
    'studentId',
    'fullName',
    'email',
    'password'
  ];
  static const List<String> csvHeadersSemesters = ['code', 'name'];
  static const List<String> csvHeadersCourses = [
    'code',
    'name',
    'sessions',
    'semesterId'
  ];
  static const List<String> csvHeadersGroups = ['name', 'courseId'];
  static const List<String> csvHeadersStudentGroups = ['studentId', 'groupId'];

  // CSV Import Statuses
  static const String csvStatusWillBeAdded = 'will be added';
  static const String csvStatusAlreadyExists = 'already exists';
  static const String csvStatusError = 'error - invalid format';
  static const String csvStatusSuccess = 'success';
  static const String csvStatusFailed = 'failed';

  // Notification Types
  static const String notificationTypeAnnouncement = 'announcement';
  static const String notificationTypeAssignment = 'assignment';
  static const String notificationTypeQuiz = 'quiz';
  static const String notificationTypeMaterial = 'material';
  static const String notificationTypeMessage = 'message';
  static const String notificationTypeForum = 'forum';
  static const String notificationTypeGrade = 'grade';
  static const String notificationTypeDeadline = 'deadline';

  // Assignment Statuses
  static const String assignmentStatusNotSubmitted = 'not_submitted';
  static const String assignmentStatusSubmitted = 'submitted';
  static const String assignmentStatusGraded = 'graded';
  static const String assignmentStatusLate = 'late';

  // Quiz Statuses
  static const String quizStatusNotStarted = 'not_started';
  static const String quizStatusInProgress = 'in_progress';
  static const String quizStatusCompleted = 'completed';

  // Firebase Collections
  static const String collectionUsers = 'users';
  static const String collectionSemesters = 'semesters';
  static const String collectionCourses = 'courses';
  static const String collectionGroups = 'groups';
  static const String collectionAnnouncements = 'announcements';
  static const String collectionAssignments = 'assignments';
  static const String collectionAssignmentSubmissions = 'assignment_submissions';
  static const String collectionQuizzes = 'quizzes';
  static const String collectionQuestions = 'questions';
  static const String collectionQuizSubmissions = 'quiz_submissions';
  static const String collectionMaterials = 'materials';
  static const String collectionForumTopics = 'forum_topics';
  static const String collectionForumReplies = 'forum_replies';
  static const String collectionMessages = 'messages';
  static const String collectionNotifications = 'notifications';
  static const String collectionComments = 'comments';

  // Firebase Storage Paths
  static const String storageUsers = 'users';
  static const String storageCourses = 'courses';
  static const String storageAnnouncements = 'announcements';
  static const String storageAssignments = 'assignments';
  static const String storageSubmissions = 'submissions';
  static const String storageMaterials = 'materials';
  static const String storageMessages = 'messages';
  static const String storageForums = 'forums';

  // Hive Box Names
  static const String hiveBoxUsers = 'users_box';
  static const String hiveBoxSemesters = 'semesters_box';
  static const String hiveBoxCourses = 'courses_box';
  static const String hiveBoxGroups = 'groups_box';
  static const String hiveBoxAnnouncements = 'announcements_box';
  static const String hiveBoxAssignments = 'assignments_box';
  static const String hiveBoxQuizzes = 'quizzes_box';
  static const String hiveBoxMaterials = 'materials_box';
  static const String hiveBoxNotifications = 'notifications_box';
  static const String hiveBoxCache = 'cache_box';
  static const String hiveBoxSettings = 'settings_box';

  // Hive Type IDs (for Hive adapters)
  static const int hiveTypeIdUser = 0;
  static const int hiveTypeIdSemester = 1;
  static const int hiveTypeIdCourse = 2;
  static const int hiveTypeIdGroup = 3;
  static const int hiveTypeIdAnnouncement = 4;
  static const int hiveTypeIdAssignment = 5;
  static const int hiveTypeIdAssignmentSubmission = 6;
  static const int hiveTypeIdQuiz = 7;
  static const int hiveTypeIdQuestion = 8;
  static const int hiveTypeIdQuizSubmission = 9;
  static const int hiveTypeIdMaterial = 10;
  static const int hiveTypeIdForumTopic = 11;
  static const int hiveTypeIdForumReply = 12;
  static const int hiveTypeIdMessage = 13;
  static const int hiveTypeIdNotification = 14;

  // Error Messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorInvalidCredentials =
      'Invalid username or password.';
  static const String errorPermission = 'You do not have permission.';
  static const String errorFileSize = 'File size exceeds the maximum limit.';
  static const String errorFileFormat = 'File format is not supported.';
  static const String errorCsvFormat = 'CSV file format is invalid.';
  static const String errorCsvEmpty = 'CSV file is empty.';
  static const String errorDeadlinePassed = 'Deadline has passed.';
  static const String errorMaxAttempts = 'Maximum attempts reached.';
  static const String errorQuizInProgress = 'Quiz is already in progress.';
  static const String errorQuizNotAvailable = 'Quiz is not available yet.';
  static const String errorPastSemester =
      'Cannot modify data from past semesters.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successLogout = 'Logout successful!';
  static const String successCreate = 'Created successfully!';
  static const String successUpdate = 'Updated successfully!';
  static const String successDelete = 'Deleted successfully!';
  static const String successImport = 'Import completed successfully!';
  static const String successExport = 'Export completed successfully!';
  static const String successSubmit = 'Submitted successfully!';
  static const String successGrade = 'Graded successfully!';

  // Validation Messages
  static const String validationRequired = 'This field is required.';
  static const String validationEmail = 'Please enter a valid email.';
  static const String validationMinLength = 'Minimum length is ';
  static const String validationMaxLength = 'Maximum length is ';
  static const String validationPasswordMismatch = 'Passwords do not match.';
  static const String validationInvalidDate = 'Invalid date.';
  static const String validationInvalidNumber = 'Invalid number.';

  // IT-Related Topics (for content validation)
  static const List<String> validITTopics = [
    'programming',
    'database',
    'artificial intelligence',
    'ai',
    'machine learning',
    'ml',
    'web development',
    'mobile development',
    'data structures',
    'algorithms',
    'networking',
    'computer networks',
    'cybersecurity',
    'software engineering',
    'operating systems',
    'cloud computing',
    'devops',
    'data science',
    'big data',
    'blockchain',
    'iot',
    'internet of things',
    'computer graphics',
    'computer vision',
    'nlp',
    'natural language processing',
    'ui/ux',
    'user interface',
    'user experience',
    'api',
    'rest',
    'graphql',
    'microservices',
    'docker',
    'kubernetes',
    'git',
    'version control',
    'testing',
    'qa',
    'agile',
    'scrum',
    'java',
    'python',
    'javascript',
    'typescript',
    'c++',
    'c#',
    'php',
    'ruby',
    'swift',
    'kotlin',
    'dart',
    'flutter',
    'react',
    'angular',
    'vue',
    'node',
    'django',
    'flask',
    'spring',
    'sql',
    'nosql',
    'mongodb',
    'postgresql',
    'mysql',
    'firebase',
    'aws',
    'azure',
    'gcp',
  ];

  // Utility Methods
  static bool isValidITContent(String content) {
    final lowerContent = content.toLowerCase();
    return validITTopics.any((topic) => lowerContent.contains(topic));
  }

  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  static bool isValidFileSize(int sizeInBytes) {
    return sizeInBytes <= maxFileSizeBytes;
  }

  static bool isValidFileFormat(String filename, List<String> allowedFormats) {
    final extension = getFileExtension(filename);
    return allowedFormats.contains(extension);
  }

  static bool isValidImageFile(String filename) {
    return isValidFileFormat(filename, allowedImageFormats);
  }

  static bool isValidDocumentFile(String filename) {
    return isValidFileFormat(filename, allowedDocumentFormats);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Format as dd/MM/yyyy
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  /// Format deadline (future date) with relative time or absolute date
  static String formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      // Past deadline - show as overdue
      final daysPast = difference.inDays.abs();
      if (daysPast == 0) {
        return 'Today';
      } else if (daysPast == 1) {
        return 'Yesterday';
      } else if (daysPast < 7) {
        return '$daysPast days ago';
      }
    } else {
      // Future deadline - show relative or absolute
      final daysUntil = difference.inDays;
      final hoursUntil = difference.inHours;

      if (hoursUntil < 24) {
        if (hoursUntil < 1) {
          return 'In ${difference.inMinutes} min';
        }
        return 'Today';
      } else if (daysUntil == 1) {
        return 'Tomorrow';
      } else if (daysUntil < 7) {
        return 'In $daysUntil days';
      }
    }

    // Default: Format as dd/MM/yyyy HH:mm
    return '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year} ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
  }
}
}