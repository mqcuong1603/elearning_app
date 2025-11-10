import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/tables/user_table.dart';
import 'package:elearning_app/core/database/tables/semester_table.dart';
import 'package:elearning_app/core/database/tables/course_table.dart';
import 'package:elearning_app/core/database/tables/group_table.dart';
import 'package:elearning_app/core/database/tables/enrollment_table.dart';
import 'package:elearning_app/core/database/tables/announcement_table.dart';
import 'package:elearning_app/core/database/tables/assignment_table.dart';
import 'package:elearning_app/core/database/tables/quiz_table.dart';
import 'package:elearning_app/core/database/tables/question_table.dart';
import 'package:elearning_app/core/database/tables/material_table.dart';

/// Singleton class to manage SQLite database
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance (initialize if not already)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    // Get the device's documents directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DatabaseConfig.databaseName);

    // Open/create the database
    return await openDatabase(
      path,
      version: DatabaseConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    // Create core tables in order (respect foreign key dependencies)

    // 1. Users table (no dependencies)
    for (var statement in UserTable.createStatements) {
      await db.execute(statement);
    }

    // 2. Semesters table (no dependencies)
    for (var statement in SemesterTable.createStatements) {
      await db.execute(statement);
    }

    // 3. Courses table (depends on users and semesters)
    for (var statement in CourseTable.createStatements) {
      await db.execute(statement);
    }

    // 4. Groups table (depends on courses and semesters)
    for (var statement in GroupTable.createStatements) {
      await db.execute(statement);
    }

    // 5. Student enrollments (depends on users, groups, courses, semesters)
    for (var statement in EnrollmentTable.createStatements) {
      await db.execute(statement);
    }

    // 6. Content tables (depend on courses and users)
    for (var statement in AnnouncementTable.createStatements) {
      await db.execute(statement);
    }

    for (var statement in AssignmentTable.createStatements) {
      await db.execute(statement);
    }

    for (var statement in QuizTable.createStatements) {
      await db.execute(statement);
    }

    for (var statement in QuestionTable.createStatements) {
      await db.execute(statement);
    }

    for (var statement in MaterialTable.createStatements) {
      await db.execute(statement);
    }

    print(' Database created successfully with all tables');

    // Insert default admin user
    await _insertDefaultAdmin(db);
  }

  /// Insert default admin user
  Future<void> _insertDefaultAdmin(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      DatabaseConfig.tableUsers,
      {
        DatabaseConfig.columnId: 'admin-user-id',
        'username': 'admin',
        'display_name': 'Administrator',
        'email': 'admin@elearning.com',
        'password_hash': 'admin', // In production, this should be hashed!
        'role': 'admin',
        DatabaseConfig.columnCreatedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    print(' Default admin user created (username: admin, password: admin)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when version increases
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    // }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (useful for testing)
  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DatabaseConfig.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('=�  Database deleted');
  }

  /// Clear all tables (keep structure)
  Future<void> clearAllTables() async {
    final db = await database;

    // Disable foreign key constraints temporarily
    await db.execute('PRAGMA foreign_keys = OFF');

    // Clear all tables
    await db.delete(DatabaseConfig.tableMaterials);
    await db.delete(DatabaseConfig.tableQuestions);
    await db.delete(DatabaseConfig.tableQuizzes);
    await db.delete(DatabaseConfig.tableAssignments);
    await db.delete(DatabaseConfig.tableAnnouncements);
    await db.delete(DatabaseConfig.tableStudentEnrollments);
    await db.delete(DatabaseConfig.tableGroups);
    await db.delete(DatabaseConfig.tableCourses);
    await db.delete(DatabaseConfig.tableSemesters);
    await db.delete(DatabaseConfig.tableUsers);

    // Re-enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    // Re-insert admin
    await _insertDefaultAdmin(db);

    print('>� All tables cleared');
  }
}
