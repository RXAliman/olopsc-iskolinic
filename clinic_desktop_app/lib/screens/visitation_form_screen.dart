import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/symptoms.dart';
import '../providers/patient_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../theme/app_theme.dart';

import '../models/patient.dart';
import '../models/visitation.dart';
import 'patient_form_screen.dart';
import '../services/database_helper.dart';

class VisitationFormScreen extends StatefulWidget {
  final String? patientId;
  final Visitation? visitation;
  final bool hideChiefComplaintOptions;

  const VisitationFormScreen({
    super.key,
    this.patientId,
    this.visitation,
    this.hideChiefComplaintOptions = false,
  });

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
  bool _isLoadingPatient = false;

  bool _showAllTraumatic = true;
  bool _showAllMedical = true;
  bool _showAllBehavioral = true;
  bool _showAllSupplies = true;

  @override
  void initState() {
    super.initState();
    if (widget.hideChiefComplaintOptions) {
      _showAllTraumatic = false;
      _showAllMedical = false;
      _showAllBehavioral = false;
    }

    if (widget.visitation != null) {
      _treatmentCtrl.text = widget.visitation!.treatment;
      _remarksCtrl.text = widget.visitation!.remarks;
      _selectedSymptoms.addAll(widget.visitation!.symptoms);
      _selectedSupplies.addAll(widget.visitation!.suppliesUsed);
    }

    final pId = widget.visitation?.patientId ?? widget.patientId;
    if (pId != null) {
      final provider = context.read<PatientProvider>();
      if (provider.selectedPatient?.id == pId) {
        _selectedPatient = provider.selectedPatient;
      } else {
        try {
          _selectedPatient = provider.patients.firstWhere((p) => p.id == pId);
        } catch (_) {
          _isLoadingPatient = true;
          DatabaseHelper.instance.getPatient(pId).then((p) {
            if (mounted) {
              setState(() {
                _selectedPatient = p;
                _isLoadingPatient = false;
              });
            }
          });
        }
      }
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

    if (widget.visitation != null) {
      // Track which supplies are newly added (not in original visitation)
      final originalSupplies = widget.visitation!.suppliesUsed.toSet();
      final newlyAddedSupplies = _selectedSupplies.difference(originalSupplies);

      final updated = widget.visitation!.copyWith(
        symptoms: _selectedSymptoms.toList(),
        suppliesUsed: _selectedSupplies.toList(),
        treatment: _treatmentCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim(),
      );
      await context.read<PatientProvider>().updateVisitation(updated);

      // Deduct stock only for newly added supplies
      if (newlyAddedSupplies.isNotEmpty) {
        final inventoryProvider = context.read<InventoryProvider>();
        for (final supply in newlyAddedSupplies) {
          await inventoryProvider.deductStock(supply, 1);
        }
      }
    } else {
      await context.read<PatientProvider>().addVisitation(
        patientId: _selectedPatient!.id,
        symptoms: _selectedSymptoms.toList(),
        suppliesUsed: _selectedSupplies.toList(),
        treatment: _treatmentCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPatient) {
      return const Dialog(
        child: SizedBox(
          width: 600,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
                  widget.visitation != null
                      ? 'Edit Visitation'
                      : 'Record Visitation',
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
                        optionsBuilder: (textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Patient>.empty();
                          }
                          final query = textEditingValue.text;
                          return await DatabaseHelper.instance
                              .searchPatientsPaginated(
                                query,
                                10, // top 10 matches
                                0, // offset 0
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
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      readOnly: widget.patientId != null,
                                      decoration: const InputDecoration(
                                        labelText: 'Patient Name / ID Number *',
                                        prefixIcon: Icon(
                                          Icons.person_search_rounded,
                                        ),
                                      ),
                                      onEditingComplete: onEditingComplete,
                                    ),
                                  ),
                                  if (widget.patientId == null &&
                                      _selectedPatient == null) ...[
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final newPatient =
                                            await showDialog<Patient>(
                                              context: context,
                                              builder: (_) =>
                                                  const PatientFormScreen(),
                                            );
                                        if (newPatient != null && mounted) {
                                          setState(() {
                                            _selectedPatient = newPatient;
                                          });
                                          controller.text =
                                              newPatient.patientName;
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.person_add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Add Patient'),
                                    ),
                                  ],
                                ],
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 400,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return Builder(
                                      builder: (context) {
                                        final bool highlight =
                                            AutocompleteHighlightedOption.of(
                                              context,
                                            ) ==
                                            index;
                                        if (highlight) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (context.mounted) {
                                                  Scrollable.ensureVisible(
                                                    context,
                                                    alignment: 0.5,
                                                  );
                                                }
                                              });
                                        }
                                        return Container(
                                          color: highlight
                                              ? AppTheme.accent.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.transparent,
                                          child: ListTile(
                                            title: Text(option.patientName),
                                            subtitle: Text(option.idNumber),
                                            onTap: () => onSelected(option),
                                          ),
                                        );
                                      },
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
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        // Interventions
                        Text(
                          'Interventions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        Consumer<InventoryProvider>(
                          builder: (context, inventory, _) {
                            final allItems = inventory.items;
                            return _buildSection(
                              title: 'Clinic Supplies Used',
                              overrideItems: allItems,
                              selectedItems: _selectedSupplies,
                              showAll: _showAllSupplies,
                              onToggle: () => setState(
                                () => _showAllSupplies = !_showAllSupplies,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Note: Please manually verify the supply\'s physical expiration date before use.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Treatment
                        TextFormField(
                          controller: _treatmentCtrl,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Other Intervention Details',
                            prefixIcon: Icon(Icons.healing_outlined),
                            counterText: '',
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(150),
                          ],
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),

                        // Remarks
                        TextFormField(
                          controller: _remarksCtrl,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            prefixIcon: Icon(Icons.notes_outlined),
                            counterText: '',
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(150),
                          ],
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
    List<String> allItems = const [],
    List<InventoryItem>? overrideItems,
    required Set<String> selectedItems,
    required bool showAll,
    required VoidCallback onToggle,
    Color accentColor = AppTheme.accent,
  }) {
    // If overrideItems is provided, we're dealing with InventoryItems (supplies)
    final bool isSupplies = overrideItems != null;

    final displayItems = showAll
        ? (isSupplies ? overrideItems : allItems)
        : (isSupplies
              ? overrideItems
                    .where((item) => selectedItems.contains(item.itemName))
                    .toList()
              : allItems
                    .where((item) => selectedItems.contains(item))
                    .toList());

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
              final String name = isSupplies
                  ? (item as InventoryItem).itemName
                  : item as String;
              final isSelected = selectedItems.contains(name);
              final bool isOutOfStock =
                  isSupplies && (item as InventoryItem).quantity == 0;
              final bool isDisabled = isOutOfStock && !isSelected;

              Widget chipLabel = Text(
                isSupplies
                    ? '$name (${(item as InventoryItem).quantity})'
                    : name,
                style: TextStyle(
                  color: isDisabled
                      ? AppTheme.textMuted
                      : isSelected
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );

              Widget chip = FilterChip(
                showCheckmark: false,
                label: chipLabel,
                selected: isSelected,
                onSelected: isDisabled
                    ? null
                    : (sel) {
                        setState(() {
                          if (sel) {
                            selectedItems.add(name);
                          } else {
                            selectedItems.remove(name);
                          }
                        });
                      },
                selectedColor: accentColor,
                backgroundColor: isDisabled
                    ? AppTheme.cardLight.withValues(alpha: 0.5)
                    : AppTheme.cardLight,
                disabledColor: AppTheme.cardLight.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isDisabled
                      ? AppTheme.dividerColor.withValues(alpha: 0.5)
                      : isSelected
                      ? accentColor
                      : AppTheme.dividerColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );

              if (isSupplies && (item as InventoryItem).isLowStock) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    chip,
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          size: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return chip;
            }).toList(),
          ),
        ],
      ),
    );
  }
}
