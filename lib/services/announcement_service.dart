import 'package:file_picker/file_picker.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'email_service.dart';

/// Announcement Service
/// Handles all announcement-related operations including CRUD, tracking, and file uploads
class AnnouncementService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final StorageService _storageService;
  final NotificationService _notificationService;
  final EmailService _emailService;

  AnnouncementService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required StorageService storageService,
    required NotificationService notificationService,
    required EmailService emailService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _storageService = storageService,
        _notificationService = notificationService,
        _emailService = emailService;

  /// Get all announcements
  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAnnouncements,
        orderBy: 'createdAt',
        descending: true,
      );

      final announcements =
          data.map((json) => AnnouncementModel.fromJson(json)).toList();

      // Cache announcements
      await _cacheAnnouncements(announcements);

      return announcements;
    } catch (e) {
      print('Get all announcements error: $e');
      // Try to get from cache if online fetch fails
      return _getCachedAnnouncements();
    }
  }

  /// Get announcements by course
  Future<List<AnnouncementModel>> getAnnouncementsByCourse(
    String courseId,
  ) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionAnnouncements,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
        orderBy: 'createdAt',
        descending: true,
      );

      return data.map((json) => AnnouncementModel.fromJson(json)).toList();
    } catch (e) {
      print('Get announcements by course error: $e');

      // Fallback: Try without orderBy if index is missing
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          print('Attempting query without orderBy and sorting in memory...');
          final data = await _firestoreService.query(
            collection: AppConstants.collectionAnnouncements,
            filters: [
              QueryFilter(field: 'courseId', isEqualTo: courseId),
            ],
          );

          final announcements =
              data.map((json) => AnnouncementModel.fromJson(json)).toList();

          // Sort in memory by createdAt descending
          announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return announcements;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get announcements visible to a specific student (based on group membership)
  Future<List<AnnouncementModel>> getAnnouncementsForStudent({
    required String courseId,
    required String studentId,
    required List<String> studentGroupIds,
  }) async {
    try {
      // Get all announcements for the course
      final allAnnouncements = await getAnnouncementsByCourse(courseId);

      // Filter announcements that are:
      // 1. For all groups (empty groupIds)
      // 2. For groups that the student belongs to
      final visibleAnnouncements = allAnnouncements.where((announcement) {
        if (announcement.isForAllGroups) {
          return true; // Visible to all students in course
        }
        // Check if any of the announcement's groups match student's groups
        return announcement.groupIds
            .any((groupId) => studentGroupIds.contains(groupId));
      }).toList();

      return visibleAnnouncements;
    } catch (e) {
      print('Get announcements for student error: $e');
      return [];
    }
  }

  /// Get announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionAnnouncements,
        documentId: id,
      );

      if (data == null) return null;

      return AnnouncementModel.fromJson(data);
    } catch (e) {
      print('Get announcement by ID error: $e');
      return null;
    }
  }

  /// Create new announcement
  Future<AnnouncementModel> createAnnouncement({
    required String courseId,
    required String title,
    required String content,
    required List<String> groupIds,
    required String instructorId,
    required String instructorName,
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      final now = DateTime.now();

      // Create announcement first without attachments
      final announcement = AnnouncementModel(
        id: '', // Will be set by Firestore
        courseId: courseId,
        title: title,
        content: content,
        attachments: [], // Empty initially
        groupIds: groupIds,
        instructorId: instructorId,
        instructorName: instructorName,
        createdAt: now,
        updatedAt: now,
        viewedBy: [],
        downloadedBy: {},
        comments: [],
      );

      // Create announcement in Firestore to get ID
      final id = await _firestoreService.create(
        collection: AppConstants.collectionAnnouncements,
        data: announcement.toJson(),
      );

      // Now upload attachments with the proper announcement ID
      List<AttachmentModel> attachments = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        print('Uploading ${attachmentFiles.length} attachments for announcement $id');
        attachments = await _uploadAttachments(
          files: attachmentFiles,
          courseId: courseId,
          announcementId: id,
        );
        print('Successfully uploaded ${attachments.length} attachments');

        // Update announcement with attachments
        if (attachments.isNotEmpty) {
          print('Updating announcement with attachments');
          await _firestoreService.update(
            collection: AppConstants.collectionAnnouncements,
            documentId: id,
            data: {'attachments': attachments.map((a) => a.toJson()).toList()},
          );
          print('Announcement updated with attachments');
        }
      }

      final createdAnnouncement = announcement.copyWith(
        id: id,
        attachments: attachments,
      );

      // Clear cache to force refresh
      await _clearAnnouncementsCache();

      // NOTIFICATION TRIGGER: Send notifications to students in the groups
      try {
        await _sendAnnouncementNotifications(
          announcementId: id,
          announcementTitle: title,
          courseId: courseId,
          groupIds: groupIds,
        );
      } catch (e) {
        print('Error sending announcement notifications: $e');
        // Don't fail the announcement creation if notifications fail
      }

      return createdAnnouncement;
    } catch (e) {
      print('Create announcement error: $e');
      throw Exception('Failed to create announcement: ${e.toString()}');
    }
  }

  /// Update announcement
  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestoreService.update(
        collection: AppConstants.collectionAnnouncements,
        documentId: announcement.id,
        data: announcement.copyWith(updatedAt: DateTime.now()).toJson(),
      );

      // Clear cache to force refresh
      await _clearAnnouncementsCache();
    } catch (e) {
      print('Update announcement error: $e');
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  /// Update announcement with new attachments
  Future<AnnouncementModel> updateAnnouncementWithFiles({
    required AnnouncementModel announcement,
    List<PlatformFile>? newAttachmentFiles,
  }) async {
    try {
      // Upload new attachments if any
      List<AttachmentModel> newAttachments = [];
      if (newAttachmentFiles != null && newAttachmentFiles.isNotEmpty) {
        print('Uploading ${newAttachmentFiles.length} new attachments for announcement ${announcement.id}');
        newAttachments = await _uploadAttachments(
          files: newAttachmentFiles,
          courseId: announcement.courseId,
          announcementId: announcement.id,
        );
        print('Successfully uploaded ${newAttachments.length} new attachments');
      }

      // Combine existing and new attachments
      final allAttachments = [
        ...announcement.attachments,
        ...newAttachments,
      ];

      // Update announcement with combined attachments
      final updatedAnnouncement = announcement.copyWith(
        attachments: allAttachments,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.update(
        collection: AppConstants.collectionAnnouncements,
        documentId: announcement.id,
        data: updatedAnnouncement.toJson(),
      );

      // Clear cache to force refresh
      await _clearAnnouncementsCache();

      return updatedAnnouncement;
    } catch (e) {
      print('Update announcement with files error: $e');
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      // Get announcement to delete its attachments
      final announcement = await getAnnouncementById(id);
      if (announcement == null) {
        throw Exception('Announcement not found');
      }

      // Delete attachments from storage
      for (final attachment in announcement.attachments) {
        try {
          await _storageService.deleteFile(attachment.url);
        } catch (e) {
          print('Failed to delete attachment ${attachment.filename}: $e');
          // Continue even if deletion fails
        }
      }

      await _firestoreService.delete(
        collection: AppConstants.collectionAnnouncements,
        documentId: id,
      );

      // Clear cache to force refresh
      await _clearAnnouncementsCache();
    } catch (e) {
      print('Delete announcement error: $e');
      throw Exception('Failed to delete announcement: ${e.toString()}');
    }
  }

  /// Mark announcement as viewed by user
  Future<void> markAsViewed({
    required String announcementId,
    required String userId,
  }) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      if (announcement == null) return;

      // Check if user has already viewed
      if (announcement.hasViewedBy(userId)) return;

      // Add user to viewedBy list
      final updatedViewedBy = [...announcement.viewedBy, userId];

      await updateAnnouncement(
        announcement.copyWith(viewedBy: updatedViewedBy),
      );
    } catch (e) {
      print('Mark as viewed error: $e');
      // Don't throw - this is not critical
    }
  }

  /// Track attachment download
  Future<void> trackDownload({
    required String announcementId,
    required String attachmentId,
    required String userId,
  }) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      if (announcement == null) return;

      // Get current downloads for this attachment
      final currentDownloads =
          announcement.downloadedBy[attachmentId] ?? <String>[];

      // Check if user has already downloaded
      if (currentDownloads.contains(userId)) return;

      // Add user to downloaded list
      final updatedDownloadedBy = Map<String, List<String>>.from(
        announcement.downloadedBy,
      );
      updatedDownloadedBy[attachmentId] = [...currentDownloads, userId];

      await updateAnnouncement(
        announcement.copyWith(downloadedBy: updatedDownloadedBy),
      );
    } catch (e) {
      print('Track download error: $e');
      // Don't throw - this is not critical
    }
  }

  /// Get view statistics for an announcement
  Future<Map<String, dynamic>> getViewStats(String announcementId) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      if (announcement == null) {
        return {
          'totalViews': 0,
          'viewedBy': <String>[],
          'totalDownloads': 0,
          'downloadedBy': <String, List<String>>{},
        };
      }

      // Calculate total downloads across all attachments
      int totalDownloads = 0;
      for (var userList in announcement.downloadedBy.values) {
        totalDownloads += userList.length;
      }

      return {
        'totalViews': announcement.viewCount,
        'viewedBy': announcement.viewedBy,
        'totalDownloads': totalDownloads,
        'downloadedBy': announcement.downloadedBy,
      };
    } catch (e) {
      print('Get view stats error: $e');
      return {
        'totalViews': 0,
        'viewedBy': <String>[],
        'totalDownloads': 0,
        'downloadedBy': <String, List<String>>{},
      };
    }
  }

  /// Stream announcements by course (real-time updates)
  Stream<List<AnnouncementModel>> streamAnnouncementsByCourse(
    String courseId,
  ) {
    return _firestoreService
        .streamQuery(
      collection: AppConstants.collectionAnnouncements,
      filters: [
        QueryFilter(field: 'courseId', isEqualTo: courseId),
      ],
      orderBy: 'createdAt',
      descending: true,
    )
        .map((data) {
      return data.map((json) => AnnouncementModel.fromJson(json)).toList();
    });
  }

  /// Get announcement count by course
  Future<int> getAnnouncementCountByCourse(String courseId) async {
    try {
      return await _firestoreService.count(
        collection: AppConstants.collectionAnnouncements,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
      );
    } catch (e) {
      print('Get announcement count by course error: $e');
      return 0;
    }
  }

  /// Add comment to announcement
  Future<void> addComment({
    required String announcementId,
    required String userId,
    required String userFullName,
    required String content,
  }) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      if (announcement == null) {
        throw Exception('Announcement not found');
      }

      // Create new comment
      final comment = AnnouncementComment(
        id: '${announcementId}_comment_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userFullName: userFullName,
        content: content,
        createdAt: DateTime.now(),
      );

      // Add comment to list
      final updatedComments = [...announcement.comments, comment];

      await updateAnnouncement(
        announcement.copyWith(comments: updatedComments),
      );
    } catch (e) {
      print('Add comment error: $e');
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  /// Delete comment from announcement
  Future<void> deleteComment({
    required String announcementId,
    required String commentId,
  }) async {
    try {
      final announcement = await getAnnouncementById(announcementId);
      if (announcement == null) {
        throw Exception('Announcement not found');
      }

      // Remove comment from list
      final updatedComments = announcement.comments
          .where((comment) => comment.id != commentId)
          .toList();

      await updateAnnouncement(
        announcement.copyWith(comments: updatedComments),
      );
    } catch (e) {
      print('Delete comment error: $e');
      throw Exception('Failed to delete comment: ${e.toString()}');
    }
  }

  /// Upload attachments to storage
  Future<List<AttachmentModel>> _uploadAttachments({
    required List<PlatformFile> files,
    required String courseId,
    required String announcementId,
  }) async {
    final attachments = <AttachmentModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();

      try {
        // Upload to storage
        final storagePath =
            'announcements/$courseId/$announcementId';
        final downloadUrl = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: storagePath,
        );

        // Get file size
        final fileSize = file.size;

        // Create attachment model
        final attachment = AttachmentModel(
          id: '${announcementId}_attachment_$i',
          url: downloadUrl,
          filename: filename,
          size: fileSize,
          type: extension,
        );

        attachments.add(attachment);
        print('Successfully added attachment: $filename (${attachment.formattedSize})');
      } catch (e) {
        print('ERROR: Failed to upload attachment $filename: $e');
        // Continue with other files - don't throw, just log and skip
      }
    }

    print('Total attachments uploaded: ${attachments.length} of ${files.length}');
    return attachments;
  }

  /// Private: Cache announcements
  Future<void> _cacheAnnouncements(
      List<AnnouncementModel> announcements) async {
    try {
      final announcementsJson = announcements.map((a) => a.toJson()).toList();
      await _hiveService.cacheWithExpiration(
        boxName: AppConstants.hiveBoxAnnouncements,
        key: 'all_announcements',
        value: announcementsJson,
        duration: AppConstants.cacheValidDuration,
      );
    } catch (e) {
      print('Cache announcements error: $e');
    }
  }

  /// Private: Get cached announcements
  List<AnnouncementModel> _getCachedAnnouncements() {
    try {
      final cached = _hiveService.getCached(key: 'all_announcements');
      if (cached != null && cached is List) {
        return cached
            .map((json) =>
                AnnouncementModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get cached announcements error: $e');
      return [];
    }
  }

  /// Private: Clear announcements cache
  Future<void> _clearAnnouncementsCache() async {
    try {
      await _hiveService.delete(
        boxName: AppConstants.hiveBoxCache,
        key: 'all_announcements',
      );
    } catch (e) {
      print('Clear announcements cache error: $e');
    }
  }

  /// Private: Send announcement notifications to students
  Future<void> _sendAnnouncementNotifications({
    required String announcementId,
    required String announcementTitle,
    required String courseId,
    required List<String> groupIds,
  }) async {
    try {
      print('📢 Starting announcement notification process');
      print('   Announcement: $announcementTitle');
      print('   Course ID: $courseId');
      print('   Group IDs to notify: $groupIds');

      // Get course details
      final courseData = await _firestoreService.read(
        collection: AppConstants.collectionCourses,
        documentId: courseId,
      );
      if (courseData == null) {
        print('❌ Course not found, aborting notifications');
        return;
      }

      final course = CourseModel.fromJson(courseData);
      final courseName = course.name;
      print('   Course Name: $courseName');

      // Get all students from the specified groups
      final List<String> studentIds = [];
      for (final groupId in groupIds) {
        print('   📋 Fetching group: $groupId');
        final groupData = await _firestoreService.read(
          collection: AppConstants.collectionGroups,
          documentId: groupId,
        );
        if (groupData != null) {
          print('   ✅ Group found: ${groupData['name']}');
          final studentIdsInGroup = List<String>.from(groupData['studentIds'] ?? []);
          print('   👥 Students in group: ${studentIdsInGroup.length} (${studentIdsInGroup.join(', ')})');
          studentIds.addAll(studentIdsInGroup);
        } else {
          print('   ⚠️  Group not found: $groupId');
        }
      }

      // Remove duplicates
      final uniqueStudentIds = studentIds.toSet().toList();
      print('   📊 Total unique students to notify: ${uniqueStudentIds.length}');

      if (uniqueStudentIds.isEmpty) {
        print('❌ No students found in groups, skipping notifications');
        print('   💡 TIP: Make sure students are added to the selected groups');
        return;
      }

      print('✅ Sending announcement notifications to ${uniqueStudentIds.length} students');

      // Create in-app notifications for all students
      print('   📱 Creating in-app notifications...');
      await _notificationService.createNotificationsForUsers(
        userIds: uniqueStudentIds,
        type: AppConstants.notificationTypeAnnouncement,
        title: 'New Announcement: $announcementTitle',
        message: 'A new announcement has been posted in $courseName',
        relatedId: announcementId,
        relatedType: 'announcement',
        data: {
          'courseId': courseId,
          'courseName': courseName,
        },
      );
      print('   ✅ In-app notifications created');

      // Send email notifications to all students
      print('   📧 Sending email notifications...');
      int emailsSent = 0;
      int emailsSkipped = 0;
      for (final studentId in uniqueStudentIds) {
        try {
          final userData = await _firestoreService.read(
            collection: AppConstants.collectionUsers,
            documentId: studentId,
          );
          if (userData != null) {
            final user = UserModel.fromJson(userData);
            if (user.email != null && user.email!.isNotEmpty) {
              print('      📨 Sending email to: ${user.fullName} <${user.email}>');
              // Send email asynchronously (non-blocking)
              _emailService.sendEmailAsync(
                recipientEmail: user.email!,
                recipientName: user.fullName,
                subject: '[$courseName] New Announcement: $announcementTitle',
                body: '''
                  <h2>New Announcement</h2>
                  <p>Hi ${user.fullName},</p>
                  <p>A new announcement has been posted in <strong>$courseName</strong>:</p>
                  <h3>$announcementTitle</h3>
                  <p>Please log in to the E-Learning System to view the full announcement.</p>
                ''',
                isHtml: true,
              );
              emailsSent++;
            } else {
              print('      ⚠️  No email found for student: ${user.fullName} (ID: $studentId)');
              emailsSkipped++;
            }
          } else {
            print('      ⚠️  User data not found for student ID: $studentId');
            emailsSkipped++;
          }
        } catch (e) {
          print('      ❌ Error sending email to student $studentId: $e');
          emailsSkipped++;
          // Continue with other students
        }
      }
      print('   📊 Email summary: $emailsSent sent, $emailsSkipped skipped');

      print('✅ Announcement notifications sent successfully');
    } catch (e) {
      print('Error sending announcement notifications: $e');
      throw e;
    }
  }
}
