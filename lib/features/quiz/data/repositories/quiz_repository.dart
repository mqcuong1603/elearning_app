import 'package:elearning_app/core/database/dao/quiz_dao.dart';
import 'package:elearning_app/features/quiz/domain/entities/quiz_entity.dart';
import 'package:elearning_app/features/quiz/domain/repositories/quiz_repository_interface.dart';

/// Implementation of QuizRepositoryInterface
class QuizRepository implements QuizRepositoryInterface {
  final QuizDao _quizDao;

  QuizRepository({QuizDao? quizDao})
      : _quizDao = quizDao ?? QuizDao();

  @override
  Future<bool> createQuiz(QuizEntity quiz) async {
    try {
      final result = await _quizDao.insert(quiz);
      return result > 0;
    } catch (e) {
      print('Error creating quiz: $e');
      return false;
    }
  }

  @override
  Future<QuizEntity?> getQuizById(String id) async {
    try {
      return await _quizDao.getByIdWithDetails(id);
    } catch (e) {
      print('Error getting quiz by ID: $e');
      return null;
    }
  }

  @override
  Future<List<QuizEntity>> getQuizzesByCourse(String courseId) async {
    try {
      return await _quizDao.getByCourseWithDetails(courseId);
    } catch (e) {
      print('Error getting quizzes by course: $e');
      return [];
    }
  }

  @override
  Future<List<QuizEntity>> getQuizzesByGroup(String groupId) async {
    try {
      return await _quizDao.getByGroup(groupId);
    } catch (e) {
      print('Error getting quizzes by group: $e');
      return [];
    }
  }

  @override
  Future<bool> updateQuiz(QuizEntity quiz) async {
    try {
      final result = await _quizDao.update(quiz);
      return result > 0;
    } catch (e) {
      print('Error updating quiz: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteQuiz(String id) async {
    try {
      final result = await _quizDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  @override
  Future<int> getQuizCount({String? courseId}) async {
    try {
      return await _quizDao.getCount(courseId: courseId);
    } catch (e) {
      print('Error getting quiz count: $e');
      return 0;
    }
  }
}
