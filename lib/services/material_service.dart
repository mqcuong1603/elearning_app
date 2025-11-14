import 'package:file_picker/file_picker.dart';
import '../models/material_model.dart';
import '../models/announcement_model.dart'; // For AttachmentModel
import '../config/app_constants.dart';
import 'firestore_service.dart';
import 'hive_service.dart';
import 'storage_service.dart';

/// Material Service
/// Handles all material-related operations including CRUD, file uploads, and view/download tracking
class MaterialService {
  final FirestoreService _firestoreService;
  final HiveService _hiveService;
  final StorageService _storageService;

  MaterialService({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _hiveService = hiveService,
        _storageService = storageService;

  /// Get all materials
  Future<List<MaterialModel>> getAllMaterials() async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionMaterials,
        orderBy: 'createdAt',
        descending: true,
      );

      final materials =
          data.map((json) => MaterialModel.fromJson(json)).toList();

      return materials;
    } catch (e) {
      print('Get all materials error: $e');
      return [];
    }
  }

  /// Get materials by course
  /// Materials are automatically visible to all students in the course (no group filtering)
  Future<List<MaterialModel>> getMaterialsByCourse(String courseId) async {
    try {
      final data = await _firestoreService.query(
        collection: AppConstants.collectionMaterials,
        filters: [
          QueryFilter(field: 'courseId', isEqualTo: courseId),
        ],
        orderBy: 'createdAt',
        descending: true,
      );

      return data.map((json) => MaterialModel.fromJson(json)).toList();
    } catch (e) {
      print('Get materials by course error: $e');

      // Fallback: Try without orderBy if index is missing
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          print('Attempting query without orderBy and sorting in memory...');
          final data = await _firestoreService.query(
            collection: AppConstants.collectionMaterials,
            filters: [
              QueryFilter(field: 'courseId', isEqualTo: courseId),
            ],
          );

          final materials =
              data.map((json) => MaterialModel.fromJson(json)).toList();

          // Sort in memory by createdAt descending
          materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return materials;
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }

      return [];
    }
  }

  /// Get materials visible to a specific student
  /// Note: Materials are automatically visible to ALL students in a course
  Future<List<MaterialModel>> getMaterialsForStudent({
    required String courseId,
    required String studentId,
  }) async {
    // For materials, we simply get all materials in the course
    // No group filtering is applied (unlike announcements/assignments)
    return getMaterialsByCourse(courseId);
  }

  /// Get material by ID
  Future<MaterialModel?> getMaterialById(String id) async {
    try {
      final data = await _firestoreService.read(
        collection: AppConstants.collectionMaterials,
        documentId: id,
      );

      if (data == null) return null;

      return MaterialModel.fromJson(data);
    } catch (e) {
      print('Get material by ID error: $e');
      return null;
    }
  }

  /// Create a new material
  Future<String> createMaterial({
    required String courseId,
    required String title,
    required String description,
    required String instructorId,
    required String instructorName,
    List<PlatformFile>? files,
    List<LinkModel>? links,
  }) async {
    try {
      // Upload files if provided
      List<AttachmentModel> attachments = [];
      if (files != null && files.isNotEmpty) {
        attachments = await _uploadFiles(files, courseId);
      }

      final material = MaterialModel(
        id: '', // Firestore will generate
        courseId: courseId,
        title: title,
        description: description,
        files: attachments,
        links: links ?? [],
        instructorId: instructorId,
        instructorName: instructorName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewedBy: [],
        downloadedBy: {},
      );

      final id = await _firestoreService.create(
        collection: AppConstants.collectionMaterials,
        data: material.toJson(),
      );

      return id;
    } catch (e) {
      print('Create material error: $e');
      rethrow;
    }
  }

  /// Update an existing material
  Future<void> updateMaterial({
    required MaterialModel material,
    List<PlatformFile>? newFiles,
    List<String>? filesToRemove,
  }) async {
    try {
      List<AttachmentModel> updatedFiles = List.from(material.files);

      // Remove files if specified
      if (filesToRemove != null && filesToRemove.isNotEmpty) {
        for (final fileId in filesToRemove) {
          final fileToRemove = updatedFiles.firstWhere(
            (f) => f.id == fileId,
            orElse: () => AttachmentModel(
              id: '',
              filename: '',
              url: '',
              size: 0,
              type: '',
            ),
          );

          if (fileToRemove.id.isNotEmpty) {
            // Delete from storage
            await _storageService.deleteFile(fileToRemove.url);
            updatedFiles.removeWhere((f) => f.id == fileId);
          }
        }
      }

      // Upload new files if provided
      if (newFiles != null && newFiles.isNotEmpty) {
        final newAttachments = await _uploadFiles(newFiles, material.courseId);
        updatedFiles.addAll(newAttachments);
      }

      final updatedMaterial = material.copyWith(
        files: updatedFiles,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.update(
        collection: AppConstants.collectionMaterials,
        documentId: material.id,
        data: updatedMaterial.toJson(),
      );
    } catch (e) {
      print('Update material error: $e');
      rethrow;
    }
  }

  /// Delete a material
  Future<void> deleteMaterial(String materialId) async {
    try {
      // Get material to delete associated files
      final material = await getMaterialById(materialId);
      if (material != null) {
        // Delete all files from storage
        for (final file in material.files) {
          try {
            await _storageService.deleteFile(file.url);
          } catch (e) {
            print('Error deleting file ${file.filename}: $e');
          }
        }
      }

      // Delete document from Firestore
      await _firestoreService.delete(
        collection: AppConstants.collectionMaterials,
        documentId: materialId,
      );
    } catch (e) {
      print('Delete material error: $e');
      rethrow;
    }
  }

  /// Mark material as viewed by a student
  Future<void> markMaterialAsViewed({
    required String materialId,
    required String userId,
  }) async {
    try {
      final material = await getMaterialById(materialId);
      if (material == null) return;

      // Check if user has already viewed
      if (material.hasViewedBy(userId)) {
        return; // Already viewed
      }

      // Add user to viewedBy list
      final updatedViewedBy = List<String>.from(material.viewedBy)..add(userId);

      await _firestoreService.update(
        collection: AppConstants.collectionMaterials,
        documentId: materialId,
        data: {'viewedBy': updatedViewedBy},
      );
    } catch (e) {
      print('Mark material as viewed error: $e');
    }
  }

  /// Track file download by a student
  Future<void> trackDownload({
    required String materialId,
    required String fileId,
    required String userId,
  }) async {
    try {
      final material = await getMaterialById(materialId);
      if (material == null) return;

      // Get current download tracking
      final updatedDownloadedBy = Map<String, List<String>>.from(
        material.downloadedBy,
      );

      // Add user to the file's download list
      if (updatedDownloadedBy.containsKey(fileId)) {
        if (!updatedDownloadedBy[fileId]!.contains(userId)) {
          updatedDownloadedBy[fileId] = [
            ...updatedDownloadedBy[fileId]!,
            userId,
          ];
        }
      } else {
        updatedDownloadedBy[fileId] = [userId];
      }

      await _firestoreService.update(
        collection: AppConstants.collectionMaterials,
        documentId: materialId,
        data: {'downloadedBy': updatedDownloadedBy},
      );
    } catch (e) {
      print('Track download error: $e');
    }
  }

  /// Get view statistics for a material
  Future<Map<String, dynamic>> getMaterialViewStats(String materialId) async {
    try {
      final material = await getMaterialById(materialId);
      if (material == null) {
        return {
          'viewCount': 0,
          'downloadCount': 0,
          'viewedBy': <String>[],
          'downloadedBy': <String, List<String>>{},
        };
      }

      // Calculate total downloads
      int totalDownloads = 0;
      material.downloadedBy.forEach((fileId, userIds) {
        totalDownloads += userIds.length;
      });

      return {
        'viewCount': material.viewCount,
        'downloadCount': totalDownloads,
        'viewedBy': material.viewedBy,
        'downloadedBy': material.downloadedBy,
      };
    } catch (e) {
      print('Get material view stats error: $e');
      return {
        'viewCount': 0,
        'downloadCount': 0,
        'viewedBy': <String>[],
        'downloadedBy': <String, List<String>>{},
      };
    }
  }

  /// Search materials by title or description
  Future<List<MaterialModel>> searchMaterials({
    required String courseId,
    required String query,
  }) async {
    try {
      final materials = await getMaterialsByCourse(courseId);

      if (query.trim().isEmpty) {
        return materials;
      }

      final lowercaseQuery = query.toLowerCase();

      return materials.where((material) {
        final titleMatch = material.title.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch =
            material.description.toLowerCase().contains(lowercaseQuery);
        return titleMatch || descriptionMatch;
      }).toList();
    } catch (e) {
      print('Search materials error: $e');
      return [];
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Upload files to Firebase Storage
  Future<List<AttachmentModel>> _uploadFiles(
    List<PlatformFile> files,
    String courseId,
  ) async {
    final attachments = <AttachmentModel>[];

    for (final file in files) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = '${AppConstants.storageMaterials}/$courseId';

        final url = await _storageService.uploadPlatformFile(
          file: file,
          storagePath: path,
        );

        final attachment = AttachmentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filename: file.name,
          url: url,
          size: file.size,
          type: file.extension ?? 'unknown',
        );

        attachments.add(attachment);
      } catch (e) {
        print('Error uploading file ${file.name}: $e');
      }
    }

    return attachments;
  }
}
