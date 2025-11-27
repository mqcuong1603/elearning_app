import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/material_model.dart';
import '../../providers/material_provider.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/material_form_dialog.dart';

/// Material Details Screen
/// Shows detailed view of a material with files, links, and tracking
class MaterialDetailsScreen extends StatefulWidget {
  final MaterialModel material;

  const MaterialDetailsScreen({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailsScreen> createState() => _MaterialDetailsScreenState();
}

class _MaterialDetailsScreenState extends State<MaterialDetailsScreen> {
  late MaterialModel _material;
  Map<String, dynamic>? _viewStats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _material = widget.material;
    // Defer to avoid notifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsViewed();
      _loadStats();
    });
  }

  Future<void> _markAsViewed() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final materialProvider =
          Provider.of<MaterialProvider>(context, listen: false);
      await materialProvider.markAsViewed(
        materialId: _material.id,
        userId: user.id,
      );
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    final materialProvider =
        Provider.of<MaterialProvider>(context, listen: false);
    final stats =
        await materialProvider.getMaterialViewStats(_material.id);

    if (mounted) {
      setState(() {
        _viewStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _downloadFile(String fileId, String fileUrl, String fileName) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final materialProvider =
          Provider.of<MaterialProvider>(context, listen: false);

      // Track download
      if (authService.currentUser != null) {
        await materialProvider.trackDownload(
          materialId: _material.id,
          fileId: fileId,
          userId: authService.currentUser!.id,
        );
      }

      // Open/download file using URL launcher
      final uri = Uri.parse(fileUrl);
      // Try launching directly - canLaunchUrl can be unreliable on Android
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (mounted) {
        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening: $fileName')),
          );
        } else {
          throw 'Could not open $fileName. Please check your browser or file viewer is installed.';
        }
      }

      // Reload stats
      await _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      // Try launching directly - canLaunchUrl can be unreliable on Android
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw 'Could not launch $url. Please check your browser is installed.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editMaterial() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MaterialFormDialog(
        material: _material,
        courseId: _material.courseId,
      ),
    );

    if (result != null && mounted) {
      final materialProvider =
          Provider.of<MaterialProvider>(context, listen: false);

      final updatedMaterial = _material.copyWith(
        title: result['title'] as String,
        description: result['description'] as String,
        links: result['links'] as List<LinkModel>,
        updatedAt: DateTime.now(),
      );

      final success = await materialProvider.updateMaterial(
        material: updatedMaterial,
        newFiles: result['newFiles'],
        filesToRemove: result['filesToRemove'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material updated successfully')),
        );

        // Refresh material data
        final refreshedMaterial =
            await materialProvider.getMaterialById(_material.id);
        if (refreshedMaterial != null) {
          setState(() {
            _material = refreshedMaterial;
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update material'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMaterial() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text(
          'Are you sure you want to delete this material? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final materialProvider =
          Provider.of<MaterialProvider>(context, listen: false);

      final success = await materialProvider.deleteMaterial(_material.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted successfully')),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete material'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isInstructor = user?.role == AppConstants.roleInstructor;
    final isOwner = user?.id == _material.instructorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Details'),
        actions: [
          if (isInstructor && isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editMaterial,
              tooltip: 'Edit Material',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMaterial,
              tooltip: 'Delete Material',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material header
              _buildHeader(),
              const SizedBox(height: AppTheme.spacingL),

              // Description
              _buildDescription(),
              const SizedBox(height: AppTheme.spacingL),

              // Files section
              if (_material.hasFiles) ...[
                _buildFilesSection(),
                const SizedBox(height: AppTheme.spacingL),
              ],

              // Links section
              if (_material.hasLinks) ...[
                _buildLinksSection(),
                const SizedBox(height: AppTheme.spacingL),
              ],

              // Stats section (for instructors)
              if (isInstructor && isOwner) ...[
                _buildStatsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _material.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),

            // Instructor and date info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _material.instructorName,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat.yMMMd().format(_material.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Content info
            Row(
              children: [
                if (_material.hasFiles) ...[
                  Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text('${_material.files.length} file(s)'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_material.hasLinks) ...[
                  Chip(
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text('${_material.links.length} link(s)'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _material.description,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ..._material.files.map((file) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                  title: Text(file.filename),
                  subtitle: Text(file.formattedSize),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadFile(file.id, file.url, file.filename),
                    tooltip: 'Download',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Links',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ..._material.links.map((link) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.orange),
                  title: Text(link.title),
                  subtitle: Text(
                    link.url,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openLink(link.url),
                    tooltip: 'Open',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingM),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_viewStats == null) {
      return const SizedBox.shrink();
    }

    final viewCount = _viewStats!['viewCount'] as int;
    final downloadCount = _viewStats!['downloadCount'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.visibility,
                    label: 'Views',
                    value: viewCount.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.download,
                    label: 'Downloads',
                    value: downloadCount.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
