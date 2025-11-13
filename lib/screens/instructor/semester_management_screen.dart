import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/semester_model.dart';
import '../../providers/semester_provider.dart';
import '../../services/csv_service.dart';
import '../../widgets/semester_form_dialog.dart';
import '../../widgets/csv_import_dialog.dart';

class SemesterManagementScreen extends StatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  State<SemesterManagementScreen> createState() =>
      _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SemesterProvider>().loadSemesters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const SemesterFormDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.successCreate),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _showEditDialog(SemesterModel semester) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SemesterFormDialog(semester: semester),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.successUpdate),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _confirmDelete(SemesterModel semester) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text(
          'Are you sure you want to delete "${semester.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SemesterProvider>();
      final success = await provider.deleteSemester(semester.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successDelete),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to delete semester'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showImportDialog() async {
    final csvService = CsvService();

    try {
      // Pick and parse CSV file
      final data = await csvService.pickAndParseCsv(
        expectedHeaders: AppConstants.csvHeadersSemesters,
      );

      if (!mounted) return;

      // Show preview dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CsvImportDialog(
          title: 'Import Semesters',
          headers: AppConstants.csvHeadersSemesters,
          data: data,
          previewBuilder: (row) => {
            'Code': row['code'] ?? '',
            'Name': row['name'] ?? '',
          },
          onImport: () async {
            final provider = context.read<SemesterProvider>();
            return await provider.importFromCSV(data);
          },
        ),
      );

      // CsvImportDialog already shows the results, no need for another snackbar
      // The result map contains: {'success': n, 'failed': m, 'alreadyExists': k, ...}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _exportToCsv() {
    final provider = context.read<SemesterProvider>();
    final csvService = CsvService();

    final headers = AppConstants.csvHeadersSemesters;
    final rows = provider.semesters
        .map((s) => [s.code, s.name])
        .toList();

    final csvString = csvService.exportToCsvString(
      headers: headers,
      rows: rows,
    );

    // For web, download file
    // For mobile, show share dialog
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.successExport),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Show exported file
            print(csvString);
          },
        ),
      ),
    );
  }

  void _downloadTemplate() {
    final csvService = CsvService();
    final template = csvService.getSemesterCsvTemplate();

    // For web, download file
    // For mobile, show share dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV template downloaded'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            print(template);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Management'),
        actions: [
          // Download template
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTemplate,
            tooltip: 'Download CSV Template',
          ),
          // Import CSV
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showImportDialog,
            tooltip: 'Import from CSV',
          ),
          // Export CSV
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCsv,
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search semesters...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SemesterProvider>().clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<SemesterProvider>().searchSemesters(value);
              },
            ),
          ),

          // Semesters list
          Expanded(
            child: Consumer<SemesterProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Error loading semesters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          provider.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadSemesters(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!provider.hasSemesters) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: AppTheme.textDisabledColor,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No semesters yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          'Create your first semester or import from CSV',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textDisabledColor,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                final semesters = provider.semesters;

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final semester = semesters[index];
                      return _buildSemesterCard(semester);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Semester'),
      ),
    );
  }

  Widget _buildSemesterCard(SemesterModel semester) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: CircleAvatar(
          backgroundColor: semester.isCurrent
              ? AppTheme.successColor
              : AppTheme.primaryColor,
          child: Icon(
            semester.isCurrent ? Icons.check : Icons.calendar_today,
            color: AppTheme.textOnPrimaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                semester.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (semester.isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Text(
                  'CURRENT',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingXS),
            Text('Code: ${semester.code}'),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              'Created: ${_formatDate(semester.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(semester);
                break;
              case 'mark_current':
                context.read<SemesterProvider>().markAsCurrent(semester.id);
                break;
              case 'delete':
                _confirmDelete(semester);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: AppTheme.spacingS),
                  Text('Edit'),
                ],
              ),
            ),
            if (!semester.isCurrent)
              const PopupMenuItem(
                value: 'mark_current',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: AppTheme.spacingS),
                    Text('Mark as Current'),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: AppTheme.spacingS),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
