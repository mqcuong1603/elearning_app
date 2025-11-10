import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:elearning_app/core/database/database_config.dart';
import 'package:elearning_app/core/database/database_helper.dart';
import 'package:elearning_app/features/quiz/domain/entities/question_entity.dart';

/// Data Access Object for Question operations
/// PDF Requirement: Question bank with difficulty-based random selection
class QuestionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert QuestionEntity to Map for SQLite
  Map<String, dynamic> _toMap(QuestionEntity question) {
    return {
      DatabaseConfig.columnId: question.id,
      'course_id': question.courseId,
      'question_text': question.questionText,
      'choices': jsonEncode(question.choices),
      'correct_answer_index': question.correctAnswerIndex,
      'difficulty': question.difficulty.name,
      'explanation': question.explanation,
      DatabaseConfig.columnCreatedAt: question.createdAt.millisecondsSinceEpoch,
      DatabaseConfig.columnUpdatedAt: question.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from SQLite to QuestionEntity
  QuestionEntity _fromMap(Map<String, dynamic> map) {
    return QuestionEntity(
      id: map[DatabaseConfig.columnId] as String,
      courseId: map['course_id'] as String,
      questionText: map['question_text'] as String,
      choices: List<String>.from(jsonDecode(map['choices'] as String)),
      correctAnswerIndex: map['correct_answer_index'] as int,
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      explanation: map['explanation'] as String?,
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

  /// Create a new question
  Future<int> insert(QuestionEntity question) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConfig.tableQuestions,
      _toMap(question),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple questions (for CSV import)
  Future<List<String>> insertBatch(List<QuestionEntity> questions) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <String>[];

    for (var question in questions) {
      batch.insert(
        DatabaseConfig.tableQuestions,
        _toMap(question),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      results.add(question.id);
    }

    await batch.commit(noResult: true);
    return results;
  }

  /// Get question by ID
  Future<QuestionEntity?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuestions,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// Get all questions for a course
  Future<List<QuestionEntity>> getByCourse(String courseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuestions,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'difficulty, ${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Get questions by difficulty level
  Future<List<QuestionEntity>> getByDifficulty(
    String courseId,
    QuestionDifficulty difficulty,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConfig.tableQuestions,
      where: 'course_id = ? AND difficulty = ?',
      whereArgs: [courseId, difficulty.name],
      orderBy: DatabaseConfig.columnCreatedAt,
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Randomly select questions by difficulty for a quiz
  /// PDF Requirement: "Random question selection (x easy, y medium, z hard)"
  Future<List<QuestionEntity>> getRandomQuestions({
    required String courseId,
    required int easyCount,
    required int mediumCount,
    required int hardCount,
  }) async {
    final selectedQuestions = <QuestionEntity>[];

    // Get random easy questions
    if (easyCount > 0) {
      final easyQuestions = await getByDifficulty(courseId, QuestionDifficulty.easy);
      selectedQuestions.addAll(_selectRandom(easyQuestions, easyCount));
    }

    // Get random medium questions
    if (mediumCount > 0) {
      final mediumQuestions = await getByDifficulty(courseId, QuestionDifficulty.medium);
      selectedQuestions.addAll(_selectRandom(mediumQuestions, mediumCount));
    }

    // Get random hard questions
    if (hardCount > 0) {
      final hardQuestions = await getByDifficulty(courseId, QuestionDifficulty.hard);
      selectedQuestions.addAll(_selectRandom(hardQuestions, hardCount));
    }

    // Shuffle the combined list for random order
    selectedQuestions.shuffle();
    return selectedQuestions;
  }

  /// Helper method to randomly select N items from a list
  List<QuestionEntity> _selectRandom(List<QuestionEntity> questions, int count) {
    if (questions.length <= count) {
      return questions;
    }

    final random = Random();
    final selected = <QuestionEntity>[];
    final available = List<QuestionEntity>.from(questions);

    for (var i = 0; i < count; i++) {
      final index = random.nextInt(available.length);
      selected.add(available.removeAt(index));
    }

    return selected;
  }

  /// Get questions by IDs (for fixed question quizzes)
  Future<List<QuestionEntity>> getByIds(List<String> questionIds) async {
    if (questionIds.isEmpty) return [];

    final db = await _dbHelper.database;
    final placeholders = List.filled(questionIds.length, '?').join(',');

    final maps = await db.query(
      DatabaseConfig.tableQuestions,
      where: '${DatabaseConfig.columnId} IN ($placeholders)',
      whereArgs: questionIds,
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Search questions by text
  Future<List<QuestionEntity>> search(String query, {String? courseId}) async {
    final db = await _dbHelper.database;

    String whereClause = 'question_text LIKE ? OR explanation LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (courseId != null) {
      whereClause += ' AND course_id = ?';
      whereArgs.add(courseId);
    }

    final maps = await db.query(
      DatabaseConfig.tableQuestions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'difficulty, ${DatabaseConfig.columnCreatedAt} DESC',
    );

    return maps.map((map) => _fromMap(map)).toList();
  }

  /// Update question
  Future<int> update(QuestionEntity question) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseConfig.tableQuestions,
      _toMap(question),
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [question.id],
    );
  }

  /// Delete question
  Future<int> delete(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseConfig.tableQuestions,
      where: '${DatabaseConfig.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get question count by difficulty
  Future<Map<QuestionDifficulty, int>> getCountByDifficulty(String courseId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT difficulty, COUNT(*) as count
      FROM ${DatabaseConfig.tableQuestions}
      WHERE course_id = ?
      GROUP BY difficulty
    ''', [courseId]);

    final counts = <QuestionDifficulty, int>{
      QuestionDifficulty.easy: 0,
      QuestionDifficulty.medium: 0,
      QuestionDifficulty.hard: 0,
    };

    for (var row in result) {
      final difficulty = QuestionDifficulty.values.firstWhere(
        (e) => e.name == row['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      );
      counts[difficulty] = row['count'] as int;
    }

    return counts;
  }

  /// Get total question count
  Future<int> getCount({String? courseId}) async {
    final db = await _dbHelper.database;

    String query = 'SELECT COUNT(*) as count FROM ${DatabaseConfig.tableQuestions}';
    List<dynamic> args = [];

    if (courseId != null) {
      query += ' WHERE course_id = ?';
      args.add(courseId);
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if there are enough questions for a quiz
  Future<bool> hasEnoughQuestions({
    required String courseId,
    required int easyCount,
    required int mediumCount,
    required int hardCount,
  }) async {
    final counts = await getCountByDifficulty(courseId);

    return (counts[QuestionDifficulty.easy] ?? 0) >= easyCount &&
           (counts[QuestionDifficulty.medium] ?? 0) >= mediumCount &&
           (counts[QuestionDifficulty.hard] ?? 0) >= hardCount;
  }
}
