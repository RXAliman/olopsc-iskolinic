import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/symptoms.dart';
import '../constants/supplies.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';

import '../models/patient.dart';
import 'patient_form_screen.dart';

class VisitationFormScreen extends StatefulWidget {
  final String? patientId;

  const VisitationFormScreen({super.key, this.patientId});

  @override
  State<VisitationFormScreen> createState() => _VisitationFormScreenState();
}

class _VisitationFormScreenState extends State<VisitationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _treatmentCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedSupplies = {};

  Patient? _selectedPatient;

  bool _showAllTraumatic = true;
  bool _showAllMedical = true;
  bool _showAllBehavioral = true;
  bool _showAllSupplies = true;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) {
      final provider = context.read<PatientProvider>();
      try {
        _selectedPatient = provider.patients.firstWhere(
          (p) => p.id == widget.patientId,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _treatmentCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
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
      patientId: _selectedPatient!.id,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Scrollable Form Area
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Patient Search (Autocomplete)
                      Autocomplete<Patient>(
                        initialValue: TextEditingValue(
                          text: _selectedPatient?.patientName ?? '',
                        ),
                        displayStringForOption: (option) => option.patientName,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Patient>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return context.read<PatientProvider>().patients.where(
                            (p) {
                              return p.patientName.toLowerCase().contains(
                                    query,
                                  ) ||
                                  p.idNumber.toLowerCase().contains(query);
                            },
                          );
                        },
                        onSelected: (selection) {
                          setState(() {
                            _selectedPatient = selection;
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              controller,
                              focusNode,
                              onEditingComplete,
                            ) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                readOnly: widget.patientId != null,
                                decoration: InputDecoration(
                                  labelText: 'Patient Name *',
                                  prefixIcon: const Icon(
                                    Icons.person_search_rounded,
                                  ),
                                  suffixIcon:
                                      widget.patientId == null &&
                                          _selectedPatient == null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.person_add_rounded,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  const PatientFormScreen(),
                                            );
                                          },
                                        )
                                      : null,
                                ),
                                onEditingComplete: onEditingComplete,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 400,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option.patientName),
                                      subtitle: Text(option.idNumber),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_selectedPatient != null) ...[
                        const SizedBox(height: 24),
                        // Symptoms label
                        Text(
                          'Chief Complaints / Symptoms *',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        // Symptom chips - Traumatic
                        _buildSection(
                          title: 'Traumatic',
                          allItems: kTraumaticSymptoms,
                          selectedItems: _selectedSymptoms,
                          showAll: _showAllTraumatic,
                          onToggle: () => setState(
                            () => _showAllTraumatic = !_showAllTraumatic,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Symptom chips - Medical
                        _buildSection(
                          title: 'Medical',
                          allItems: kMedicalSymptoms,
                          selectedItems: _selectedSymptoms,
                          showAll: _showAllMedical,
                          onToggle: () => setState(
                            () => _showAllMedical = !_showAllMedical,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Symptom chips - Behavioral
                        _buildSection(
                          title: 'Behavioral',
                          allItems: kBehavioralSymptoms,
                          selectedItems: _selectedSymptoms,
                          showAll: _showAllBehavioral,
                          onToggle: () => setState(
                            () => _showAllBehavioral = !_showAllBehavioral,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Supplies Used
                        Text(
                          'Supplies Used',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        _buildSection(
                          title: 'Clinic Supplies',
                          allItems: kSuppliesList,
                          selectedItems: _selectedSupplies,
                          showAll: _showAllSupplies,
                          onToggle: () => setState(
                            () => _showAllSupplies = !_showAllSupplies,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Treatment
                        TextFormField(
                          controller: _treatmentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Treatment / Medication',
                            prefixIcon: Icon(Icons.healing_outlined),
                            alignLabelWithHint: true,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),

                        // Remarks
                        TextFormField(
                          controller: _remarksCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            prefixIcon: Icon(Icons.notes_outlined),
                            alignLabelWithHint: true,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> allItems,
    required Set<String> selectedItems,
    required bool showAll,
    required VoidCallback onToggle,
    Color accentColor = AppTheme.accent,
  }) {
    final displayItems = showAll
        ? allItems
        : allItems.where((item) => selectedItems.contains(item)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppTheme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  showAll ? 'Hide Options' : 'Show Options',
                  style: TextStyle(fontSize: 12, color: accentColor),
                ),
              ),
            ],
          ),
          if (displayItems.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayItems.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                showCheckmark: false,
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
                      selectedItems.add(item);
                    } else {
                      selectedItems.remove(item);
                    }
                  });
                },
                selectedColor: accentColor,
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
        ],
      ),
    );
  }
}
