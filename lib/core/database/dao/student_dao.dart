import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/student/domain/entities/student_entity.dart';

/// Data Access Object for Student Enrollment operations
/// PDF Requirement: "within a course, each student can belong to only one group"
class StudentEnrollmentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert StudentEnrollmentEntity to Map for SQLite
  Map<String, dynamic> _toMap(StudentEnrollmentEntity enrollment) {
    return {
      DatabaseConfig.columnId: enrollment.id,
      'student_id': enrollment.studentId,
      'group_id': enrollment.groupId,
      'course_id': enrollment.courseId,
      'semester_id': enrollment.semesterId,
      'enrolled_at': enrollment.enrolledAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: enrollment.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to StudentEnrollmentEntity
  StudentEnrollmentEntity _fromMap(Map<String, dynamic> map) {
    return StudentEnrollmentEntity(
      id: map[DatabaseConfig.columnId] as String,
      studentId: map['student_id'] as String,
      groupId: map['group_id'] as String,
      courseId: map['course_id'] as String,
      semesterId: map['semester_id'] as String,
      enrolledAt: DateTime.fromMillisecondsSinceEpoch(
        map['enrolled_at'] as int,
      ),
      updatedAt: map[DatabaseConfig.columnUpdatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DatabaseConfig.columnUpdatedAt] as int,
            )
          : null,
    );
  }

  /// Enroll a student in a group
  /// PDF Requirement: Enforces UNIQUE(student_id, course_id, semester_id) constraint
  Future<int> insert(StudentEnrollmentEntity enrollment) async {
    final db = await _dbHelper.database;

    // Check if student is already enrolled in this course/semester
    final existing = await getByStudentAndCourse(
      enrollment.studentId,
      enrollment.courseId,
      enrollment.semesterId,
    );

    if (existing != null) {
      // Student already enrolled, update to new group instead
      return await update(enrollment.copyWith(id: existing.id));
    }

    return await db.insert(
      DatabaseConfig.tableStudentEnrollments,
      _toMap(enrollment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Enroll multiple students (for CSV import)
  Future<List<String>> insertBatch(List<StudentEnrollmentEntity> enrollments) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var enrollment in enrollments) {
      batch.insert(
        DatabaseConfig.tableStudentEnrollments,
        _toMap(enrollment),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(enrollment.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get enrollment by ID
  Future<StudentEnrollmentEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get enrollment by student, course, and semester
  /// Used to enforce "one group per course" rule
  Future<StudentEnrollmentEntity?> getByStudentAndCourse(
    String studentId,
    String courseId,
    String semesterId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: 'student_id = ? AND course_id = ? AND semester_id = ?',
      whereArgs: [studentId, courseId, semesterId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all enrollments for a student
  Future<List<StudentEnrollmentEntity>> getByStudent(String studentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'enrolled_at DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get all enrollments in a group
  Future<List<StudentEnrollmentEntity>> getByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'enrolled_at ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get all enrollments in a course
  Future<List<StudentEnrollmentEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'enrolled_at ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get all enrollments in a semester
  Future<List<StudentEnrollmentEntity>> getBySemester(String semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableStudentEnrollments,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'enrolled_at ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get enrollments with student details for a group
  /// For display in People tab
  Future<List<StudentEnrollmentEntity>> getByGroupWithStudentDetails(String groupId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT e.*,
        u.display_name as student_name,
        u.email as student_email,
        u.avatar_url as student_avatar_url,
        g.name as group_name,
        c.name as course_name,
        c.code as course_code
      FROM ${DatabaseConfig.tableStudentEnrollments} e
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = e.student_id
      LEFT JOIN ${DatabaseConfig.tableGroups} g ON g.${DatabaseConfig.columnId} = e.group_id
      LEFT JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = e.course_id
      WHERE e.group_id = ?
      ORDER BY u.display_name ASC
    ''', [groupId]);

    return result.map((map) {
      final enrollment = _fromMap(map);
      return enrollment.copyWith(
        studentName: map['student_name'] as String?,
        studentEmail: map['student_email'] as String?,
        studentAvatarUrl: map['student_avatar_url'] as String?,
        groupName: map['group_name'] as String?,
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
      );
    }).toList();
  }

  /// Get enrollments with student details for a course
  /// For display in Student List Screen
  Future<List<StudentEnrollmentEntity>> getByCourseWithStudentDetails(String courseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT e.*,
        u.display_name as student_name,
        u.email as student_email,
        u.avatar_url as student_avatar_url,
        g.name as group_name,
        c.name as course_name,
        c.code as course_code
      FROM ${DatabaseConfig.tableStudentEnrollments} e
      INNER JOIN ${DatabaseConfig.tableUsers} u ON u.${DatabaseConfig.columnId} = e.student_id
      LEFT JOIN ${DatabaseConfig.tableGroups} g ON g.${DatabaseConfig.columnId} = e.group_id
      LEFT JOIN ${DatabaseConfig.tableCourses} c ON c.${DatabaseConfig.columnId} = e.course_id
      WHERE e.course_id = ?
      ORDER BY u.display_name ASC
    ''', [courseId]);

    return result.map((map) {
      final enrollment = _fromMap(map);
      return enrollment.copyWith(
        studentName: map['student_name'] as String?,
        studentEmail: map['student_email'] as String?,
        studentAvatarUrl: map['student_avatar_url'] as String?,
        groupName: map['group_name'] as String?,
        courseName: map['course_name'] as String?,
        courseCode: map['course_code'] as String?,
      );
    }).toList();
  }

  /// Update enrollment (change group)
  Future<int> update(StudentEnrollmentEntity enrollment) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableStudentEnrollments,
      _toMap(enrollment),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [enrollment.id],
    );
  }

  /// Unenroll a student from a course
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableStudentEnrollments,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Unenroll student from a specific course/semester
  Future<int> deleteByStudentAndCourse(
    String studentId,
    String courseId,
    String semesterId,
  ) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableStudentEnrollments,
      where: 'student_id = ? AND course_id = ? AND semester_id = ?',
      whereArgs: [studentId, courseId, semesterId],
    );
  }

  /// Check if student is enrolled in a course
  Future<bool> isStudentEnrolled(
    String studentId,
    String courseId,
    String semesterId,
  ) async {
    final enrollment = await getByStudentAndCourse(studentId, courseId, semesterId);
    return enrollment != null;
  }

  /// Get student count in a group
  Future<int> getStudentCountInGroup(String groupId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableStudentEnrollments} WHERE group_id = ?',
      [groupId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get student count in a course
  Future<int> getStudentCountInCourse(String courseId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableStudentEnrollments} WHERE course_id = ?',
      [courseId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total enrollment count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableStudentEnrollments}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
