import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/material/domain/entities/material_entity.dart';

/// Data Access Object for Material operations
/// PDF Requirement: Materials are visible to ALL students in a course (no group scoping)
class MaterialDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert MaterialEntity to Map for SQLite
  Map<String, dynamic> _toMap(MaterialEntity material) {
    return {
      DatabaseConfig.columnId: material.id,
      'title': material.title,
      'description': material.description,
      'course_id': material.courseId,
      'created_by': material.createdBy,
      'file_urls': jsonEncode(material.fileUrls),
      'link_urls': jsonEncode(material.linkUrls),
      DatabaseConfig.columnCreatedAt: material.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: material.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to MaterialEntity
  MaterialEntity _fromMap(Map<String, dynamic> map) {
    return MaterialEntity(
      id: map[DatabaseConfig.columnId] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      courseId: map['course_id'] as String,
      createdBy: map['created_by'] as String,
      fileUrls: List<String>.from(jsonDecode(map['file_urls'] as String)),
      linkUrls: List<String>.from(jsonDecode(map['link_urls'] as String)),
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

  /// Create a new material
  Future<int> insert(MaterialEntity material) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableMaterials,
      _toMap(material),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple materials (for CSV import)
  Future<List<String>> insertBatch(List<MaterialEntity> materials) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var material in materials) {
      batch.insert(
        DatabaseConfig.tableMaterials,
        _toMap(material),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(material.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get material by ID
  Future<MaterialEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all materials for a course
  /// PDF Requirement: Materials are visible to ALL students (no group filtering)
  Future<List<MaterialEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get materials with course and instructor details
  /// PDF Requirement: Display related information for better UX
  Future<List<MaterialEntity>> getByCourseWithDetails(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT m.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableMaterials} m
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = m.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = m.created_by
      WHERE m.course_id = ?
      ORDER BY m.${DatabaseConfig.columnCreatedAt} DESC
    ''', [courseId]);

    return result.map((map) {
      final material = _fromMap(map);
      return material.copyWith(
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Get material by ID with details
  Future<MaterialEntity?> getByIdWithDetails(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT m.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableMaterials} m
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = m.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = m.created_by
      WHERE m.${DatabaseConfig.columnId} = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final material = _fromMap(result.first);
    return material.copyWith(
      courseName: result.first['course_name'] as String?,
      courseCode: result.first['course_code'] as String?,
      instructorName: result.first['instructor_name'] as String?,
    );
  }

  /// Get materials by student ID (all materials from their enrolled courses)
  /// PDF Requirement: Students see all materials from their courses
  Future<List<MaterialEntity>> getByStudentId(String studentId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT DISTINCT m.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableMaterials} m
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = m.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = m.created_by
      INNER JOIN ${DatabaseConfig.tableStudentEnrollments} e ON e.course_id = m.course_id
      WHERE e.student_id = ?
      ORDER BY m.${DatabaseConfig.columnCreatedAt} DESC
    ''', [studentId]);

    return result.map((map) {
      final material = _fromMap(map);
      return material.copyWith(
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Search materials by title or description
  Future<List<MaterialEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'title LIKE ? OR description LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get materials with files (exclude link-only materials)
  Future<List<MaterialEntity>> getMaterialsWithFiles({String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'file_urls != ?';
    List<dynamic> whereArgs = [jsonEncode([])];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get materials with links (exclude file-only materials)
  Future<List<MaterialEntity>> getMaterialsWithLinks({String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'link_urls != ?';
    List<dynamic> whereArgs = [jsonEncode([])];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get recent materials (last N days)
  Future<List<MaterialEntity>> getRecent({int days = 7, String? courseId}) async {
    final db = await _dbHelper.database;
    final cutoffTime = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    String whereClause = '${DatabaseConfig.columnCreatedAt} >= ?';
    List<dynamic> whereArgs = [cutoffTime];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableMaterials,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update material
  Future<int> update(MaterialEntity material) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableMaterials,
      _toMap(material),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [material.id],
    );
  }

  /// Delete material
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableMaterials,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get total material count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableMaterials}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
