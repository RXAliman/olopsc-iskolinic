import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/symptom_tracking_provider.dart';
import '../theme/app_theme.dart';

class SymptomTrackingScreen extends StatelessWidget {
  const SymptomTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracking'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<SymptomTrackingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.visitations.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.visitations.length,
            itemBuilder: (context, index) {
              final visit = provider.visitations[index];
              final hasFollowUp = visit.followUpDate != null;
              final followUpPending = hasFollowUp && !visit.followUpCompleted;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: followUpPending
                      ? AppTheme.warning.withValues(alpha: 0.06)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: followUpPending
                        ? AppTheme.warning.withValues(alpha: 0.3)
                        : AppTheme.dividerColor,
                    width: followUpPending ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: followUpPending
                                ? AppTheme.warning.withValues(alpha: 0.2)
                                : AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            followUpPending
                                ? Icons.schedule_rounded
                                : Icons.check_circle_outline_rounded,
                            color: followUpPending
                                ? AppTheme.warning
                                : AppTheme.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinic Visit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy – hh:mm a',
                                ).format(visit.dateTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasFollowUp)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: visit.followUpCompleted
                                  ? AppTheme.accent.withValues(alpha: 0.15)
                                  : AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              visit.followUpCompleted
                                  ? 'COMPLETED'
                                  : 'FOLLOW-UP',
                              style: TextStyle(
                                color: visit.followUpCompleted
                                    ? AppTheme.accent
                                    : AppTheme.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Symptoms
                    if (visit.symptoms.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: visit.symptoms
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Treatment
                    if (visit.treatment.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.medical_services_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visit.treatment,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Remarks
                    if (visit.remarks.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visit.remarks,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Follow-up section
                    if (hasFollowUp) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Follow-up: ${DateFormat('MMM dd, yyyy').format(visit.followUpDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (visit.followUpCompleted &&
                          visit.followUpNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Notes: ${visit.followUpNotes}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentDim,
                            ),
                          ),
                        ),
                      ],
                      if (followUpPending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showFollowUpDialog(
                              context,
                              provider,
                              visit.id,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Complete Follow-up'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          );
        },
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
              Icons.monitor_heart_rounded,
              size: 40,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Clinic Visits',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your clinic visit history will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use "Simulate Clinic Visit" on the Home tab to test',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showFollowUpDialog(
    BuildContext context,
    SymptomTrackingProvider provider,
    String visitId,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Follow-up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How are you feeling? Add notes about your recovery.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Follow-up Notes',
                hintText: 'e.g., "Feeling much better, no more headache."',
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
              provider.completeFollowUp(
                visitId,
                notes: notesController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
