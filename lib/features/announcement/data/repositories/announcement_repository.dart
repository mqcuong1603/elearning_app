import 'package:elearning_app/core/database/dao/announcement_dao.dart';
import 'package:elearning_app/features/announcement/domain/entities/announcement_entity.dart';
import 'package:elearning_app/features/announcement/domain/repositories/announcement_repository_interface.dart';

/// Implementation of AnnouncementRepositoryInterface
class AnnouncementRepository implements AnnouncementRepositoryInterface {
  final AnnouncementDao _announcementDao;

  AnnouncementRepository({AnnouncementDao? announcementDao})
      : _announcementDao = announcementDao ?? AnnouncementDao();

  @override
  Future<bool> createAnnouncement(AnnouncementEntity announcement) async {
    try {
      final result = await _announcementDao.insert(announcement);
      return result > 0;
    } catch (e) {
      print('Error creating announcement: $e');
      return false;
    }
  }

  @override
  Future<AnnouncementEntity?> getAnnouncementById(String id) async {
    try {
      return await _announcementDao.getById(id);
    } catch (e) {
      print('Error getting announcement by ID: $e');
      return null;
    }
  }

  @override
  Future<List<AnnouncementEntity>> getAnnouncementsByCourse(String courseId) async {
    try {
      return await _announcementDao.getByCourse(courseId);
    } catch (e) {
      print('Error getting announcements by course: $e');
      return [];
    }
  }

  @override
  Future<List<AnnouncementEntity>> getAnnouncementsByGroup(String groupId) async {
    try {
      // Get all announcements and filter by group
      final allAnnouncements = await _announcementDao.getAll();
      return allAnnouncements
          .where((a) => a.targetGroupIds.contains(groupId))
          .toList();
    } catch (e) {
      print('Error getting announcements by group: $e');
      return [];
    }
  }

  @override
  Future<bool> updateAnnouncement(AnnouncementEntity announcement) async {
    try {
      final result = await _announcementDao.update(announcement);
      return result > 0;
    } catch (e) {
      print('Error updating announcement: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAnnouncement(String id) async {
    try {
      final result = await _announcementDao.delete(id);
      return result > 0;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  @override
  Future<int> getAnnouncementCount({String? courseId}) async {
    try {
      if (courseId != null) {
        final announcements = await _announcementDao.getByCourse(courseId);
        return announcements.length;
      }
      return await _announcementDao.getCount();
    } catch (e) {
      print('Error getting announcement count: $e');
      return 0;
    }
  }
}
