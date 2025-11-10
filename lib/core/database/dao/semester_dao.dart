import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/semester/domain/entities/semester_entity.dart';

/// Data Access Object for Semester operations
class SemesterDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert SemesterEntity to Map for SQLite
  Map<String, dynamic> _toMap(SemesterEntity semester) {
    return {
      DatabaseConfig.columnId: semester.id,
      'code': semester.code,
      'name': semester.name,
      'start_date': semester.startDate.millisecondsSinceEpoch,
      'end_date': semester.endDate.millisecondsSinceEpoch,
      'is_current': semester.isCurrent ? 1 : 0,
      DatabaseConfig.columnCreatedAt: semester.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: semester.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to SemesterEntity
  SemesterEntity _fromMap(Map<String, dynamic> map) {
    return SemesterEntity(
      id: map[DatabaseConfig.columnId] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      isCurrent: (map['is_current'] as int) == 1,
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

  /// Create a new semester
  Future<int> insert(SemesterEntity semester) async {
    final db = await _dbHelper.database;

    // If this semester is marked as current, unmark all others
    if (semester.isCurrent) {
      await _unmarkAllAsCurrent();
    }

    return await db.insert(
      DatabaseConfig.tableSemesters,
      _toMap(semester),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple semesters (for CSV import)
  Future<List<String>> insertBatch(List<SemesterEntity> semesters) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var semester in semesters) {
      batch.insert(
        DatabaseConfig.tableSemesters,
        _toMap(semester),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(semester.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Unmark all semesters as current
  Future<void> _unmarkAllAsCurrent() async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConfig.tableSemesters,
      {'is_current': 0},
    );
  }

  /// Set a semester as current
  Future<int> setAsCurrent(String semesterId) async {
    final db = await _dbHelper.database;

    // First, unmark all semesters
    await _unmarkAllAsCurrent();

    // Then mark this one as current
    return await db.update(
      DatabaseConfig.tableSemesters,
      {'is_current': 1},
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [semesterId],
    );
  }

  /// Get semester by ID
  Future<SemesterEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get semester by code
  Future<SemesterEntity?> getByCode(String code) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get current semester
  /// PDF Requirement: "By default, the system loads the current (latest) semester"
  Future<SemesterEntity?> getCurrentSemester() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'is_current = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all semesters
  Future<List<SemesterEntity>> getAll({String? orderBy}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      orderBy: orderBy ?? 'start_date DESC', // Latest first by default
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get past semesters (ended)
  Future<List<SemesterEntity>> getPastSemesters() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'end_date < ?',
      whereArgs: [now],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get active/current semesters (ongoing)
  Future<List<SemesterEntity>> getActiveSemesters() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [now, now],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get future semesters (not started yet)
  Future<List<SemesterEntity>> getFutureSemesters() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'start_date > ?',
      whereArgs: [now],
      orderBy: 'start_date ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Search semesters by code or name
  Future<List<SemesterEntity>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableSemesters,
      where: 'code LIKE ? OR name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update semester
  Future<int> update(SemesterEntity semester) async {
    final db = await _dbHelper.database;

    // If this semester is marked as current, unmark all others
    if (semester.isCurrent) {
      await _unmarkAllAsCurrent();
    }

    return await db.update(
      DatabaseConfig.tableSemesters,
      _toMap(semester),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [semester.id],
    );
  }

  /// Delete semester
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableSemesters,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Check if semester code exists
  Future<bool> codeExists(String code) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DatabaseConfig.tableSemesters,
      columns: [DatabaseConfig.columnId],
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get total semester count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableSemesters}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get semester with course count (for dashboard)
  Future<SemesterEntity?> getByIdWithCounts(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT s.*,
        COUNT(DISTINCT c.${DatabaseConfig.columnId}) as course_count,
        COUNT(DISTINCT e.student_id) as student_count
      FROM ${DatabaseConfig.tableSemesters} s
      LEFT JOIN ${DatabaseConfig.tableCourses} c ON c.semester_id = s.${DatabaseConfig.columnId}
      LEFT JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.semester_id = s.${DatabaseConfig.columnId}
      WHERE s.${DatabaseConfig.columnId} = ?
      GROUP BY s.${DatabaseConfig.columnId}
    ''', [id]);

    if (result.isEmpty) return null;

    final semester = _fromMap(result.first);
    return semester.copyWith(
      courseCount: result.first['course_count'] as int?,
      studentCount: result.first['student_count'] as int?,
    );
  }
}
