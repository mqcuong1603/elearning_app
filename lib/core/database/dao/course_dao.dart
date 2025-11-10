import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/course/domain/entities/course_entity.dart';

/// Data Access Object for Course operations
class CourseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert CourseEntity to Map for SQLite
  Map<String, dynamic> _toMap(CourseEntity course) {
    return {
      DatabaseConfig.columnId: course.id,
      'code': course.code,
      'name': course.name,
      'description': course.description,
      'semester_id': course.semesterId,
      'instructor_id': course.instructorId,
      'cover_image_url': course.coverImageUrl,
      'sessions': course.sessions,
      DatabaseConfig.columnCreatedAt: course.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: course.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to CourseEntity
  CourseEntity _fromMap(Map<String, dynamic> map) {
    return CourseEntity(
      id: map[DatabaseConfig.columnId] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      semesterId: map['semester_id'] as String,
      instructorId: map['instructor_id'] as String,
      coverImageUrl: map['cover_image_url'] as String?,
      sessions: map['sessions'] as int,
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

  /// Create a new course
  Future<int> insert(CourseEntity course) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableCourses,
      _toMap(course),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple courses (for CSV import)
  Future<List<String>> insertBatch(List<CourseEntity> courses) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var course in courses) {
      batch.insert(
        DatabaseConfig.tableCourses,
        _toMap(course),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(course.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get course by ID
  Future<CourseEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get course by code
  Future<CourseEntity?> getByCode(String code) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all courses
  Future<List<CourseEntity>> getAll({String? orderBy}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      orderBy: orderBy ?? 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get courses by semester ID
  /// PDF Requirement: Filter courses by semester
  Future<List<CourseEntity>> getBySemester(String semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get courses by instructor ID
  Future<List<CourseEntity>> getByInstructor(String instructorId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: 'instructor_id = ?',
      whereArgs: [instructorId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Search courses by code or name
  /// PDF Requirement: Search functionality for large datasets
  Future<List<CourseEntity>> search(String query, {String? semesterId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'code LIKE ? OR name LIKE ? OR description LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%'];

    if (semesterId != null) {
      whereClause += ' AND semester_id = ?';
      whereArgs.add(semesterId);
    }

    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get course with all counts (groups, students, content)
  /// PDF Requirement: Display counts for better UX
  Future<CourseEntity?> getByIdWithCounts(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT c.*,
        (SELECT name FROM ${DatabaseConfig.tableSemesters} WHERE ${DatabaseConfig.columnId} = c.semester_id) as semester_name,
        (SELECT display_name FROM ${DatabaseConfig.tableUsers} WHERE ${DatabaseConfig.columnId} = c.instructor_id) as instructor_name,
        COUNT(DISTINCT g.${DatabaseConfig.columnId}) as group_count,
        COUNT(DISTINCT e.student_id) as student_count,
        COUNT(DISTINCT a.${DatabaseConfig.columnId}) as assignment_count,
        COUNT(DISTINCT q.${DatabaseConfig.columnId}) as quiz_count,
        COUNT(DISTINCT m.${DatabaseConfig.columnId}) as material_count,
        COUNT(DISTINCT an.${DatabaseConfig.columnId}) as announcement_count
      FROM ${DatabaseConfig.tableCourses} c
      LEFT JOIN ${DatabaseConfig.tableGroups} g ON g.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableAssignments} a ON a.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableQuizzes} q ON q.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableMaterials} m ON m.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableAnnouncements} an ON an.course_id = c.${DatabaseConfig.columnId}
      WHERE c.${DatabaseConfig.columnId} = ?
      GROUP BY c.${DatabaseConfig.columnId}
    ''', [id]);

    if (result.isEmpty) return null;

    final course = _fromMap(result.first);
    return course.copyWith(
      semesterName: result.first['semester_name'] as String?,
      instructorName: result.first['instructor_name'] as String?,
      groupCount: result.first['group_count'] as int?,
      studentCount: result.first['student_count'] as int?,
      assignmentCount: result.first['assignment_count'] as int?,
      quizCount: result.first['quiz_count'] as int?,
      materialCount: result.first['material_count'] as int?,
      announcementCount: result.first['announcement_count'] as int?,
    );
  }

  /// Get courses enrolled by a student (for student homepage)
  /// PDF Requirement: "For students, the homepage displays enrolled courses as cards"
  Future<List<CourseEntity>> getByStudentId(String studentId, {String? semesterId}) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT c.*,
        s.name as semester_name,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableCourses} c
      INNER JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.course_id = c.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableSemesters} s ON s.${DatabaseConfig.columnId} = c.semester_id
      LEFT JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = c.instructor_id
      WHERE e.student_id = ?
    ''';

    List<dynamic> args = [studentId];

    if (semesterId != null) {
      query += ' AND c.semester_id = ?';
      args.add(semesterId);
    }

    query += ' ORDER BY c.name ASC';

    final result = await db.rawQuery(query, args);

    return result.map((map) {
      final course = _fromMap(map);
      return course.copyWith(
        semesterName: map['semester_name'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Update course
  Future<int> update(CourseEntity course) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableCourses,
      _toMap(course),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [course.id],
    );
  }

  /// Delete course
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableCourses,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Check if course code exists in a semester
  Future<bool> codeExistsInSemester(String code, String semesterId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DatabaseConfig.tableCourses,
      columns: [DatabaseConfig.columnId],
      where: 'code = ? AND semester_id = ?',
      whereArgs: [code, semesterId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get total course count
  Future<int> getCount({String? semesterId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableCourses}';
    List<dynamic> args = [];

    if (semesterId != null) {
      query += ' WHERE semester_id = ?';
      args.add(semesterId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get courses by session count (10 or 15)
  Future<List<CourseEntity>> getBySessionCount(int sessions) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableCourses,
      where: 'sessions = ?',
      whereArgs: [sessions],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }
}
