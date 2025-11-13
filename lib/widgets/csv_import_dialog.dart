import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CsvImportDialog extends StatefulWidget {
  final String title;
  final List<String> headers;
  final List<Map<String, String>> data;
  final Map<String, String> Function(Map<String, String>) previewBuilder;
  final Future<Map<String, dynamic>> Function() onImport;

  const CsvImportDialog({
    super.key,
    required this.title,
    required this.headers,
    required this.data,
    required this.previewBuilder,
    required this.onImport,
  });

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  bool _isImporting = false;
  Map<String, dynamic>? _importResult;

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await widget.onImport();

      setState(() {
        _importResult = result;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _importResult = {
          'error': e.toString(),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_importResult != null) {
      return _buildResultDialog();
    }

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            Card(
              color: AppTheme.infoColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        '${widget.data.length} rows found in CSV file',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Preview header
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),

            // Preview list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.data.length > 10 ? 10 : widget.data.length,
                itemBuilder: (context, index) {
                  final row = widget.data[index];
                  final preview = widget.previewBuilder(row);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: preview.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingXS,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (widget.data.length > 10) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Showing first 10 of ${widget.data.length} rows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isImporting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isImporting ? null : _handleImport,
          child: _isImporting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Import ${widget.data.length} Rows'),
        ),
      ],
    );
  }

  Widget _buildResultDialog() {
    final result = _importResult!;
    final hasError = result.containsKey('error');
    final success = result['success'] ?? 0;
    final failed = result['failed'] ?? 0;
    final alreadyExists = result['alreadyExists'] ?? 0;
    final total = result['total'] ?? 0;
    final details = result['details'] as List<dynamic>?;

    // Get failed entries for error display
    final failedEntries = details?.where((d) =>
      d['status'] == 'failed' || d['status'] == 'exists'
    ).toList() ?? [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: hasError ? AppTheme.errorColor : AppTheme.successColor,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(hasError ? 'Import Failed' : 'Import Complete'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasError) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Text(
                  result['error'],
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ] else ...[
              _buildStatCard(
                icon: Icons.check_circle,
                label: 'Successfully imported',
                value: success.toString(),
                color: AppTheme.successColor,
              ),
              if (alreadyExists > 0) ...[
                const SizedBox(height: AppTheme.spacingS),
                _buildStatCard(
                  icon: Icons.info,
                  label: 'Already exists (skipped)',
                  value: alreadyExists.toString(),
                  color: AppTheme.warningColor,
                ),
              ],
              if (failed > 0) ...[
                const SizedBox(height: AppTheme.spacingS),
                _buildStatCard(
                  icon: Icons.error,
                  label: 'Failed',
                  value: failed.toString(),
                  color: AppTheme.errorColor,
                ),
              ],
              const SizedBox(height: AppTheme.spacingM),
              const Divider(),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total processed:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Show error details if there are any failures
              if (failedEntries.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                const Divider(),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Error Details:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: failedEntries.map((entry) {
                        final code = entry['code'] ?? '';
                        final name = entry['name'] ?? '';
                        final error = entry['error'] ?? '';
                        final status = entry['status'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: status == 'exists'
                              ? AppTheme.warningColor.withOpacity(0.1)
                              : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: status == 'exists'
                                ? AppTheme.warningColor
                                : AppTheme.errorColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$code - $name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                error,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: status == 'exists'
                                    ? AppTheme.warningColor
                                    : AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // Use microtask to defer the pop operation to the next event loop cycle
            // This avoids Navigator lock issues when dialog rebuilds
            Future.microtask(() {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop(_importResult);
              }
            });
          },
          child: const Text('Close'),
        ),
      ],
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
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
