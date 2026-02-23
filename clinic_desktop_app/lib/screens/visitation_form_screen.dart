import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/symptoms.dart';
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
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kSymptomsList.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return FilterChip(
                        label: Text(
                          symptom,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        selectedColor: AppTheme.accent,
                        checkmarkColor: Colors.white,
                        backgroundColor: AppTheme.cardLight,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.dividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
    );
  }
}
