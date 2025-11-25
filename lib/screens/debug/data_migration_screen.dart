import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../config/app_constants.dart';

/// Data Migration Screen
/// Fixes documents with empty 'id' fields by updating them with their Firestore document IDs
class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  bool _isRunning = false;
  final List<String> _logs = [];
  final Map<String, int> _stats = {
    'usersFixed': 0,
    'semestersFixed': 0,
    'coursesFixed': 0,
    'groupsFixed': 0,
    'announcementsFixed': 0,
    'totalFixed': 0,
  };

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} - $message');
    });
  }

  Future<void> _runMigration() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
      _stats.clear();
      _stats['usersFixed'] = 0;
      _stats['semestersFixed'] = 0;
      _stats['coursesFixed'] = 0;
      _stats['groupsFixed'] = 0;
      _stats['announcementsFixed'] = 0;
      _stats['totalFixed'] = 0;
    });

    try {
      final firestoreService = context.read<FirestoreService>();

      _addLog('🚀 Starting data migration...');
      _addLog('');

      // Migrate users (students, instructors, admin)
      _addLog('📋 Migrating users collection...');
      final usersFixed = await _migrateCollection(
        firestoreService,
        AppConstants.collectionUsers,
      );
      setState(() => _stats['usersFixed'] = usersFixed);
      _addLog('✅ Fixed $usersFixed users with empty id fields');
      _addLog('');

      // Migrate semesters
      _addLog('📋 Migrating semesters collection...');
      final semestersFixed = await _migrateCollection(
        firestoreService,
        AppConstants.collectionSemesters,
      );
      setState(() => _stats['semestersFixed'] = semestersFixed);
      _addLog('✅ Fixed $semestersFixed semesters with empty id fields');
      _addLog('');

      // Migrate courses
      _addLog('📋 Migrating courses collection...');
      final coursesFixed = await _migrateCollection(
        firestoreService,
        AppConstants.collectionCourses,
      );
      setState(() => _stats['coursesFixed'] = coursesFixed);
      _addLog('✅ Fixed $coursesFixed courses with empty id fields');
      _addLog('');

      // Migrate groups
      _addLog('📋 Migrating groups collection...');
      final groupsFixed = await _migrateCollection(
        firestoreService,
        AppConstants.collectionGroups,
      );
      setState(() => _stats['groupsFixed'] = groupsFixed);
      _addLog('✅ Fixed $groupsFixed groups with empty id fields');
      _addLog('');

      // Migrate announcements
      _addLog('📋 Migrating announcements collection...');
      final announcementsFixed = await _migrateCollection(
        firestoreService,
        AppConstants.collectionAnnouncements,
      );
      setState(() => _stats['announcementsFixed'] = announcementsFixed);
      _addLog('✅ Fixed $announcementsFixed announcements with empty id fields');
      _addLog('');

      final totalFixed = usersFixed +
          semestersFixed +
          coursesFixed +
          groupsFixed +
          announcementsFixed;
      setState(() => _stats['totalFixed'] = totalFixed);

      _addLog('');
      _addLog('🎉 Migration completed successfully!');
      _addLog('📊 Total documents fixed: $totalFixed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration completed! Fixed $totalFixed documents.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('');
      _addLog('❌ Error during migration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<int> _migrateCollection(
    FirestoreService firestoreService,
    String collection,
  ) async {
    int fixedCount = 0;

    try {
      // Get all documents in the collection
      final allDocs = await firestoreService.getAll(collection: collection);

      for (final doc in allDocs) {
        final docId = doc['id'] as String?;

        // Check if id field is empty or null
        if (docId == null || docId.isEmpty) {
          // This shouldn't happen with our getAll method, but let's check
          _addLog('⚠️  Found document with missing id in $collection');
          continue;
        }

        // The getAll method already injects the correct id, but we need to check
        // if the id field in Firestore is actually empty
        // We'll query for documents where id is empty or doesn't exist
      }

      // Query for documents with empty id field
      final docsWithEmptyId = await firestoreService.query(
        collection: collection,
        filters: [
          QueryFilter(field: 'id', isEqualTo: ''),
        ],
      );

      for (final doc in docsWithEmptyId) {
        final realDocId = doc['id'] as String; // This is injected by query method
        _addLog('  Fixing document $realDocId in $collection');

        await firestoreService.update(
          collection: collection,
          documentId: realDocId,
          data: {'id': realDocId},
        );

        fixedCount++;
      }
    } catch (e) {
      _addLog('⚠️  Error migrating $collection: $e');
      rethrow;
    }

    return fixedCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Migration Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This tool fixes documents that have empty "id" fields in Firestore. '
                          'This issue was caused by a bug in the FirestoreService that has now been fixed.\n\n'
                          'Run this migration ONCE to fix all existing data.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            if (_stats['totalFixed']! > 0) ...[
              const Text(
                'Migration Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatChip('Users', _stats['usersFixed']!),
                  _buildStatChip('Semesters', _stats['semestersFixed']!),
                  _buildStatChip('Courses', _stats['coursesFixed']!),
                  _buildStatChip('Groups', _stats['groupsFixed']!),
                  _buildStatChip('Announcements', _stats['announcementsFixed']!),
                  _buildStatChip(
                    'Total',
                    _stats['totalFixed']!,
                    isTotal: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Run Migration Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runMigration,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Running Migration...' : 'Run Migration'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logs Section
            if (_logs.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Migration Log',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color textColor = Colors.grey[300]!;

                      if (log.contains('✅')) {
                        textColor = Colors.green[300]!;
                      } else if (log.contains('❌') || log.contains('⚠️')) {
                        textColor = Colors.orange[300]!;
                      } else if (log.contains('🎉')) {
                        textColor = Colors.blue[300]!;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, {bool isTotal = false}) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: isTotal ? Colors.blue : Colors.green,
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(label),
      backgroundColor: isTotal ? Colors.blue[50] : Colors.green[50],
    );
  }
}
