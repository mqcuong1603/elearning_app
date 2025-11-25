// import 'package:flutter/foundation.dart';
// import '../models/user_model.dart';
// import '../services/student_service.dart';

// /// Student Provider
// /// Manages student state and handles student operations
// class StudentProvider extends ChangeNotifier {
//   final StudentService _studentService;

//   StudentProvider({required StudentService studentService})
//       : _studentService = studentService;

//   // State
//   List<UserModel> _students = [];
//   List<UserModel> _filteredStudents = [];
//   bool _isLoading = false;
//   String? _error;
//   String _searchQuery = '';

//   // Getters
//   List<UserModel> get students => _filteredStudents;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get searchQuery => _searchQuery;
//   int get studentsCount => _students.length;

//   /// Load all students
//   Future<void> loadStudents() async {
//     try {
//       _setLoading(true);
//       _error = null;

//       _students = await _studentService.getAllStudents();
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Get student by ID
//   Future<UserModel?> getStudentById(String id) async {
//     try {
//       final student = await _studentService.getStudentById(id);
//       if (student == null) {
//         // Don't set error for null results, might be offline
//         print('ℹ️ Student $id not found (may be offline)');
//       }
//       return student;
//     } catch (e) {
//       // Only log error once, don't spam the console
//       print('Get student by ID error: $e');
//       return null;
//     }
//   }

//   /// Create new student
//   Future<UserModel?> createStudent({
//     required String username,
//     required String fullName,
//     required String email,
//     String? studentId,
//     String? avatarUrl,
//     Map<String, dynamic>? additionalInfo,
//   }) async {
//     try {
//       _error = null;

//       final student = await _studentService.createStudent(
//         username: username,
//         fullName: fullName,
//         email: email,
//         studentId: studentId,
//         avatarUrl: avatarUrl,
//         additionalInfo: additionalInfo,
//       );

//       // Reload students
//       await loadStudents();

//       return student;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update student
//   Future<bool> updateStudent(UserModel student) async {
//     try {
//       _error = null;

//       await _studentService.updateStudent(student);

//       // Reload students
//       await loadStudents();

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete student
//   Future<bool> deleteStudent(String id) async {
//     try {
//       _error = null;

//       await _studentService.deleteStudent(id);

//       // Reload students
//       await loadStudents();

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Batch create students from CSV
//   Future<Map<String, dynamic>?> importStudentsFromCsv(
//     List<Map<String, String>> studentsData,
//   ) async {
//     try {
//       _error = null;

//       final results = await _studentService.batchCreateStudents(studentsData);

//       // Reload students
//       await loadStudents();

//       return results;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Search students
//   void searchStudents(String query) {
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

//   /// Sort students by field
//   void sortStudents(String sortBy, {bool ascending = true}) {
//     switch (sortBy) {
//       case 'username':
//         _filteredStudents.sort((a, b) => ascending
//             ? a.username.compareTo(b.username)
//             : b.username.compareTo(a.username));
//         break;
//       case 'fullName':
//         _filteredStudents.sort((a, b) => ascending
//             ? a.fullName.compareTo(b.fullName)
//             : b.fullName.compareTo(a.fullName));
//         break;
//       case 'email':
//         _filteredStudents.sort((a, b) => ascending
//             ? a.email.compareTo(b.email)
//             : b.email.compareTo(a.email));
//         break;
//       case 'studentId':
//         _filteredStudents.sort((a, b) {
//           final aId = a.studentId ?? '';
//           final bId = b.studentId ?? '';
//           return ascending ? aId.compareTo(bId) : bId.compareTo(aId);
//         });
//         break;
//       case 'created':
//         _filteredStudents.sort((a, b) => ascending
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

//   /// Refresh students
//   Future<void> refresh() async {
//     await loadStudents();
//   }

//   /// Private: Apply filters
//   void _applyFilters() {
//     if (_searchQuery.isEmpty) {
//       _filteredStudents = List.from(_students);
//     } else {
//       _filteredStudents = _students.where((student) {
//         return student.username.toLowerCase().contains(_searchQuery) ||
//             student.fullName.toLowerCase().contains(_searchQuery) ||
//             student.email.toLowerCase().contains(_searchQuery) ||
//             (student.studentId?.toLowerCase().contains(_searchQuery) ?? false);
//       }).toList();
//     }
//   }

//   /// Private: Set loading state
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
