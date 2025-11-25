// import 'package:flutter/foundation.dart';
// import '../models/group_model.dart';
// import '../services/group_service.dart';

// /// Group Provider
// /// Manages group state and handles group operations
// class GroupProvider extends ChangeNotifier {
//   final GroupService _groupService;

//   GroupProvider({required GroupService groupService})
//       : _groupService = groupService;

//   // State
//   List<GroupModel> _groups = [];
//   List<GroupModel> _filteredGroups = [];
//   bool _isLoading = false;
//   String? _error;
//   String _searchQuery = '';
//   String? _selectedCourseId;

//   // Getters
//   List<GroupModel> get groups => _filteredGroups;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get searchQuery => _searchQuery;
//   String? get selectedCourseId => _selectedCourseId;
//   int get groupsCount => _groups.length;

//   /// Load all groups
//   Future<void> loadGroups() async {
//     try {
//       _setLoading(true);
//       _error = null;

//       _groups = await _groupService.getAllGroups();
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Load groups by course
//   Future<void> loadGroupsByCourse(String courseId) async {
//     try {
//       _setLoading(true);
//       _error = null;
//       _selectedCourseId = courseId;

//       _groups = await _groupService.getGroupsByCourse(courseId);
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Get group by ID
//   Future<GroupModel?> getGroupById(String id) async {
//     try {
//       return await _groupService.getGroupById(id);
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Create new group
//   Future<GroupModel?> createGroup({
//     required String name,
//     required String courseId,
//     List<String>? studentIds,
//   }) async {
//     try {
//       _error = null;

//       final group = await _groupService.createGroup(
//         name: name,
//         courseId: courseId,
//         studentIds: studentIds,
//       );

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return group;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update group
//   Future<bool> updateGroup(GroupModel group) async {
//     try {
//       _error = null;

//       await _groupService.updateGroup(group);

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete group
//   Future<bool> deleteGroup(String id) async {
//     try {
//       _error = null;

//       await _groupService.deleteGroup(id);

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Add student to group
//   Future<bool> addStudentToGroup({
//     required String groupId,
//     required String studentId,
//   }) async {
//     try {
//       _error = null;

//       await _groupService.addStudentToGroup(
//         groupId: groupId,
//         studentId: studentId,
//       );

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Remove student from group
//   Future<bool> removeStudentFromGroup({
//     required String groupId,
//     required String studentId,
//   }) async {
//     try {
//       _error = null;

//       await _groupService.removeStudentFromGroup(
//         groupId: groupId,
//         studentId: studentId,
//       );

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Batch create groups from CSV
//   Future<Map<String, dynamic>?> importGroupsFromCsv(
//     List<Map<String, String>> groupsData,
//   ) async {
//     try {
//       _error = null;

//       final results = await _groupService.batchCreateGroups(groupsData);

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return results;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Batch assign students to groups from CSV
//   Future<Map<String, dynamic>?> importStudentGroupAssignments(
//     List<Map<String, String>> assignmentsData,
//   ) async {
//     try {
//       _error = null;

//       final results = await _groupService.batchAssignStudentsToGroups(
//         assignmentsData,
//       );

//       // Reload groups
//       if (_selectedCourseId != null) {
//         await loadGroupsByCourse(_selectedCourseId!);
//       } else {
//         await loadGroups();
//       }

//       return results;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Search groups
//   void searchGroups(String query) {
//     _searchQuery = query.toLowerCase();
//     _applyFilters();
//     notifyListeners();
//   }

//   /// Clear search
//   void clearSearch() {
//     _searchQuery = '';
//     _applyFilters();
//     notifyListeners();
//   }

//   /// Filter by course
//   void filterByCourse(String? courseId) {
//     _selectedCourseId = courseId;
//     if (courseId != null) {
//       loadGroupsByCourse(courseId);
//     } else {
//       loadGroups();
//     }
//   }

//   /// Sort groups by field
//   void sortGroups(String sortBy, {bool ascending = true}) {
//     switch (sortBy) {
//       case 'name':
//         _filteredGroups.sort((a, b) => ascending
//             ? a.name.compareTo(b.name)
//             : b.name.compareTo(a.name));
//         break;
//       case 'studentCount':
//         _filteredGroups.sort((a, b) => ascending
//             ? a.studentCount.compareTo(b.studentCount)
//             : b.studentCount.compareTo(a.studentCount));
//         break;
//       case 'created':
//         _filteredGroups.sort((a, b) => ascending
//             ? a.createdAt.compareTo(b.createdAt)
//             : b.createdAt.compareTo(a.createdAt));
//         break;
//     }
//     notifyListeners();
//   }

//   /// Clear error
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   /// Clear course filter
//   void clearCourseFilter() {
//     _selectedCourseId = null;
//     loadGroups();
//   }

//   /// Refresh groups
//   Future<void> refresh() async {
//     if (_selectedCourseId != null) {
//       await loadGroupsByCourse(_selectedCourseId!);
//     } else {
//       await loadGroups();
//     }
//   }

//   /// Private: Apply filters
//   void _applyFilters() {
//     if (_searchQuery.isEmpty) {
//       _filteredGroups = List.from(_groups);
//     } else {
//       _filteredGroups = _groups.where((group) {
//         return group.name.toLowerCase().contains(_searchQuery) ||
//             group.courseId.toLowerCase().contains(_searchQuery);
//       }).toList();
//     }
//   }

//   /// Private: Set loading state
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
