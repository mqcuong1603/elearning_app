# Material Service & UI Documentation

## Overview

The Material Service provides a complete system for managing course materials with file/link attachments, automatic visibility to all students, and comprehensive view/download tracking.

## Key Features

### 1. **Create/Edit/Delete Materials**
- Create materials with title, description, files, and links
- Edit existing materials including adding/removing files and links
- Delete materials with automatic cleanup of associated files
- Rich validation and error handling

### 2. **File/Link Attachments**
- **File Attachments**: Upload multiple files of any type to Firebase Storage
- **Link Attachments**: Add external links with custom titles
- Support for mixed content (files + links)
- Automatic file size tracking and display
- File removal with storage cleanup

### 3. **Automatic Visibility**
- Materials are automatically visible to **ALL students** in a course
- No group-based filtering (unlike announcements/assignments)
- Simplified access model as per project requirements

### 4. **View/Download Tracking**
- **View Tracking**: Automatically tracks which users have viewed each material
- **Download Tracking**: Tracks which files have been downloaded by which users
- **Statistics Dashboard**: Instructors can view:
  - Total view count
  - Total download count
  - Individual user activity
  - Per-file download statistics

## Architecture

### Components Created

```
lib/
├── services/
│   └── material_service.dart          # CRUD operations & tracking
├── providers/
│   └── material_provider.dart         # State management
├── models/
│   └── material_model.dart            # Data model (already existed)
├── widgets/
│   └── material_form_dialog.dart      # Create/edit dialog
└── screens/
    └── shared/
        └── material_details_screen.dart  # Material viewing & tracking
```

### Integration Points

1. **main.dart**: MaterialService and MaterialProvider registered with dependency injection
2. **course_space_screen.dart**: Materials tab integration with create/view functionality
3. **Firebase Storage**: Files stored at `materials/{courseId}/{timestamp}_{filename}`
4. **Firestore Collection**: `materials` collection with tracking fields

## Data Model

### MaterialModel

```dart
class MaterialModel {
  final String id;
  final String courseId;
  final String title;
  final String description;

  // Content
  final List<AttachmentModel> files;      // Uploaded files
  final List<LinkModel> links;             // External links

  // Metadata
  final String instructorId;
  final String instructorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Tracking
  final List<String> viewedBy;                        // User IDs who viewed
  final Map<String, List<String>> downloadedBy;       // fileId -> [userId...]
}
```

### LinkModel

```dart
class LinkModel {
  final String id;
  final String url;
  final String title;
}
```

## Usage Guide

### For Instructors

#### Creating a Material

1. Navigate to Course Space
2. Click the **+** (Add Content) button
3. Select **"Add Material"**
4. Fill in the form:
   - **Title**: Material name (required)
   - **Description**: Detailed description (required)
   - **Files**: Add one or more files (optional)
   - **Links**: Add one or more external links (optional)
5. Click **"Create"**

**Note**: At least one file or link is required.

#### Editing a Material

1. Open the material details screen
2. Click the **Edit** icon (top-right)
3. Modify title, description, files, or links
4. Click **"Update"**

#### Deleting a Material

1. Open the material details screen
2. Click the **Delete** icon (top-right)
3. Confirm deletion
4. All files are automatically removed from storage

#### Viewing Statistics

When viewing a material you created, you'll see:
- **View Count**: Number of unique students who viewed
- **Download Count**: Total number of file downloads
- Per-file download tracking available in Firestore

### For Students

#### Viewing Materials

1. Navigate to Course Space
2. Click the **"Classwork"** tab
3. Scroll to the **"Materials"** section
4. Click on any material to view details

#### Downloading Files

1. Open a material
2. Find the file in the **Files** section
3. Click the **Download** icon
4. The file will open in your browser/external app

**Note**: Downloads are automatically tracked for instructor analytics.

#### Opening Links

1. Open a material
2. Find the link in the **Links** section
3. Click the **Open** icon
4. The link opens in an external browser

## Service Layer Details

### MaterialService

**Location**: `lib/services/material_service.dart`

#### Key Methods

```dart
// CRUD Operations
Future<String> createMaterial({...})           // Create with files & links
Future<void> updateMaterial({...})             // Update with file management
Future<void> deleteMaterial(String id)         // Delete with cleanup

// Retrieval
Future<List<MaterialModel>> getMaterialsByCourse(String courseId)
Future<MaterialModel?> getMaterialById(String id)
Future<List<MaterialModel>> getMaterialsForStudent({...})

// Tracking
Future<void> markMaterialAsViewed({...})
Future<void> trackDownload({...})
Future<Map<String, dynamic>> getMaterialViewStats(String materialId)

// Search
Future<List<MaterialModel>> searchMaterials({...})
```

#### File Upload Process

