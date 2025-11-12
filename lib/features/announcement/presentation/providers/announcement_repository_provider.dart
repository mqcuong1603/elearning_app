import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_app/features/announcement/data/repositories/announcement_repository.dart';
import 'package:elearning_app/features/announcement/domain/repositories/announcement_repository_interface.dart';

/// Provider for AnnouncementRepository
final announcementRepositoryProvider = Provider<AnnouncementRepositoryInterface>((ref) {
  return AnnouncementRepository();
});
