import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/group/domain/entities/group_entity.dart';

/// Data Access Object for Group operations
class GroupDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert GroupEntity to Map for SQLite
  Map<String, dynamic> _toMap(GroupEntity group) {
    return {
      DatabaseConfig.columnId: group.id,
      'name': group.name,
      'course_id': group.courseId,
      'semester_id': group.semesterId,
      DatabaseConfig.columnCreatedAt: group.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: group.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to GroupEntity
  GroupEntity _fromMap(Map<String, dynamic> map) {
    return GroupEntity(
      id: map[DatabaseConfig.columnId] as String,
      name: map['name'] as String,
      courseId: map['course_id'] as String,
      semesterId: map['semester_id'] as String,
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

  /// Create a new group
  Future<int> insert(GroupEntity group) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableGroups,
      _toMap(group),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple groups (for CSV import)
  Future<List<String>> insertBatch(List<GroupEntity> groups) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var group in groups) {
      batch.insert(
        DatabaseConfig.tableGroups,
        _toMap(group),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(group.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get group by ID
  Future<GroupEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableGroups,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all groups
  Future<List<GroupEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableGroups,
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get groups by course ID
  /// PDF Requirement: "Group: Belongs to a single course"
  Future<List<GroupEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableGroups,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get groups by semester ID
  Future<List<GroupEntity>> getBySemester(String semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableGroups,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get group with student count
  /// PDF Requirement: Display related info like student count
  Future<GroupEntity?> getByIdWithCounts(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT g.*,
        (SELECT code FROM ${DatabaseConfig.tableCourses} WHERE ${DatabaseConfig.columnId} = g.course_id) as course_code,
        (SELECT name FROM ${DatabaseConfig.tableCourses} WHERE ${DatabaseConfig.columnId} = g.course_id) as course_name,
        COUNT(DISTINCT e.student_id) as student_count
      FROM ${DatabaseConfig.tableGroups} g
      LEFT JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.group_id = g.${DatabaseConfig.columnId}
      WHERE g.${DatabaseConfig.columnId} = ?
      GROUP BY g.${DatabaseConfig.columnId}
    ''', [id]);

    if (result.isEmpty) return null;

    final group = _fromMap(result.first);
    return group.copyWith(
      courseCode: result.first['course_code'] as String?,
      courseName: result.first['course_name'] as String?,
      studentCount: result.first['student_count'] as int?,
    );
  }

  /// Get groups with student counts for a course
  Future<List<GroupEntity>> getByCourseWithCounts(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT g.*,
        (SELECT code FROM ${DatabaseConfig.tableCourses} WHERE ${DatabaseConfig.columnId} = g.course_id) as course_code,
        (SELECT name FROM ${DatabaseConfig.tableCourses} WHERE ${DatabaseConfig.columnId} = g.course_id) as course_name,
        COUNT(DISTINCT e.student_id) as student_count
      FROM ${DatabaseConfig.tableGroups} g
      LEFT JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.group_id = g.${DatabaseConfig.columnId}
      WHERE g.course_id = ?
      GROUP BY g.${DatabaseConfig.columnId}
      ORDER BY g.name ASC
    ''', [courseId]);

    return result.map((map) {
      final group = _fromMap(map);
      return group.copyWith(
        courseCode: map['course_code'] as String?,
        courseName: map['course_name'] as String?,
        studentCount: map['student_count'] as int?,
      );
    }).toList();
  }

  /// Search groups by name
  Future<List<GroupEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'name LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableGroups,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update group
  Future<int> update(GroupEntity group) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableGroups,
      _toMap(group),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [group.id],
    );
  }

  /// Delete group
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableGroups,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get total group count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableGroups}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