1. Files selected using `file_picker` package
2. Uploaded to Firebase Storage at: `materials/{courseId}/{timestamp}_{filename}`
3. URL stored in `AttachmentModel` with metadata:
   - id, name, url, size, uploadedAt

#### File Deletion Process

1. Files marked for removal via UI
2. Service deletes from Firebase Storage using URL
3. Firestore document updated without deleted file references

### MaterialProvider

**Location**: `lib/providers/material_provider.dart`

#### State Management

```dart
// State
List<MaterialModel> _materials
List<MaterialModel> _filteredMaterials
bool _isLoading
String? _error
String _searchQuery
String? _selectedCourseId

// Public Methods
Future<void> loadMaterialsByCourse(String courseId)
Future<String?> createMaterial({...})
Future<bool> updateMaterial({...})
Future<bool> deleteMaterial(String id)
Future<void> markAsViewed({...})
Future<void> trackDownload({...})
void searchMaterials(String query)
```

## UI Components

### MaterialFormDialog

**Location**: `lib/widgets/material_form_dialog.dart`

**Features**:
- Title and description input with validation
- File picker for multiple files
- Link management with custom dialog
- Visual distinction between new/existing files when editing
- File removal with confirmation
- Form validation ensuring at least one file or link

**Usage**:
```dart
final result = await showDialog<Map<String, dynamic>>(
  context: context,
  builder: (context) => MaterialFormDialog(
    material: existingMaterial,  // null for create
    courseId: courseId,
  ),
);
```

### MaterialDetailsScreen

**Location**: `lib/screens/shared/material_details_screen.dart`

**Features**:
- Material header with title, instructor, date
- Description display
- Files section with download buttons
- Links section with open buttons
- Statistics (instructors only)
- Edit/delete actions (instructors only)
- Automatic view tracking on load
- Download tracking on file download

**Navigation**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MaterialDetailsScreen(material: material),
  ),
);
```

## Firebase Configuration

### Firestore Collection Structure

```
materials/
  {materialId}/
    - id: string
    - courseId: string
    - title: string
    - description: string
    - files: [
        {
          id: string
          name: string
          url: string
          size: number
          uploadedAt: timestamp
        }
      ]
    - links: [
        {
          id: string
          url: string
          title: string
        }
      ]
    - instructorId: string
    - instructorName: string
    - createdAt: timestamp
    - updatedAt: timestamp
    - viewedBy: [userId1, userId2, ...]
    - downloadedBy: {
        fileId1: [userId1, userId2],
        fileId2: [userId3]
      }
```

### Firebase Storage Structure

```
materials/
  {courseId}/
    {timestamp}_{filename}
    {timestamp}_{filename}
    ...
```

### Required Firestore Indexes

```
Collection: materials
  - courseId (Ascending) + createdAt (Descending)
```

## Caching Strategy

### Hive Offline Cache

- **Box Name**: `materials_box`
- **Type ID**: 10 (defined in AppConstants)
- **Storage**: Local Hive database

#### Cache Operations

```dart
// Write to cache
await _cacheMaterials(List<MaterialModel> materials)

// Read from cache
List<MaterialModel> _getCachedMaterials()

// Update single item
await _updateCache(MaterialModel material)

