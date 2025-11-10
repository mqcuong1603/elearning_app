import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/quiz/domain/entities/quiz_entity.dart';

/// Data Access Object for Quiz operations
class QuizDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert QuizEntity to Map for SQLite
  Map<String, dynamic> _toMap(QuizEntity quiz) {
    return {
      DatabaseConfig.columnId: quiz.id,
      'title': quiz.title,
      'description': quiz.description,
      'course_id': quiz.courseId,
      'created_by': quiz.createdBy,
      'target_group_ids': jsonEncode(quiz.targetGroupIds),
      'open_time': quiz.openTime.millisecondsSinceEpoch,
      'close_time': quiz.closeTime.millisecondsSinceEpoch,
      'max_attempts': quiz.maxAttempts,
      'duration_minutes': quiz.durationMinutes,
      'easy_questions_count': quiz.easyQuestionsCount,
      'medium_questions_count': quiz.mediumQuestionsCount,
      'hard_questions_count': quiz.hardQuestionsCount,
      'fixed_question_ids': quiz.fixedQuestionIds != null
          ? jsonEncode(quiz.fixedQuestionIds)
          : null,
      DatabaseConfig.columnCreatedAt: quiz.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: quiz.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to QuizEntity
  QuizEntity _fromMap(Map<String, dynamic> map) {
    return QuizEntity(
      id: map[DatabaseConfig.columnId] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      courseId: map['course_id'] as String,
      createdBy: map['created_by'] as String,
      targetGroupIds: List<String>.from(jsonDecode(map['target_group_ids'] as String)),
      openTime: DateTime.fromMillisecondsSinceEpoch(map['open_time'] as int),
      closeTime: DateTime.fromMillisecondsSinceEpoch(map['close_time'] as int),
      maxAttempts: map['max_attempts'] as int,
      durationMinutes: map['duration_minutes'] as int,
      easyQuestionsCount: map['easy_questions_count'] as int,
      mediumQuestionsCount: map['medium_questions_count'] as int,
      hardQuestionsCount: map['hard_questions_count'] as int,
      fixedQuestionIds: map['fixed_question_ids'] != null
          ? List<String>.from(jsonDecode(map['fixed_question_ids'] as String))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConfig.columnCreatedAt] as int,
      ),
      updatedAt: map[DatabaseConfig.columnUpdatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DatabaseConfig.columnUpdatedAt] as int,
            )
          : null,
    );
  }

  /// Create a new quiz
  Future<int> insert(QuizEntity quiz) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableQuizzes,
      _toMap(quiz),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple quizzes (for CSV import)
  Future<List<String>> insertBatch(List<QuizEntity> quizzes) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var quiz in quizzes) {
      batch.insert(
        DatabaseConfig.tableQuizzes,
        _toMap(quiz),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(quiz.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get quiz by ID
  Future<QuizEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all quizzes for a course
  Future<List<QuizEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'open_time ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get quizzes for a specific group
  /// PDF Requirement: Quizzes can be scoped to specific groups
  Future<List<QuizEntity>> getByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: 'target_group_ids LIKE ?',
      whereArgs: ['%"$groupId"%'],
      orderBy: 'open_time ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get quizzes visible to a student (based on their group enrollments)
  /// PDF Requirement: Students see quizzes targeted to their groups
  Future<List<QuizEntity>> getByStudentId(String studentId) async {
    final db = await _dbHelper.database;

    // Find all groups the student is enrolled in
    final groupResult = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      columns: ['group_id'],
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    if (groupResult.isEmpty) return [];

    final groupIds = groupResult.map((row) => row['group_id'] as String).toList();

    // Get all quizzes for these groups
    final List<QuizEntity> quizzes = [];
    for (var groupId in groupIds) {
      final groupQuizzes = await getByGroup(groupId);
      quizzes.addAll(groupQuizzes);
    }

    // Remove duplicates and sort by open time
    final uniqueQuizzes = <String, QuizEntity>{};
    for (var quiz in quizzes) {
      uniqueQuizzes[quiz.id] = quiz;
    }

    final result = uniqueQuizzes.values.toList();
    result.sort((a, b) => a.openTime.compareTo(b.openTime));
    return result;
  }

  /// Get quizzes with course and instructor details
  /// PDF Requirement: Display related information for better UX
  Future<List<QuizEntity>> getByCourseWithDetails(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT q.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableQuizzes} q
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = q.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = q.created_by
      WHERE q.course_id = ?
      ORDER BY q.open_time ASC
    ''', [courseId]);

    return result.map((map) {
      final quiz = _fromMap(map);
      return quiz.copyWith(
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Get quiz by ID with details
  Future<QuizEntity?> getByIdWithDetails(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT q.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableQuizzes} q
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = q.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = q.created_by
      WHERE q.${DatabaseConfig.columnId} = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final quiz = _fromMap(result.first);
    return quiz.copyWith(
      courseName: result.first['course_name'] as String?,
      courseCode: result.first['course_code'] as String?,
      instructorName: result.first['instructor_name'] as String?,
    );
  }

  /// Get open quizzes (currently available)
  /// PDF Requirement: Display quiz status (open/closed/upcoming)
  Future<List<QuizEntity>> getOpenQuizzes({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'open_time <= ? AND close_time > ?';
    List<dynamic> whereArgs = [now, now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'close_time ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get upcoming quizzes (not yet open)
  Future<List<QuizEntity>> getUpcomingQuizzes({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'open_time > ?';
    List<dynamic> whereArgs = [now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'open_time ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get closed quizzes (past close time)
  Future<List<QuizEntity>> getClosedQuizzes({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'close_time <= ?';
    List<dynamic> whereArgs = [now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'close_time DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Search quizzes by title or description
  Future<List<QuizEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'title LIKE ? OR description LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableQuizzes,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'open_time ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update quiz
  Future<int> update(QuizEntity quiz) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableQuizzes,
      _toMap(quiz),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [quiz.id],
    );
  }

  /// Delete quiz
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableQuizzes,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get total quiz count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableQuizzes}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
