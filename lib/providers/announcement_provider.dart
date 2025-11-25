// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
// import '../models/announcement_model.dart';
// import '../services/announcement_service.dart';

// /// Announcement Provider
// /// Manages announcement state and handles announcement operations
// class AnnouncementProvider extends ChangeNotifier {
//   final AnnouncementService _announcementService;

//   AnnouncementProvider({required AnnouncementService announcementService})
//       : _announcementService = announcementService;

//   // State
//   List<AnnouncementModel> _announcements = [];
//   List<AnnouncementModel> _filteredAnnouncements = [];
//   bool _isLoading = false;
//   String? _error;
//   String _searchQuery = '';
//   String? _selectedCourseId;

//   // Getters
//   List<AnnouncementModel> get announcements => _filteredAnnouncements;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get searchQuery => _searchQuery;
//   String? get selectedCourseId => _selectedCourseId;
//   int get announcementsCount => _announcements.length;

//   /// Load all announcements
//   Future<void> loadAnnouncements() async {
//     try {
//       _setLoading(true);
//       _error = null;

//       _announcements = await _announcementService.getAllAnnouncements();
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Load announcements by course
//   Future<void> loadAnnouncementsByCourse(String courseId) async {
//     try {
//       _setLoading(true);
//       _error = null;
//       _selectedCourseId = courseId;

//       _announcements =
//           await _announcementService.getAnnouncementsByCourse(courseId);
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Load announcements for a specific student (filtered by group membership)
//   Future<void> loadAnnouncementsForStudent({
//     required String courseId,
//     required String studentId,
//     required List<String> studentGroupIds,
//   }) async {
//     try {
//       _setLoading(true);
//       _error = null;
//       _selectedCourseId = courseId;

//       _announcements =
//           await _announcementService.getAnnouncementsForStudent(
//         courseId: courseId,
//         studentId: studentId,
//         studentGroupIds: studentGroupIds,
//       );
//       _applyFilters();

//       _setLoading(false);
//     } catch (e) {
//       _error = e.toString();
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Get announcement by ID
//   Future<AnnouncementModel?> getAnnouncementById(String id) async {
//     try {
//       return await _announcementService.getAnnouncementById(id);
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Create new announcement
//   Future<AnnouncementModel?> createAnnouncement({
//     required String courseId,
//     required String title,
//     required String content,
//     required List<String> groupIds,
//     required String instructorId,
//     required String instructorName,
//     List<PlatformFile>? attachmentFiles,
//   }) async {
//     try {
//       _error = null;

//       final announcement = await _announcementService.createAnnouncement(
//         courseId: courseId,
//         title: title,
//         content: content,
//         groupIds: groupIds,
//         instructorId: instructorId,
//         instructorName: instructorName,
//         attachmentFiles: attachmentFiles,
//       );

//       // Reload announcements
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return announcement;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return null;
//     }
//   }

//   /// Update announcement
//   Future<bool> updateAnnouncement(AnnouncementModel announcement) async {
//     try {
//       _error = null;

//       await _announcementService.updateAnnouncement(announcement);

//       // Reload announcements
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       print('❌ Create announcement error: $_error');
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Update announcement with new file attachments
//   Future<bool> updateAnnouncementWithFiles({
//     required AnnouncementModel announcement,
//     List<PlatformFile>? newAttachmentFiles,
//   }) async {
//     try {
//       _error = null;

//       await _announcementService.updateAnnouncementWithFiles(
//         announcement: announcement,
//         newAttachmentFiles: newAttachmentFiles,
//       );

//       // Reload announcements
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete announcement
//   Future<bool> deleteAnnouncement(String id) async {
//     try {
//       _error = null;

//       await _announcementService.deleteAnnouncement(id);

//       // Reload announcements
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Mark announcement as viewed
//   Future<void> markAsViewed({
//     required String announcementId,
//     required String userId,
//   }) async {
//     try {
//       await _announcementService.markAsViewed(
//         announcementId: announcementId,
//         userId: userId,
//       );

//       // Optionally reload to get updated view count
//       // (or update locally for better UX)
//     } catch (e) {
//       print('Mark as viewed error: $e');
//       // Don't show error to user - this is not critical
//     }
//   }

//   /// Track attachment download
//   Future<void> trackDownload({
//     required String announcementId,
//     required String attachmentId,
//     required String userId,
//   }) async {
//     try {
//       await _announcementService.trackDownload(
//         announcementId: announcementId,
//         attachmentId: attachmentId,
//         userId: userId,
//       );

//       // Optionally reload to get updated download count
//     } catch (e) {
//       print('Track download error: $e');
//       // Don't show error to user - this is not critical
//     }
//   }

//   /// Get view statistics for an announcement
//   Future<Map<String, dynamic>> getViewStats(String announcementId) async {
//     try {
//       return await _announcementService.getViewStats(announcementId);
//     } catch (e) {
//       print('Get view stats error: $e');
//       return {
//         'totalViews': 0,
//         'viewedBy': <String>[],
//         'totalDownloads': 0,
//         'downloadedBy': <String, List<String>>{},
//       };
//     }
//   }

//   /// Add comment to announcement
//   Future<bool> addComment({
//     required String announcementId,
//     required String userId,
//     required String userFullName,
//     required String content,
//   }) async {
//     try {
//       _error = null;

//       await _announcementService.addComment(
//         announcementId: announcementId,
//         userId: userId,
//         userFullName: userFullName,
//         content: content,
//       );

//       // Reload announcements to get updated comments
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete comment from announcement
//   Future<bool> deleteComment({
//     required String announcementId,
//     required String commentId,
//   }) async {
//     try {
//       _error = null;

//       await _announcementService.deleteComment(
//         announcementId: announcementId,
//         commentId: commentId,
//       );

//       // Reload announcements to get updated comments
//       if (_selectedCourseId != null) {
//         await loadAnnouncementsByCourse(_selectedCourseId!);
//       } else {
//         await loadAnnouncements();
//       }

//       return true;
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Search announcements
//   void searchAnnouncements(String query) {
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
//       loadAnnouncementsByCourse(courseId);
//     } else {
//       loadAnnouncements();
//     }
//   }

//   /// Sort announcements by field
//   void sortAnnouncements(String sortBy, {bool ascending = true}) {
//     switch (sortBy) {
//       case 'title':
//         _filteredAnnouncements.sort((a, b) => ascending
//             ? a.title.compareTo(b.title)
//             : b.title.compareTo(a.title));
//         break;
//       case 'created':
//         _filteredAnnouncements.sort((a, b) => ascending
//             ? a.createdAt.compareTo(b.createdAt)
//             : b.createdAt.compareTo(a.createdAt));
//         break;
//       case 'views':
//         _filteredAnnouncements.sort((a, b) => ascending
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
//     loadAnnouncements();
//   }

//   /// Refresh announcements
//   Future<void> refresh() async {
//     if (_selectedCourseId != null) {
//       await loadAnnouncementsByCourse(_selectedCourseId!);
//     } else {
//       await loadAnnouncements();
//     }
//   }

//   /// Private: Apply filters
//   void _applyFilters() {
//     if (_searchQuery.isEmpty) {
//       _filteredAnnouncements = List.from(_announcements);
//     } else {
//       _filteredAnnouncements = _announcements.where((announcement) {
//         return announcement.title.toLowerCase().contains(_searchQuery) ||
//             announcement.content.toLowerCase().contains(_searchQuery) ||
//             announcement.instructorName.toLowerCase().contains(_searchQuery);
//       }).toList();
//     }
//   }

//   /// Private: Set loading state
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