// Remove from cache
await _removeFromCache(String materialId)
```

#### Offline Behavior

1. **Online**: Data fetched from Firestore, then cached
2. **Offline**: Data loaded from cache if available
3. **Sync**: Automatic sync when connection restored

## Security & Permissions

### Access Control

**Instructors**:
- ✅ Create materials
- ✅ Edit own materials
- ✅ Delete own materials
- ✅ View all materials in their courses
- ✅ View statistics

**Students**:
- ✅ View all materials in enrolled courses
- ✅ Download files
- ✅ Open links
- ❌ Cannot create/edit/delete materials
- ❌ Cannot view statistics

### Validation Rules

**Material Creation**:
- Title: Required, max 200 characters
- Description: Required
- Content: At least one file or link required

**File Upload**:
- Type: Any file type allowed
- Size: Limited by Firebase Storage (default 10MB per file)
- Multiple files supported

**Link Addition**:
- URL: Must start with http:// or https://
- Title: Required

## Error Handling

### Common Errors

1. **Network Errors**: Fallback to cached data
2. **Upload Failures**: Individual file errors reported, others continue
3. **Permission Errors**: Clear error messages to user
4. **Validation Errors**: Form-level validation with user feedback

### Error Recovery

```dart
try {
  // Operation
} catch (e) {
  print('Error: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
  // Fallback to cache
  return _getCachedMaterials();
}
```

## Testing Checklist

### Functional Testing

- [ ] Create material with files only
- [ ] Create material with links only
- [ ] Create material with both files and links
- [ ] Edit material - add files
- [ ] Edit material - remove files
- [ ] Edit material - add links
- [ ] Edit material - remove links
- [ ] Delete material
- [ ] View material as instructor
- [ ] View material as student
- [ ] Download file (verify tracking)
- [ ] Open link
- [ ] View statistics as instructor
- [ ] Search materials

### Edge Cases

- [ ] Create material with no content (should fail validation)
- [ ] Upload very large files (should handle gracefully)
- [ ] Upload multiple files simultaneously
- [ ] Edit material while offline (should use cache)
- [ ] Delete material while offline (should fail with message)
- [ ] View material with deleted files (should handle missing files)
- [ ] Track download for same file multiple times by same user

### Performance Testing

- [ ] Load course with 50+ materials
- [ ] Upload 10 files at once
- [ ] View material with 20+ files
- [ ] Download tracking with 100+ students

## Future Enhancements

### Potential Improvements

1. **File Previews**: Show thumbnails for images/PDFs
2. **Bulk Operations**: Upload entire folders
3. **Version Control**: Track material revisions
4. **Comments**: Allow students to comment on materials
5. **Favorites**: Let students bookmark materials
6. **Advanced Search**: Search within file contents
7. **Notifications**: Notify students when new materials added
8. **Analytics Dashboard**: Detailed usage reports for instructors
9. **File Type Restrictions**: Limit allowed file types per course
10. **Expiration Dates**: Automatically hide materials after a date

### Known Limitations

1. **File Size**: Limited by Firebase Storage (currently no explicit limit in code)
2. **Concurrent Edits**: No conflict resolution for simultaneous edits
3. **Download Stats**: Tracks downloads but not actual file access time
4. **Search**: In-memory search only (not indexed)
5. **Batch Delete**: Must delete materials one at a time

## API Reference

### MaterialService API

```dart
// Create
MaterialService.createMaterial({
  required String courseId,
  required String title,
  required String description,
  required String instructorId,
  required String instructorName,
  List<PlatformFile>? files,
  List<LinkModel>? links,
}) -> Future<String>  // Returns material ID

// Update
MaterialService.updateMaterial({
  required MaterialModel material,
  List<PlatformFile>? newFiles,
  List<String>? filesToRemove,
}) -> Future<void>

// Delete
MaterialService.deleteMaterial(String materialId) -> Future<void>

// Retrieve
MaterialService.getMaterialsByCourse(String courseId)
  -> Future<List<MaterialModel>>

MaterialService.getMaterialById(String id)
  -> Future<MaterialModel?>

// Track
MaterialService.markMaterialAsViewed({
  required String materialId,
  required String userId,
}) -> Future<void>

MaterialService.trackDownload({
  required String materialId,
  required String fileId,
  required String userId,
}) -> Future<void>

MaterialService.getMaterialViewStats(String materialId)
  -> Future<Map<String, dynamic>>
```

### MaterialProvider API

```dart
// Load
MaterialProvider.loadMaterialsByCourse(String courseId) -> Future<void>
MaterialProvider.loadMaterialsForStudent({...}) -> Future<void>

// CRUD
MaterialProvider.createMaterial({...}) -> Future<String?>
MaterialProvider.updateMaterial({...}) -> Future<bool>
MaterialProvider.deleteMaterial(String id) -> Future<bool>

// Track
MaterialProvider.markAsViewed({...}) -> Future<void>
MaterialProvider.trackDownload({...}) -> Future<void>

// Utilities
MaterialProvider.searchMaterials(String query) -> void
MaterialProvider.clearSearch() -> void
MaterialProvider.refresh() -> Future<void>

// Getters
MaterialProvider.materials -> List<MaterialModel>
MaterialProvider.isLoading -> bool
MaterialProvider.error -> String?
```

## Troubleshooting

### Common Issues

**Issue**: Materials not showing up
- **Check**: Ensure MaterialProvider is registered in main.dart
- **Check**: Verify Firestore collection name is "materials"
- **Check**: Confirm user is enrolled in the course

**Issue**: Files not uploading
- **Check**: Firebase Storage rules allow writes
- **Check**: File size is reasonable
- **Check**: Internet connection is stable

**Issue**: Download tracking not working
- **Check**: User is authenticated
- **Check**: Firestore write permissions for materials collection
- **Check**: Check browser console for errors

**Issue**: Statistics not updating
- **Check**: Refresh the material details screen
- **Check**: Verify Firestore indexes are created
- **Check**: Check for permission errors in console

## Summary

The Material Service provides a complete, production-ready solution for managing course materials with:

✅ **Full CRUD operations** with file and link support
✅ **Automatic visibility** to all students in a course
✅ **Comprehensive tracking** of views and downloads
✅ **Offline caching** for improved performance
✅ **Clean architecture** following project patterns
✅ **Rich UI components** for instructors and students
✅ **Proper error handling** and validation
✅ **Firebase integration** for storage and database

The implementation follows all project requirements and integrates seamlessly with the existing codebase architecture.
