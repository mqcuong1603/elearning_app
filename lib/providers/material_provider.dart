// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
// import '../models/material_model.dart';
// import '../services/material_service.dart';

// /// Material Provider
// /// Manages material state and handles material operations
// class MaterialProvider extends ChangeNotifier {
//   final MaterialService _materialService;

//   MaterialProvider({required MaterialService materialService})
//       : _materialService = materialService;

//   // State
//   List<MaterialModel> _materials = [];
//   List<MaterialModel> _filteredMaterials = [];
//   bool _isLoading = false;
//   String? _error;
//   String _searchQuery = '';
//   String? _selectedCourseId;

//   // Getters
//   List<MaterialModel> get materials => _filteredMaterials;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get searchQuery => _searchQuery;
//   String? get selectedCourseId => _selectedCourseId;
//   int get materialsCount => _materials.length;

//   /// Load all materials
//   Future<void> loadMaterials() async {
//     try {
//       _setLoading(true);
//       _error = null;

//       _materials = await _materialService.getAllMaterials();
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Load materials by course
//   Future<void> loadMaterialsByCourse(String courseId) async {
//     try {
//       _setLoading(true);
//       _error = null;
//       _selectedCourseId = courseId;

//       _materials = await _materialService.getMaterialsByCourse(courseId);
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Load materials for a specific student
//   /// Note: Materials are automatically visible to all students in the course
//   Future<void> loadMaterialsForStudent({
//     required String courseId,
//     required String studentId,
//   }) async {
//     try {
//       _setLoading(true);
//       _error = null;
//       _selectedCourseId = courseId;

//       _materials = await _materialService.getMaterialsForStudent(
//         courseId: courseId,
//         studentId: studentId,
//       );
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Get material by ID
//   Future<MaterialModel?> getMaterialById(String id) async {
//     try {
//       return await _materialService.getMaterialById(id);
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Create new material
//   Future<String?> createMaterial({
//     required String courseId,
//     required String title,
//     required String description,
//     required String instructorId,
//     required String instructorName,
//     List<PlatformFile>? files,
//     List<LinkModel>? links,
//   }) async {
//     try {
//       _error = null;

//       final materialId = await _materialService.createMaterial(
//         courseId: courseId,
//         title: title,
//         description: description,
//         instructorId: instructorId,
//         instructorName: instructorName,
//         files: files,
//         links: links,
//       );

//       // Reload materials
//       if (_selectedCourseId != null) {
//         await loadMaterialsByCourse(_selectedCourseId!);
//       } else {
//         await loadMaterials();
//       }

//       return materialId;
//     } catch (e) {
//       _error = e.toString();
//       print('❌ Create material error: $_error');
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update material
//   Future<bool> updateMaterial({
//     required MaterialModel material,
//     List<PlatformFile>? newFiles,
//     List<String>? filesToRemove,
//   }) async {
//     try {
//       _error = null;

//       await _materialService.updateMaterial(
//         material: material,
//         newFiles: newFiles,
//         filesToRemove: filesToRemove,
//       );

//       // Reload materials
//       if (_selectedCourseId != null) {
//         await loadMaterialsByCourse(_selectedCourseId!);
//       } else {
//         await loadMaterials();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       print('❌ Update material error: $_error');
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete material
//   Future<bool> deleteMaterial(String id) async {
//     try {
//       _error = null;

//       await _materialService.deleteMaterial(id);

//       // Reload materials
//       if (_selectedCourseId != null) {
//         await loadMaterialsByCourse(_selectedCourseId!);
//       } else {
//         await loadMaterials();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Mark material as viewed
//   Future<void> markAsViewed({
//     required String materialId,
//     required String userId,
//   }) async {
//     try {
//       await _materialService.markMaterialAsViewed(
//         materialId: materialId,
//         userId: userId,
//       );

//       // Optionally reload to get updated view count
//       // (or update locally for better UX)
//     } catch (e) {
//       print('Mark as viewed error: $e');
//       // Don't show error to user - this is not critical
//     }
//   }

//   /// Track file download
//   Future<void> trackDownload({
//     required String materialId,
//     required String fileId,
//     required String userId,
//   }) async {
//     try {
//       await _materialService.trackDownload(
//         materialId: materialId,
//         fileId: fileId,
//         userId: userId,
//       );

//       // Optionally reload to get updated download count
//     } catch (e) {
//       print('Track download error: $e');
//       // Don't show error to user - this is not critical
//     }
//   }

//   /// Get view statistics for a material
//   Future<Map<String, dynamic>> getMaterialViewStats(String materialId) async {
//     try {
//       return await _materialService.getMaterialViewStats(materialId);
//     } catch (e) {
//       print('Get material view stats error: $e');
//       return {
//         'viewCount': 0,
//         'downloadCount': 0,
//         'viewedBy': <String>[],
//         'downloadedBy': <String, List<String>>{},
//       };
//     }
//   }

//   /// Search materials
//   void searchMaterials(String query) {
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
//       loadMaterialsByCourse(courseId);
//     } else {
//       loadMaterials();
//     }
//   }

//   /// Sort materials by field
//   void sortMaterials(String sortBy, {bool ascending = true}) {
//     switch (sortBy) {
//       case 'title':
//         _filteredMaterials.sort((a, b) => ascending
//             ? a.title.compareTo(b.title)
//             : b.title.compareTo(a.title));
//         break;
//       case 'created':
//         _filteredMaterials.sort((a, b) => ascending
//             ? a.createdAt.compareTo(b.createdAt)
//             : b.createdAt.compareTo(a.createdAt));
//         break;
//       case 'views':
//         _filteredMaterials.sort((a, b) => ascending
//             ? a.viewCount.compareTo(b.viewCount)
//             : b.viewCount.compareTo(a.viewCount));
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
//     loadMaterials();
//   }

//   /// Refresh materials
//   Future<void> refresh() async {
//     if (_selectedCourseId != null) {
//       await loadMaterialsByCourse(_selectedCourseId!);
//     } else {
//       await loadMaterials();
//     }
//   }

//   /// Private: Apply filters
//   void _applyFilters() {
//     if (_searchQuery.isEmpty) {
//       _filteredMaterials = List.from(_materials);
//     } else {
//       _filteredMaterials = _materials.where((material) {
//         return material.title.toLowerCase().contains(_searchQuery) ||
//             material.description.toLowerCase().contains(_searchQuery) ||
//             material.instructorName.toLowerCase().contains(_searchQuery);
//       }).toList();
//     }
//   }

//   /// Private: Set loading state
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
