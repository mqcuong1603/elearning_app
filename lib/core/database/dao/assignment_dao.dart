import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/assignment/domain/entities/assignment_entity.dart';

/// Data Access Object for Assignment operations
class AssignmentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert AssignmentEntity to Map for SQLite
  Map<String, dynamic> _toMap(AssignmentEntity assignment) {
    return {
      DatabaseConfig.columnId: assignment.id,
      'title': assignment.title,
      'description': assignment.description,
      'course_id': assignment.courseId,
      'created_by': assignment.createdBy,
      'attachment_urls': jsonEncode(assignment.attachmentUrls),
      'target_group_ids': jsonEncode(assignment.targetGroupIds),
      'start_date': assignment.startDate.millisecondsSinceEpoch,
      'deadline': assignment.deadline.millisecondsSinceEpoch,
      'allow_late_submission': assignment.allowLateSubmission ? 1 : 0,
      'late_deadline': assignment.lateDeadline?.millisecondsSinceEpoch,
      'max_submission_attempts': assignment.maxSubmissionAttempts,
      'allowed_file_formats': jsonEncode(assignment.allowedFileFormats),
      'max_file_size_mb': assignment.maxFileSizeMB,
      DatabaseConfig.columnCreatedAt: assignment.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: assignment.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to AssignmentEntity
  AssignmentEntity _fromMap(Map<String, dynamic> map) {
    return AssignmentEntity(
      id: map[DatabaseConfig.columnId] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      courseId: map['course_id'] as String,
      createdBy: map['created_by'] as String,
      attachmentUrls: List<String>.from(jsonDecode(map['attachment_urls'] as String)),
      targetGroupIds: List<String>.from(jsonDecode(map['target_group_ids'] as String)),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
      allowLateSubmission: (map['allow_late_submission'] as int) == 1,
      lateDeadline: map['late_deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['late_deadline'] as int)
          : null,
      maxSubmissionAttempts: map['max_submission_attempts'] as int,
      allowedFileFormats: List<String>.from(jsonDecode(map['allowed_file_formats'] as String)),
      maxFileSizeMB: map['max_file_size_mb'] as int,
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

  /// Create a new assignment
  Future<int> insert(AssignmentEntity assignment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableAssignments,
      _toMap(assignment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple assignments (for CSV import)
  Future<List<String>> insertBatch(List<AssignmentEntity> assignments) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var assignment in assignments) {
      batch.insert(
        DatabaseConfig.tableAssignments,
        _toMap(assignment),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(assignment.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get assignment by ID
  Future<AssignmentEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all assignments for a course
  Future<List<AssignmentEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'deadline ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get assignments for a specific group
  /// PDF Requirement: Assignments can be scoped to specific groups
  Future<List<AssignmentEntity>> getByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: 'target_group_ids LIKE ?',
      whereArgs: ['%"$groupId"%'],
      orderBy: 'deadline ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get assignments visible to a student (based on their group enrollments)
  /// PDF Requirement: Students see assignments targeted to their groups
  Future<List<AssignmentEntity>> getByStudentId(String studentId) async {
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

    // Get all assignments for these groups
    final List<AssignmentEntity> assignments = [];
    for (var groupId in groupIds) {
      final groupAssignments = await getByGroup(groupId);
      assignments.addAll(groupAssignments);
    }

    // Remove duplicates and sort by deadline
    final uniqueAssignments = <String, AssignmentEntity>{};
    for (var assignment in assignments) {
      uniqueAssignments[assignment.id] = assignment;
    }

    final result = uniqueAssignments.values.toList();
    result.sort((a, b) => a.deadline.compareTo(b.deadline));
    return result;
  }

  /// Get assignments with course and instructor details
  /// PDF Requirement: Display related information for better UX
  Future<List<AssignmentEntity>> getByCourseWithDetails(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT a.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableAssignments} a
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = a.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = a.created_by
      WHERE a.course_id = ?
      ORDER BY a.deadline ASC
    ''', [courseId]);

    return result.map((map) {
      final assignment = _fromMap(map);
      return assignment.copyWith(
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
        instructorName: map['instructor_name'] as String?,
      );
    }).toList();
  }

  /// Get assignment by ID with details
  Future<AssignmentEntity?> getByIdWithDetails(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT a.*,
        c.name as course_name,
        c.code as course_code,
        u.display_name as instructor_name
      FROM ${DatabaseConfig.tableAssignments} a
      INNER JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = a.course_id
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = a.created_by
      WHERE a.${DatabaseConfig.columnId} = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final assignment = _fromMap(result.first);
    return assignment.copyWith(
      courseName: result.first['course_name'] as String?,
      courseCode: result.first['course_code'] as String?,
      instructorName: result.first['instructor_name'] as String?,
    );
  }

  /// Get open assignments (currently accepting submissions)
  /// PDF Requirement: Display assignment status (open/closed/upcoming)
  Future<List<AssignmentEntity>> getOpenAssignments({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'start_date <= ? AND deadline > ?';
    List<dynamic> whereArgs = [now, now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'deadline ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get upcoming assignments (not yet open)
  Future<List<AssignmentEntity>> getUpcomingAssignments({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'start_date > ?';
    List<dynamic> whereArgs = [now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_date ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get closed assignments (past deadline)
  Future<List<AssignmentEntity>> getClosedAssignments({String? courseId}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'deadline <= ?';
    List<dynamic> whereArgs = [now];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'deadline DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Search assignments by title or description
  Future<List<AssignmentEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'title LIKE ? OR description LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableAssignments,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'deadline ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update assignment
  Future<int> update(AssignmentEntity assignment) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableAssignments,
      _toMap(assignment),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [assignment.id],
    );
  }

  /// Delete assignment
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableAssignments,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get total assignment count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableAssignments}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
