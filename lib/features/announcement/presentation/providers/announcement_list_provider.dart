import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/announcement/domain/entities/announcement_entity.dart';
import 'package:elearning_app/features/announcement/presentation/providers/announcement_repository_provider.dart';

/// Provider for announcements by course
final announcementsByCourseProvider = FutureProvider.family<List<AnnouncementEntity>, String>((ref, courseId) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return await repository.getAnnouncementsByCourse(courseId);
});

/// Provider for announcements by group
final announcementsByGroupProvider = FutureProvider.family<List<AnnouncementEntity>, String>((ref, groupId) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return await repository.getAnnouncementsByGroup(groupId);
});

/// Provider for announcement detail
final announcementDetailProvider = FutureProvider.family<AnnouncementEntity?, String>((ref, announcementId) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return await repository.getAnnouncementById(announcementId);
});
