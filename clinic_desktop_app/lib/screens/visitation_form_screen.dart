import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/symptoms.dart';
import '../constants/supplies.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';

class VisitationFormScreen extends StatefulWidget {
  final String patientId;

  const VisitationFormScreen({super.key, required this.patientId});

  @override
  State<VisitationFormScreen> createState() => _VisitationFormScreenState();
}

class _VisitationFormScreenState extends State<VisitationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _treatmentCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedSupplies = {};

  @override
  void dispose() {
    _treatmentCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    await context.read<PatientProvider>().addVisitation(
      patientId: widget.patientId,
      symptoms: _selectedSymptoms.toList(),
      suppliesUsed: _selectedSupplies.toList(),
      treatment: _treatmentCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Record Visitation',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Symptoms label
                Text(
                  'Chief Complaints / Symptoms *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Symptom chips
                _buildChipSelector(
                  items: kSymptomsList,
                  selected: _selectedSymptoms,
                ),
                const SizedBox(height: 24),

                // Supplies label
                Text(
                  'Supplies Used',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Supply chips
                _buildChipSelector(
                  items: kSuppliesList,
                  selected: _selectedSupplies,
                  accentColor: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 20),

                // Treatment
                TextFormField(
                  controller: _treatmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Treatment / Medication',
                    prefixIcon: Icon(Icons.healing_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Remarks
                TextFormField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Visit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required Set<String> selected,
    Color accentColor = AppTheme.accent,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selected.contains(item);
            return FilterChip(
              label: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    selected.add(item);
                  } else {
                    selected.remove(item);
                  }
                });
              },
              selectedColor: accentColor,
              checkmarkColor: Colors.white,
              backgroundColor: AppTheme.cardLight,
              side: BorderSide(
                color: isSelected ? accentColor : AppTheme.dividerColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
