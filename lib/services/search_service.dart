import '../models/assignment_model.dart';
import '../models/quiz_model.dart';
import '../models/filter_model.dart';
import 'hive_service.dart';
import '../config/app_constants.dart';

/// Search Service
/// Handles search, filter, and sort operations for assignments and quizzes
class SearchService {
  final HiveService _hiveService;

  SearchService({required HiveService hiveService})
      : _hiveService = hiveService;

  // ==================== SEARCH ====================

  /// Search assignments by keyword
  List<AssignmentModel> searchAssignments(
    List<AssignmentModel> assignments,
    String query,
  ) {
    if (query.trim().isEmpty) return assignments;

    final lowerQuery = query.toLowerCase();

    return assignments.where((assignment) {
      return assignment.title.toLowerCase().contains(lowerQuery) ||
          assignment.description.toLowerCase().contains(lowerQuery) ||
          assignment.instructorName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search quizzes by keyword
  List<QuizModel> searchQuizzes(
    List<QuizModel> quizzes,
    String query,
  ) {
    if (query.trim().isEmpty) return quizzes;

    final lowerQuery = query.toLowerCase();

    return quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(lowerQuery) ||
          quiz.description.toLowerCase().contains(lowerQuery) ||
          quiz.instructorName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ==================== FILTER ====================

  /// Filter assignments
  List<AssignmentModel> filterAssignments(
    List<AssignmentModel> assignments,
    FilterOptions options,
  ) {
    var filtered = assignments;

    // Filter by search query
    if (options.searchQuery != null && options.searchQuery!.isNotEmpty) {
      filtered = searchAssignments(filtered, options.searchQuery!);
    }

    // Filter by group
    if (options.groupIds != null && options.groupIds!.isNotEmpty) {
      filtered = filtered.where((assignment) {
        if (assignment.isForAllGroups) return true;
        return assignment.groupIds
            .any((groupId) => options.groupIds!.contains(groupId));
      }).toList();
    }

    // Filter by status
    if (options.statuses != null && options.statuses!.isNotEmpty) {
      filtered = filtered.where((assignment) {
        for (final status in options.statuses!) {
          switch (status.toLowerCase()) {
            case 'open':
              if (assignment.isOpen) return true;
              break;
            case 'closed':
              if (assignment.isClosed) return true;
              break;
            case 'upcoming':
              if (assignment.isUpcoming) return true;
              break;
            case 'late_period':
              if (assignment.isInLatePeriod) return true;
              break;
          }
        }
        return false;
      }).toList();
    }

    // Filter by date range
    if (options.startDate != null) {
      filtered = filtered
          .where((assignment) =>
              assignment.deadline.isAfter(options.startDate!) ||
              assignment.deadline.isAtSameMomentAs(options.startDate!))
          .toList();
    }

    if (options.endDate != null) {
      filtered = filtered
          .where((assignment) =>
              assignment.deadline.isBefore(options.endDate!) ||
              assignment.deadline.isAtSameMomentAs(options.endDate!))
          .toList();
    }

    return filtered;
  }

  /// Filter quizzes
  List<QuizModel> filterQuizzes(
    List<QuizModel> quizzes,
    FilterOptions options,
  ) {
    var filtered = quizzes;

    // Filter by search query
    if (options.searchQuery != null && options.searchQuery!.isNotEmpty) {
      filtered = searchQuizzes(filtered, options.searchQuery!);
    }

    // Filter by group
    if (options.groupIds != null && options.groupIds!.isNotEmpty) {
      filtered = filtered.where((quiz) {
        if (quiz.isForAllGroups) return true;
        return quiz.groupIds
            .any((groupId) => options.groupIds!.contains(groupId));
      }).toList();
    }

    // Filter by status
    if (options.statuses != null && options.statuses!.isNotEmpty) {
      filtered = filtered.where((quiz) {
        for (final status in options.statuses!) {
          switch (status.toLowerCase()) {
            case 'available':
              if (quiz.isAvailable) return true;
              break;
            case 'closed':
              if (quiz.isClosed) return true;
              break;
            case 'upcoming':
              if (quiz.isUpcoming) return true;
              break;
          }
        }
        return false;
      }).toList();
    }

    // Filter by date range
    if (options.startDate != null) {
      filtered = filtered
          .where((quiz) =>
              quiz.closeDate.isAfter(options.startDate!) ||
              quiz.closeDate.isAtSameMomentAs(options.startDate!))
          .toList();
    }

    if (options.endDate != null) {
      filtered = filtered
          .where((quiz) =>
              quiz.closeDate.isBefore(options.endDate!) ||
              quiz.closeDate.isAtSameMomentAs(options.endDate!))
          .toList();
    }

    return filtered;
  }

  // ==================== SORT ====================

  /// Sort assignments
  List<AssignmentModel> sortAssignments(
    List<AssignmentModel> assignments,
    SortOptions options,
  ) {
    final sorted = List<AssignmentModel>.from(assignments);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (options.field) {
        case SortField.name:
          comparison = a.title.compareTo(b.title);
          break;
        case SortField.deadline:
          comparison = a.deadline.compareTo(b.deadline);
          break;
        case SortField.date:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortField.status:
          comparison = _compareAssignmentStatus(a, b);
          break;
        case SortField.score:
          // Assignments don't have a score field directly, so sort by deadline
          comparison = a.deadline.compareTo(b.deadline);
          break;
      }

      return options.order == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Sort quizzes
  List<QuizModel> sortQuizzes(
    List<QuizModel> quizzes,
    SortOptions options,
  ) {
    final sorted = List<QuizModel>.from(quizzes);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (options.field) {
        case SortField.name:
          comparison = a.title.compareTo(b.title);
          break;
        case SortField.deadline:
          comparison = a.closeDate.compareTo(b.closeDate);
          break;
        case SortField.date:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortField.status:
          comparison = _compareQuizStatus(a, b);
          break;
        case SortField.score:
          // Quizzes don't have a score field, so sort by close date
          comparison = a.closeDate.compareTo(b.closeDate);
          break;
      }

      return options.order == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Compare assignment status
  int _compareAssignmentStatus(AssignmentModel a, AssignmentModel b) {
    // Priority: Open > Late Period > Upcoming > Closed
    final aValue = a.isOpen
        ? 4
        : a.isInLatePeriod
            ? 3
            : a.isUpcoming
                ? 2
                : 1;
    final bValue = b.isOpen
        ? 4
        : b.isInLatePeriod
            ? 3
            : b.isUpcoming
                ? 2
                : 1;

    return aValue.compareTo(bValue);
  }

  /// Compare quiz status
  int _compareQuizStatus(QuizModel a, QuizModel b) {
    // Priority: Available > Upcoming > Closed
    final aValue = a.isAvailable
        ? 3
        : a.isUpcoming
            ? 2
            : 1;
    final bValue = b.isAvailable
        ? 3
        : b.isUpcoming
            ? 2
            : 1;

    return aValue.compareTo(bValue);
  }

  // ==================== RECENT SEARCHES CACHE ====================

  /// Save recent search query
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final recentSearches = await getRecentSearches();

      // Add to beginning and limit to 10
      recentSearches.insert(0, query);
      final uniqueSearches = recentSearches.toSet().toList();
      final limitedSearches = uniqueSearches.take(10).toList();

      await _hiveService.save(
        boxName: AppConstants.hiveBoxCache,
        key: 'recent_searches',
        value: limitedSearches,
      );
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  /// Get recent search queries
  Future<List<String>> getRecentSearches() async {
    try {
      final searches = _hiveService.get(
        boxName: AppConstants.hiveBoxCache,
        key: 'recent_searches',
        defaultValue: <String>[],
      );

      if (searches is List) {
        return searches.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'recent_searches',
      );
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }
}
