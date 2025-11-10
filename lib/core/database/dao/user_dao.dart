import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/auth/domain/entities/user_entity.dart';

/// Data Access Object for User operations
class UserDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert UserEntity to Map for SQLite
  Map<String, dynamic> _toMap(UserEntity user) {
    return {
      DatabaseConfig.columnId: user.id,
      'username': user.username,
      'display_name': user.displayName,
      'email': user.email,
      'password_hash': user.id, // In production, use proper password hashing!
      'avatar_url': user.avatarUrl,
      'role': user.role.name,
      'phone_number': user.phoneNumber,
      'student_id': user.studentId,
      'bio': user.bio,
      DatabaseConfig.columnCreatedAt: user.createdAt.millisecondsSinceEpoch,
      'last_login_at': user.lastLoginAt?.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: user.createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to UserEntity
  UserEntity _fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map[DatabaseConfig.columnId] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.student,
      phoneNumber: map['phone_number'] as String?,
      studentId: map['student_id'] as String?,
      bio: map['bio'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConfig.columnCreatedAt] as int,
      ),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login_at'] as int)
          : null,
    );
  }

  /// Create a new user
  Future<int> insert(UserEntity user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableUsers,
      _toMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple users (for CSV import)
  Future<List<String>> insertBatch(List<UserEntity> users) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var user in users) {
      batch.insert(
        DatabaseConfig.tableUsers,
        _toMap(user),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(user.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get user by ID
  Future<UserEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get user by username (for login)
  Future<UserEntity?> getByUsername(String username) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get user by email
  Future<UserEntity?> getByEmail(String email) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Authenticate user (login)
  /// Returns user if credentials are valid, null otherwise
  Future<UserEntity?> authenticate(String username, String password) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, password], // In production, hash password first!
      limit: 1,
    );

    if (maps.isEmpty) return null;

    // Update last login time
    final user = _fromMap(maps.first);
    await updateLastLogin(user.id);

    return user;
  }

  /// Update last login timestamp
  Future<int> updateLastLogin(String userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableUsers,
      {'last_login_at': DateTime.now().millisecondsSinceEpoch},
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [userId],
    );
  }

  /// Get all users
  Future<List<UserEntity>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      orderBy: 'display_name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get users by role
  Future<List<UserEntity>> getByRole(UserRole role) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: 'role = ?',
      whereArgs: [role.name],
      orderBy: 'display_name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get all students
  Future<List<UserEntity>> getAllStudents() async {
    return await getByRole(UserRole.student);
  }

  /// Get all admins
  Future<List<UserEntity>> getAllAdmins() async {
    return await getByRole(UserRole.admin);
  }

  /// Search users by name or email
  Future<List<UserEntity>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableUsers,
      where: 'display_name LIKE ? OR email LIKE ? OR username LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'display_name ASC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update user
  Future<int> update(UserEntity user) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableUsers,
      _toMap(user),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete user
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableUsers,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DatabaseConfig.tableUsers,
      columns: [DatabaseConfig.columnId],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DatabaseConfig.tableUsers,
      columns: [DatabaseConfig.columnId],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get total user count
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableUsers}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get student count
  Future<int> getStudentCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableUsers} WHERE role = ?',
      [UserRole.student.name],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
