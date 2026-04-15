import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/medical_provider.dart';
import '../theme/app_theme.dart';
import 'upload_medical_data_screen.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<MedicalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.records.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.records.length,
            itemBuilder: (context, index) {
              final record = provider.records[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.glassCard(),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      record.filePath.isNotEmpty
                          ? Icons.insert_drive_file_rounded
                          : Icons.description_rounded,
                      color: AppTheme.accent,
                    ),
                  ),
                  title: Text(
                    record.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (record.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(record.uploadedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: record.parentAcknowledged
                                  ? AppTheme.accent.withValues(alpha: 0.15)
                                  : AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.parentAcknowledged
                                  ? '✓ Acknowledged'
                                  : 'Pending',
                              style: TextStyle(
                                color: record.parentAcknowledged
                                    ? AppTheme.accent
                                    : AppTheme.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (record.parentNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.comment_rounded,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Parent: ${record.parentNotes}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'acknowledge') {
                        _showAcknowledgeDialog(context, provider, record.id);
                      } else if (value == 'delete') {
                        provider.deleteRecord(record.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (!record.parentAcknowledged)
                        const PopupMenuItem(
                          value: 'acknowledge',
                          child: Text('Simulate Parent Ack.'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (user == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadMedicalDataScreen(studentId: user.id),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.medical_information_rounded,
              size: 40,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Medical Records',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your medical data by tapping +',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showAcknowledgeDialog(
    BuildContext context,
    MedicalProvider provider,
    String recordId,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Parent Acknowledgement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Simulate parent/guardian acknowledgement with notes.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Parent Notes (optional)',
                hintText: 'e.g., "Noted. Please take medicine on time."',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.acknowledgeRecord(
                recordId,
                notes: notesController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}
