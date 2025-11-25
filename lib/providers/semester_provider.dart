import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/semester_model.dart';
import '../services/semester_service.dart';

/// Semester Provider
/// Manages semester state using ChangeNotifier
class SemesterProvider extends ChangeNotifier {
  final SemesterService _semesterService;
  StreamSubscription<List<SemesterModel>>? _semesterSubscription;

  SemesterProvider({required SemesterService semesterService})
      : _semesterService = semesterService;

  // State
  List<SemesterModel> _semesters = [];
  SemesterModel? _currentSemester;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  List<SemesterModel> get semesters => _searchQuery.isEmpty
      ? _semesters
      : _semesters
          .where((semester) =>
              semester.code
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              semester.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  SemesterModel? get currentSemester => _currentSemester;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSemesters => _semesters.isNotEmpty;
  int get semesterCount => _semesters.length;

  /// Load all semesters
  Future<void> loadSemesters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _semesters = await _semesterService.getAllSemesters();
      _currentSemester = _semesters.firstWhere(
        (s) => s.isCurrent,
        orElse: () =>
            _semesters.isNotEmpty ? _semesters.first : _createEmptySemester(),
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new semester
  Future<bool> createSemester({
    required String code,
    required String name,
    bool isCurrent = false,
  }) async {
    try {
      _errorMessage = null;
      notifyListeners();

      final semester = await _semesterService.createSemester(
        code: code,
        name: name,
        isCurrent: isCurrent,
      );

      _semesters.insert(0, semester);

      if (isCurrent) {
        // Update all other semesters to not current
        _semesters = _semesters.map((s) {
          if (s.id != semester.id) {
            return s.copyWith(isCurrent: false);
          }
          return s;
        }).toList();
        _currentSemester = semester;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update semester
  Future<bool> updateSemester(SemesterModel semester) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _semesterService.updateSemester(semester);

      final index = _semesters.indexWhere((s) => s.id == semester.id);
      if (index != -1) {
        _semesters[index] = semester;

        if (semester.isCurrent) {
          // Update all other semesters to not current
          _semesters = _semesters.map((s) {
            if (s.id != semester.id) {
              return s.copyWith(isCurrent: false);
            }
            return s;
          }).toList();
          _currentSemester = semester;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete semester
  Future<bool> deleteSemester(String id) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _semesterService.deleteSemester(id);

      _semesters.removeWhere((s) => s.id == id);

      // If deleted semester was current, set the first one as current
      if (_currentSemester?.id == id) {
        if (_semesters.isNotEmpty) {
          await markAsCurrent(_semesters.first.id);
        } else {
          _currentSemester = null;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark semester as current
  Future<bool> markAsCurrent(String id) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _semesterService.markAsCurrent(id);

      // Update local state
      _semesters = _semesters.map((s) {
        return s.copyWith(isCurrent: s.id == id);
      }).toList();

      _currentSemester = _semesters.firstWhere((s) => s.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Batch create semesters from CSV
  Future<Map<String, dynamic>> importFromCSV(
    List<Map<String, String>> data,
  ) async {
    try {
      _errorMessage = null;
      notifyListeners();

      final results = await _semesterService.batchCreateSemesters(data);

      // Reload semesters after import
      await loadSemesters();

      return results;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'total': data.length,
        'success': 0,
        'failed': data.length,
        'alreadyExists': 0,
        'error': e.toString(),
      };
    }
  }

  /// Check if semester code exists
  Future<bool> semesterCodeExists(String code, {String? excludeId}) async {
    return await _semesterService.semesterCodeExists(code,
        excludeId: excludeId);
  }

  /// Search semesters
  void searchSemesters(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get semester by ID
  SemesterModel? getSemesterById(String id) {
    try {
      return _semesters.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh semesters
  Future<void> refresh() async {
    await loadSemesters();
  }

  /// Start listening to real-time semester updates
  void startListening() {
    _semesterSubscription?.cancel(); // Cancel any existing subscription
    _semesterSubscription = _semesterService.streamSemesters().listen(
      (semesters) {
        _semesters = semesters;
        _currentSemester = semesters.firstWhere(
          (s) => s.isCurrent,
          orElse: () => semesters.isNotEmpty ? semesters.first : _createEmptySemester(),
        );
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Stop listening to real-time updates
  void stopListening() {
    _semesterSubscription?.cancel();
    _semesterSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  /// Create empty semester for default
  SemesterModel _createEmptySemester() {
    return SemesterModel(
      id: '',
      code: '',
      name: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCurrent: false,
    );
  }
}
