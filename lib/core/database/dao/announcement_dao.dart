import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/announcement/domain/entities/announcement_entity.dart';

/// Data Access Object for Announcement operations
class AnnouncementDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert AnnouncementEntity to Map for SQLite
  Map<String, dynamic> _toMap(AnnouncementEntity announcement) {
    return {
      DatabaseConfig.columnId: announcement.id,
      'title': announcement.title,
      'content': announcement.content,
      'course_id': announcement.courseId,
      'created_by': announcement.createdBy,
      'attachment_urls': jsonEncode(announcement.attachmentUrls),
      'target_group_ids': jsonEncode(announcement.targetGroupIds),
      DatabaseConfig.columnCreatedAt: announcement.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: announcement.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to AnnouncementEntity
  AnnouncementEntity _fromMap(Map<String, dynamic> map) {
    return AnnouncementEntity(
      id: map[DatabaseConfig.columnId] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      courseId: map['course_id'] as String,
      createdBy: map['created_by'] as String,
      attachmentUrls: List<String>.from(jsonDecode(map['attachment_urls'] as String)),
      targetGroupIds: List<String>.from(jsonDecode(map['target_group_ids'] as String)),
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

  /// Create a new announcement
  Future<int> insert(AnnouncementEntity announcement) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableAnnouncements,
      _toMap(announcement),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple announcements (for CSV import)
  Future<List<String>> insertBatch(List<AnnouncementEntity> announcements) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var announcement in announcements) {
      batch.insert(
        DatabaseConfig.tableAnnouncements,
        _toMap(announcement),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(announcement.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get announcement by ID
  Future<AnnouncementEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all announcements for a course
  Future<List<AnnouncementEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get announcements for a specific group
  /// PDF Requirement: Announcements can be scoped to specific groups
  Future<List<AnnouncementEntity>> getByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      where: 'target_group_ids LIKE ?',
      whereArgs: ['%"$groupId"%'],
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get announcements visible to a student (based on their group enrollments)
  /// PDF Requirement: Students see announcements targeted to their groups
  Future<List<AnnouncementEntity>> getByStudentId(String studentId) async {
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

    // Get all announcements for these groups
    final List<AnnouncementEntity> announcements = [];
    for (var groupId in groupIds) {
      final groupAnnouncements = await getByGroup(groupId);
      announcements.addAll(groupAnnouncements);
    }

    // Remove duplicates and sort by date
    final uniqueAnnouncements = <String, AnnouncementEntity>{};
    for (var announcement in announcements) {
      uniqueAnnouncements[announcement.id] = announcement;
    }

    final result = uniqueAnnouncements.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Get announcements with course and instructor details
  /// PDF Requirement: Display related information for better UX
  Future<List<AnnouncementEntity>> getByCourseWithDetails(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT a.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableAnnouncements} a
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = a.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = a.created_by
      WHERE a.course_id = ?
      ORDER BY a.${DatabaseConfig.columnCreatedAt} DESC
    ''', [courseId]);

    return result.map((map) {
      final announcement = _fromMap(map);
      return announcement.copyWith(
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Get announcement by ID with details
  Future<AnnouncementEntity?> getByIdWithDetails(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT a.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableAnnouncements} a
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = a.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = a.created_by
      WHERE a.${DatabaseConfig.columnId} = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final announcement = _fromMap(result.first);
    return announcement.copyWith(
      courseName: result.first['course_name'] as String?,
      courseCode: result.first['course_code'] as String?,
      instructorName: result.first['instructor_name'] as String?,
    );
  }

  /// Search announcements by title or content
  Future<List<AnnouncementEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'title LIKE ? OR content LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update announcement
  Future<int> update(AnnouncementEntity announcement) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableAnnouncements,
      _toMap(announcement),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [announcement.id],
    );
  }

  /// Delete announcement
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableAnnouncements,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get total announcement count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableAnnouncements}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get recent announcements (last N days)
  Future<List<AnnouncementEntity>> getRecent({int days = 7, String? courseId}) async {
    final db = await _dbHelper.database;
    final cutoffTime = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    String whereClause = '${DatabaseConfig.columnCreatedAt} >= ?';
    List<dynamic> whereArgs = [cutoffTime];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get all announcements
  Future<List<AnnouncementEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAnnouncements,
      orderBy: '${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }
}
