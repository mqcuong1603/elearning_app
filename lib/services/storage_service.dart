import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../config/app_constants.dart';

/// Storage Service
/// Handles file uploads and downloads with Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    String? filename,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (!AppConstants.isValidFileSize(fileSize)) {
        throw Exception(AppConstants.errorFileSize);
      }

      // Get filename
      final fileName = filename ?? path.basename(file.path);

      // Validate file format
      final extension = AppConstants.getFileExtension(fileName);
      final allowedFormats = [
        ...AppConstants.allowedImageFormats,
        ...AppConstants.allowedDocumentFormats,
        ...AppConstants.allowedVideoFormats,
        ...AppConstants.allowedArchiveFormats,
      ];

      if (!allowedFormats.contains(extension)) {
        throw Exception(AppConstants.errorFileFormat);
      }

      // Create reference
      final ref = _storage.ref().child('$storagePath/$fileName');

      // Upload file
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Storage upload error: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String storagePath,
    Function(int completed, int total)? onProgress,
  }) async {
    try {
      final downloadUrls = <String>[];
      int completed = 0;

      for (final file in files) {
        final url = await uploadFile(
          file: file,
          storagePath: storagePath,
        );
        downloadUrls.add(url);
        completed++;

        if (onProgress != null) {
          onProgress(completed, files.length);
        }
      }

      return downloadUrls;
    } catch (e) {
      print('Storage upload multiple error: $e');
      throw Exception('Failed to upload files: ${e.toString()}');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Storage delete error: $e');
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> downloadUrls) async {
    try {
      for (final url in downloadUrls) {
        await deleteFile(url);
      }
    } catch (e) {
      print('Storage delete multiple error: $e');
      throw Exception('Failed to delete files: ${e.toString()}');
    }
  }

  /// Get file metadata
  Future<Map<String, dynamic>> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final metadata = await ref.getMetadata();

      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdAt': metadata.timeCreated,
        'updatedAt': metadata.updated,
        'fullPath': metadata.fullPath,
      };
    } catch (e) {
      print('Storage get metadata error: $e');
      throw Exception('Failed to get file metadata: ${e.toString()}');
    }
  }

  /// Get download URL from storage path
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Storage get download URL error: $e');
      throw Exception('Failed to get download URL: ${e.toString()}');
    }
  }

  /// List files in a directory
  Future<List<Map<String, dynamic>>> listFiles(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final result = await ref.listAll();

      final files = <Map<String, dynamic>>[];

      for (final item in result.items) {
        final metadata = await item.getMetadata();
        final downloadUrl = await item.getDownloadURL();

        files.add({
          'name': item.name,
          'path': item.fullPath,
          'downloadUrl': downloadUrl,
          'size': metadata.size,
          'contentType': metadata.contentType,
          'createdAt': metadata.timeCreated,
        });
      }

      return files;
    } catch (e) {
      print('Storage list files error: $e');
      throw Exception('Failed to list files: ${e.toString()}');
    }
  }

  /// Upload user avatar
  Future<String> uploadAvatar({
    required File file,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath: '${AppConstants.storageUsers}/$userId/avatar',
      filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload course cover image
  Future<String> uploadCourseCover({
    required File file,
    required String courseId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath: '${AppConstants.storageCourses}/$courseId/cover',
      filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload announcement attachment
  Future<String> uploadAnnouncementAttachment({
    required File file,
    required String courseId,
    required String announcementId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath:
          '${AppConstants.storageAnnouncements}/$courseId/$announcementId',
      onProgress: onProgress,
    );
  }

  /// Upload assignment attachment
  Future<String> uploadAssignmentAttachment({
    required File file,
    required String courseId,
    required String assignmentId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath:
          '${AppConstants.storageAssignments}/$courseId/$assignmentId',
      onProgress: onProgress,
    );
  }

  /// Upload assignment submission
  Future<String> uploadSubmission({
    required File file,
    required String assignmentId,
    required String studentId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath:
          '${AppConstants.storageSubmissions}/$assignmentId/$studentId',
      onProgress: onProgress,
    );
  }

  /// Upload material attachment
  Future<String> uploadMaterialAttachment({
    required File file,
    required String courseId,
    required String materialId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath: '${AppConstants.storageMaterials}/$courseId/$materialId',
      onProgress: onProgress,
    );
  }

  /// Upload message attachment
  Future<String> uploadMessageAttachment({
    required File file,
    required String senderId,
    required String receiverId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath:
          '${AppConstants.storageMessages}/${senderId}_$receiverId',
      onProgress: onProgress,
    );
  }

  /// Upload forum attachment
  Future<String> uploadForumAttachment({
    required File file,
    required String courseId,
    required String topicId,
    Function(double progress)? onProgress,
  }) async {
    return await uploadFile(
      file: file,
      storagePath: '${AppConstants.storageForums}/$courseId/$topicId',
      onProgress: onProgress,
    );
  }

  /// Get file size from URL
  Future<int> getFileSize(String downloadUrl) async {
    try {
      final metadata = await getFileMetadata(downloadUrl);
      return metadata['size'] as int;
    } catch (e) {
      print('Storage get file size error: $e');
      return 0;
    }
  }

  /// Validate file before upload
  bool validateFile(File file, String filename) {
    try {
      // Check file size
      final fileSize = file.lengthSync();
      if (!AppConstants.isValidFileSize(fileSize)) {
        return false;
      }

      // Check file format
      final extension = AppConstants.getFileExtension(filename);
      final allowedFormats = [
        ...AppConstants.allowedImageFormats,
        ...AppConstants.allowedDocumentFormats,
        ...AppConstants.allowedVideoFormats,
        ...AppConstants.allowedArchiveFormats,
      ];

      return allowedFormats.contains(extension);
    } catch (e) {
      print('Storage validate file error: $e');
      return false;
    }
  }

  /// Get storage usage for a path (in bytes)
  Future<int> getStorageUsage(String storagePath) async {
    try {
      final files = await listFiles(storagePath);
      int totalSize = 0;

      for (final file in files) {
        totalSize += file['size'] as int;
      }

      return totalSize;
    } catch (e) {
      print('Storage get usage error: $e');
      return 0;
    }
  }

  /// Delete all files in a directory
  Future<void> deleteDirectory(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final result = await ref.listAll();

      // Delete all files
      for (final item in result.items) {
        await item.delete();
      }

      // Recursively delete subdirectories
      for (final prefix in result.prefixes) {
        await deleteDirectory(prefix.fullPath);
      }
    } catch (e) {
      print('Storage delete directory error: $e');
      throw Exception('Failed to delete directory: ${e.toString()}');
    }
  }
}
