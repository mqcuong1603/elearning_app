import 'package:elearning_app/features/announcement/domain/entities/announcement_entity.dart';

/// Abstract repository interface for announcement operations
/// PDF Requirement: Group-scoped announcements with comments
abstract class AnnouncementRepositoryInterface {
  /// Create a new announcement
  Future<bool> createAnnouncement(AnnouncementEntity announcement);

  /// Get announcement by ID
  Future<AnnouncementEntity?> getAnnouncementById(String id);

  /// Get all announcements for a course
  Future<List<AnnouncementEntity>> getAnnouncementsByCourse(String courseId);

  /// Get announcements for a specific group
  Future<List<AnnouncementEntity>> getAnnouncementsByGroup(String groupId);

  /// Update an announcement
  Future<bool> updateAnnouncement(AnnouncementEntity announcement);

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String id);

  /// Get announcement count
  Future<int> getAnnouncementCount({String? courseId});
}
