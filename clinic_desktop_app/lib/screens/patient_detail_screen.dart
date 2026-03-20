import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';
import 'visitation_form_screen.dart';
import 'patient_form_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        final patient = provider.selectedPatient;
        if (patient == null) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No patient selected'),
            ),
          );
        }

        return Dialog(
          child: Container(
            width: 950,
            height: 640,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          patient.firstName.isNotEmpty
                              ? patient.firstName[0].toUpperCase()
                              : (patient.patientName.isNotEmpty
                                    ? patient.patientName[0].toUpperCase()
                                    : '?'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.patientName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            patient.idNumber,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Left Column: Patient Info ---
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassCard(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoCell(
                                    icon: Icons.home_outlined,
                                    label: 'Address',
                                    value: patient.address.isNotEmpty
                                        ? patient.address
                                        : '—',
                                  ),
                                  const SizedBox(height: 16),
                                  _InfoCell(
                                    icon: Icons.family_restroom_outlined,
                                    label: 'Guardian',
                                    value: patient.guardianName.isNotEmpty
                                        ? patient.guardianName
                                        : '—',
                                  ),
                                  const SizedBox(height: 16),
                                  _InfoCell(
                                    icon: Icons.phone_outlined,
                                    label: 'Contact',
                                    value: patient.guardianContact.isNotEmpty
                                        ? patient.guardianContact
                                        : '—',
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => PatientFormScreen(
                                              patient: patient,
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.accent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: const BorderSide(
                                              color: AppTheme.accent,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppTheme.accent,
                                        ),
                                        label: const Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: AppTheme.accent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete Patient',
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete ${patient.patientName}? This will also delete all visitation records.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppTheme.danger,
                                                      ),
                                                  onPressed: () {
                                                    context
                                                        .read<PatientProvider>()
                                                        .deletePatient(
                                                          patient.id,
                                                        );
                                                    Navigator.pop(
                                                      ctx,
                                                    ); // close dialog
                                                    Navigator.pop(
                                                      context,
                                                    ); // close details screen
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.danger,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: const BorderSide(
                                              color: AppTheme.danger,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppTheme.danger,
                                        ),
                                        label: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppTheme.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppTheme.dividerColor,
                        ),
                      ),

                      // --- Right Column: Visitation History ---
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Visitation Header
                            Row(
                              children: [
                                Text(
                                  'Visitation History',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => VisitationFormScreen(
                                        patientId: patient.id,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Visit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Visitation List
                            Expanded(
                              child: provider.visitations.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.medical_services_outlined,
                                            size: 48,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No visits recorded',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: provider.visitations.length,
                                      itemBuilder: (context, index) {
                                        final visit =
                                            provider.visitations[index];
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: AppTheme.glassCard(),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 14,
                                                    color: AppTheme.accent,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    DateFormat(
                                                      'MMM dd, yyyy – hh:mm a',
                                                    ).format(visit.dateTime),
                                                    style: const TextStyle(
                                                      color: AppTheme.accent,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              // Symptoms chips
                                              if (visit.symptoms.isNotEmpty)
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: visit.symptoms
                                                      .map(
                                                        (s) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme
                                                                .accent
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            s,
                                                            style: const TextStyle(
                                                              color: AppTheme
                                                                  .accentLight,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              if (visit
                                                  .treatment
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Treatment: ',
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme.textMuted,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        visit.treatment,
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .textPrimary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (visit.remarks.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Remarks: ',
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme.textMuted,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        visit.remarks,
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .textPrimary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            if (provider.visitations.isNotEmpty &&
                                provider.totalVisitPages > 1)
                              _buildPagination(
                                provider,
                                provider.totalVisitations,
                                provider.totalVisitPages,
                                provider.currentVisitPage *
                                    provider.visitPageSize,
                                (provider.currentVisitPage *
                                        provider.visitPageSize) +
                                    provider.visitations.length,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(
    PatientProvider provider,
    int totalItems,
    int totalPages,
    int start,
    int end,
  ) {
    final currentPage = provider.currentVisitPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.glassCard(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${start + 1}–$end of $totalItems visits',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => provider.firstVisitPage()
                    : null,
                icon: const Icon(Icons.first_page_rounded, size: 20),
                tooltip: 'First page',
                splashRadius: 18,
              ),
              IconButton(
                onPressed: currentPage > 0
                    ? () => provider.prevVisitPage()
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Previous',
                splashRadius: 18,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(provider, totalPages),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => provider.nextVisitPage()
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Next',
                splashRadius: 18,
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => provider.lastVisitPage()
                    : null,
                icon: const Icon(Icons.last_page_rounded, size: 20),
                tooltip: 'Last page',
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(PatientProvider provider, int totalPages) {
    final current = provider.currentVisitPage;
    return [
      Container(
        width: 64,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${current + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    ];
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
