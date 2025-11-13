import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

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

      // Create reference - ensure the path is properly formed
      final fullPath = '$storagePath/$fileName';
      print('Uploading file to path: $fullPath');
      final ref = _storage.ref().child(fullPath);

      // Create metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFilename': fileName,
        },
      );

      // Upload file with metadata
      final uploadTask = ref.putFile(file, metadata);

      // Listen to upload progress on the main thread
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (snapshot) {
            if (snapshot.state == TaskState.running) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              onProgress(progress);
            }
          },
          onError: (error) {
            print('Upload progress error: $error');
          },
        );
      }

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {
        print('Upload completed for $fileName');
      });

      // Check if upload was successful
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully. URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage error: ${e.code} - ${e.message}');

      // Provide more specific error messages
      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'You do not have permission to upload files. Please ensure you are logged in.';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload was canceled.';
          break;
        case 'storage/unknown':
          errorMessage = 'An unknown error occurred. Please try again.';
          break;
        case 'storage/object-not-found':
          errorMessage = 'Storage bucket not found. Please check your Firebase configuration.';
          break;
        case 'storage/bucket-not-found':
          errorMessage = 'Storage bucket not configured. Please contact support.';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Storage quota exceeded. Please contact support.';
          break;
        case 'storage/unauthenticated':
          errorMessage = 'You must be logged in to upload files.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Upload failed after multiple retries. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Failed to upload file: ${e.message ?? e.code}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Storage upload error: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload a PlatformFile (works for both web and mobile)
  /// Returns the download URL
  Future<String> uploadPlatformFile({
    required PlatformFile file,
    required String storagePath,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file size
      if (file.size > 0 && !AppConstants.isValidFileSize(file.size)) {
        throw Exception(AppConstants.errorFileSize);
      }

      // Validate file format
      final extension = AppConstants.getFileExtension(file.name);
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
      final fullPath = '$storagePath/${file.name}';
      print('📤 Uploading file to path: $fullPath');
      print('   File size: ${file.size} bytes (${(file.size / 1024 / 1024).toStringAsFixed(2)} MB)');
      print('   Platform: ${kIsWeb ? "Web" : "Mobile"}');
      final ref = _storage.ref().child(fullPath);

      // Create metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFilename': file.name,
        },
      );

      UploadTask uploadTask;

      // Handle web and mobile differently
      try {
        if (kIsWeb) {
          // On web, use bytes
          print('   Using web upload (putData)');
          if (file.bytes == null) {
            throw Exception('File bytes are null');
          }
          print('   Bytes length: ${file.bytes!.length}');
          uploadTask = ref.putData(file.bytes!, metadata);
          print('   Upload task created successfully');
        } else {
          // On mobile, use path
          print('   Using mobile upload (putFile)');
          if (file.path == null) {
            throw Exception('File path is null');
          }
          print('   File path: ${file.path}');
          uploadTask = ref.putFile(File(file.path!), metadata);
          print('   Upload task created successfully');
        }
      } catch (e) {
        print('❌ Error creating upload task: $e');
        rethrow;
      }

      print('   Upload task created, starting upload...');

      // Listen to upload progress and errors
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          print('   Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
          print('   State: ${snapshot.state}');

          if (snapshot.state == TaskState.running && onProgress != null) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        },
        onError: (error) {
          print('❌ Upload stream error: $error');
          if (error is FirebaseException) {
            print('   Firebase error code: ${error.code}');
            print('   Firebase error message: ${error.message}');
          }
        },
      );

      // Wait for upload to complete with timeout
      print('   Waiting for upload to complete...');
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ❌ Upload timed out after 30 seconds');
          print('   This might be a CORS issue or Storage rules blocking the upload');
          throw Exception('Upload timed out. Check Firebase Storage rules and CORS configuration.');
        },
      ).whenComplete(() {
        print('   ✅ Upload completed for ${file.name}');
      });

      // Check if upload was successful
      print('   Upload state: ${snapshot.state}');
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      // Get download URL
      print('   Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ File uploaded successfully!');
      print('   URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage error: ${e.code} - ${e.message}');
      String errorMessage;

      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'You do not have permission to upload files.';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload was canceled.';
          break;
        case 'storage/unknown':
          errorMessage = 'An unknown error occurred. Please try again.';
          break;
        case 'storage/object-not-found':
          errorMessage = 'Storage bucket not found. Please check your Firebase configuration.';
          break;
        case 'storage/bucket-not-found':
          errorMessage = 'Storage bucket not configured. Please contact support.';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Storage quota exceeded. Please contact support.';
          break;
        case 'storage/unauthenticated':
          errorMessage = 'You must be logged in to upload files.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Upload failed after multiple retries. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Failed to upload file: ${e.message ?? e.code}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Storage upload error: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
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
