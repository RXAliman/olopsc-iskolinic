import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patients',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.totalPatients} total patients',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPatientForm(context),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Patient'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              SizedBox(
                width: 400,
                child: TextField(
                  onChanged: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by name or student number...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => provider.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Patient Table
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.patients.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPatientTable(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new patient to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTable(BuildContext context, PatientProvider provider) {
    return Container(
      decoration: AppTheme.glassCard(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: provider.patients.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.dividerColor),
          itemBuilder: (context, index) {
            final patient = provider.patients[index];
            return _PatientTile(
              patient: patient,
              onTap: () => _openPatientDetail(context, patient),
              onEdit: () => _showPatientForm(context, patient: patient),
              onDelete: () => _confirmDelete(context, patient),
            );
          },
        ),
      ),
    );
  }

  void _showPatientForm(BuildContext context, {Patient? patient}) {
    showDialog(
      context: context,
      builder: (_) => PatientFormScreen(patient: patient),
    );
  }

  void _openPatientDetail(BuildContext context, Patient patient) async {
    final provider = context.read<PatientProvider>();
    await provider.selectPatient(patient);
    if (context.mounted) {
      showDialog(context: context, builder: (_) => const PatientDetailScreen());
    }
  }

  void _confirmDelete(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${patient.studentName}? This will also delete all visitation records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<PatientProvider>().deletePatient(patient.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientTile({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PatientTile> createState() => _PatientTileState();
}

class _PatientTileState extends State<_PatientTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isHovered
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.patient.studentName.isNotEmpty
                          ? widget.patient.studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.studentName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.patient.studentNumber,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Guardian
                SizedBox(
                  width: 180,
                  child: Text(
                    widget.patient.guardianName.isNotEmpty
                        ? widget.patient.guardianName
                        : '—',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Actions
                if (_isHovered) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: AppTheme.accent,
                    ),
                    onPressed: widget.onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppTheme.danger,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
