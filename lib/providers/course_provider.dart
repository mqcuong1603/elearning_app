import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

/// Course Provider
/// Manages course state and handles course operations
class CourseProvider extends ChangeNotifier {
  final CourseService _courseService;

  CourseProvider({required CourseService courseService})
      : _courseService = courseService;

  // State
  List<CourseModel> _courses = [];
  List<CourseModel> _filteredCourses = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSemesterId;
  String _searchQuery = '';

  // Getters
  List<CourseModel> get courses => _filteredCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSemesterId => _currentSemesterId;
  String get searchQuery => _searchQuery;
  int get coursesCount => _courses.length;

  /// Load all courses
  Future<void> loadCourses() async {
    try {
      _setLoading(true);
      _error = null;

      _courses = await _courseService.getAllCourses();
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load courses by semester
  Future<void> loadCoursesBySemester(String semesterId) async {
    try {
      _setLoading(true);
      _error = null;
      _currentSemesterId = semesterId;

      _courses = await _courseService.getCoursesBySemester(semesterId);
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(String id) async {
    try {
      return await _courseService.getCourseById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create new course
  Future<CourseModel?> createCourse({
    required String code,
    required String name,
    required String semesterId,
    required int sessions,
    String? description,
    String? coverImageUrl,
  }) async {
    try {
      _error = null;

      final course = await _courseService.createCourse(
        code: code,
        name: name,
        semesterId: semesterId,
        sessions: sessions,
        description: description,
        coverImageUrl: coverImageUrl,
      );

      // Reload courses for current semester if needed
      if (_currentSemesterId == semesterId) {
        await loadCoursesBySemester(semesterId);
      }

      return course;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update course
  Future<bool> updateCourse(CourseModel course) async {
    try {
      _error = null;

      await _courseService.updateCourse(course);

      // Reload courses for current semester if needed
      if (_currentSemesterId == course.semesterId) {
        await loadCoursesBySemester(course.semesterId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String id, String semesterId) async {
    try {
      _error = null;

      await _courseService.deleteCourse(id);

      // Reload courses for current semester if needed
      if (_currentSemesterId == semesterId) {
        await loadCoursesBySemester(semesterId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Batch create courses from CSV
  Future<Map<String, dynamic>?> importCoursesFromCsv(
    List<Map<String, String>> coursesData,
    String? defaultSemesterId,
  ) async {
    try {
      _error = null;

      final results = await _courseService.batchCreateCourses(
        coursesData,
        defaultSemesterId,
      );

      // Reload courses for current semester if needed
      if (_currentSemesterId != null) {
        await loadCoursesBySemester(_currentSemesterId!);
      }

      return results;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Check if course code exists in semester
  Future<bool> courseCodeExistsInSemester(
    String code,
    String semesterId, {
    String? excludeId,
  }) async {
    return await _courseService.courseCodeExistsInSemester(
      code,
      semesterId,
      excludeId: excludeId,
    );
  }

  /// Load courses for a student (enrolled through groups)
  Future<List<CourseModel>> loadCoursesForStudent(String studentId) async {
    try {
      _setLoading(true);
      _error = null;

      final courses = await _courseService.getCoursesForStudent(studentId);

      _setLoading(false);
      return courses;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Load courses for a student by semester
  Future<List<CourseModel>> loadCoursesForStudentBySemester(
    String studentId,
    String semesterId,
  ) async {
    try {
      _setLoading(true);
      _error = null;

      final courses = await _courseService.getCoursesForStudentBySemester(
        studentId,
        semesterId,
      );

      _setLoading(false);
      return courses;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Search courses
  void searchCourses(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Sort courses by field
  void sortCourses(String sortBy, {bool ascending = true}) {
    switch (sortBy) {
      case 'code':
        _filteredCourses.sort((a, b) =>
            ascending ? a.code.compareTo(b.code) : b.code.compareTo(a.code));
        break;
      case 'name':
        _filteredCourses.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 'sessions':
        _filteredCourses.sort((a, b) => ascending
            ? a.sessions.compareTo(b.sessions)
            : b.sessions.compareTo(a.sessions));
        break;
      case 'created':
        _filteredCourses.sort((a, b) => ascending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'updated':
        _filteredCourses.sort((a, b) => ascending
            ? a.updatedAt.compareTo(b.updatedAt)
            : b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh courses
  Future<void> refresh() async {
    if (_currentSemesterId != null) {
      await loadCoursesBySemester(_currentSemesterId!);
    } else {
      await loadCourses();
    }
  }

  /// Private: Apply filters
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCourses = List.from(_courses);
    } else {
      _filteredCourses = _courses.where((course) {
        return course.code.toLowerCase().contains(_searchQuery) ||
            course.name.toLowerCase().contains(_searchQuery) ||
            course.instructorName.toLowerCase().contains(_searchQuery) ||
            (course.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  /// Private: Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
