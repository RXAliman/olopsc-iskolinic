import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/symptoms.dart';
import '../providers/inventory_provider.dart';
import '../providers/custom_symptom_provider.dart';
import '../models/inventory_item.dart';
import '../theme/app_theme.dart';

import '../models/patient.dart';
import '../models/visitation.dart';
import '../providers/patient_provider.dart';
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
  final Set<String> _fullyConsumedSupplies = {};

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
      _fullyConsumedSupplies.addAll(widget.visitation!.consumedSupplies);
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

    final inventoryProvider = context.read<InventoryProvider>();

    // Transform selected supplies to ID:Name format for snapshotting
    final mappedSupplies = _selectedSupplies.map((supplyIdOrLegacy) {
      try {
        final item = inventoryProvider.items.firstWhere(
          (i) => i.id == supplyIdOrLegacy || i.itemName == supplyIdOrLegacy,
        );
        return "${item.id}:${item.itemName}";
      } catch (_) {
        return supplyIdOrLegacy;
      }
    }).toList();

    final consumedSupplies = mappedSupplies.where((supplyStr) {
      try {
        final idPart = supplyStr.contains(':')
            ? supplyStr.split(':')[0]
            : supplyStr;
        final item = inventoryProvider.items.firstWhere(
          (i) => i.id == idPart || i.itemName == idPart,
        );
        return item.itemType == 'piece' ||
            _fullyConsumedSupplies.contains(item.id) ||
            _fullyConsumedSupplies.contains(item.itemName);
      } catch (e) {
        return true; // Fallback context
      }
    }).toList();

    if (widget.visitation != null) {
      final originalConsumed = widget.visitation!.consumedSupplies.toSet();
      final newlyConsumed = consumedSupplies
          .where((s) => !originalConsumed.contains(s))
          .toList();

      final updated = widget.visitation!.copyWith(
        symptoms: _selectedSymptoms.toList(),
        suppliesUsed: mappedSupplies,
        consumedSupplies: consumedSupplies,
        treatment: _treatmentCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim(),
      );
      await context.read<PatientProvider>().updateVisitation(updated);

      // Deduct stock only for newly consumed supplies
      if (newlyConsumed.isNotEmpty) {
        for (final supplyStr in newlyConsumed) {
          // Resolve ID if it's in ID:Name format or legacy name
          final idPart = supplyStr.contains(':')
              ? supplyStr.split(':')[0]
              : supplyStr;
          try {
            final item = inventoryProvider.items.firstWhere(
              (i) => i.id == idPart || i.itemName == idPart,
            );
            await inventoryProvider.deductStock(item.id, 1);
          } catch (_) {
            // Item not found or deleted
          }
        }
      }
    } else {
      await context.read<PatientProvider>().addVisitation(
        patientId: _selectedPatient!.id,
        symptoms: _selectedSymptoms.toList(),
        suppliesUsed: mappedSupplies,
        consumedSupplies: consumedSupplies,
        treatment: _treatmentCtrl.text.trim(),
        remarks: _remarksCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showAddCustomSymptomDialog(String category) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Custom ${category[0].toUpperCase()}${category.substring(1)} Symptom',
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Symptom Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                context.read<CustomSymptomProvider>().addCustomSymptom(
                  name,
                  category,
                );
                setState(() {
                  _selectedSymptoms.add(name);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
                        Consumer<CustomSymptomProvider>(
                          builder: (context, customSymptomProvider, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Symptom chips - Traumatic
                                _buildSection(
                                  title: 'Traumatic',
                                  allItems: [
                                    ...kTraumaticSymptoms,
                                    ...customSymptomProvider.traumaticSymptoms
                                        .map((e) => e.name),
                                  ],
                                  selectedItems: _selectedSymptoms,
                                  showAll: _showAllTraumatic,
                                  onAddCustom: () =>
                                      _showAddCustomSymptomDialog('traumatic'),
                                  onToggle: () => setState(
                                    () =>
                                        _showAllTraumatic = !_showAllTraumatic,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Symptom chips - Medical
                                _buildSection(
                                  title: 'Medical',
                                  allItems: [
                                    ...kMedicalSymptoms,
                                    ...customSymptomProvider.medicalSymptoms
                                        .map((e) => e.name),
                                  ],
                                  selectedItems: _selectedSymptoms,
                                  showAll: _showAllMedical,
                                  onAddCustom: () =>
                                      _showAddCustomSymptomDialog('medical'),
                                  onToggle: () => setState(
                                    () => _showAllMedical = !_showAllMedical,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Symptom chips - Behavioral
                                _buildSection(
                                  title: 'Behavioral',
                                  allItems: [
                                    ...kBehavioralSymptoms,
                                    ...customSymptomProvider.behavioralSymptoms
                                        .map((e) => e.name),
                                  ],
                                  selectedItems: _selectedSymptoms,
                                  showAll: _showAllBehavioral,
                                  onAddCustom: () =>
                                      _showAddCustomSymptomDialog('behavioral'),
                                  onToggle: () => setState(
                                    () => _showAllBehavioral =
                                        !_showAllBehavioral,
                                  ),
                                ),
                              ],
                            );
                          },
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      'Sent home',
                                      'Rested in clinic',
                                      'Given medication',
                                      'Wound cleaned and dressed',
                                      'Referred to hospital',
                                      'Observation',
                                    ]
                                    .map(
                                      (text) => ActionChip(
                                        label: Text(
                                          text,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: AppTheme.accent
                                            .withValues(alpha: 0.1),
                                        padding: const EdgeInsets.all(4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.accent,
                                          ),
                                        ),
                                        onPressed: () {
                                          final ctrl = _treatmentCtrl;
                                          final currentText = ctrl.text;
                                          if (currentText.isEmpty) {
                                            ctrl.text = text;
                                          } else {
                                            ctrl.text = '$currentText, $text';
                                          }
                                          ctrl.selection =
                                              TextSelection.collapsed(
                                                offset: ctrl.text.length,
                                              );
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),

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
    VoidCallback? onAddCustom,
    Color accentColor = AppTheme.accent,
  }) {
    // If overrideItems is provided, we're dealing with InventoryItems (supplies)
    final bool isSupplies = overrideItems != null;

    final displayItems = showAll
        ? (isSupplies ? List.from(overrideItems) : List.from(allItems))
        : (isSupplies
              ? overrideItems
                    .where((item) => selectedItems.contains(item.id))
                    .toList()
              : allItems
                    .where((item) => selectedItems.contains(item))
                    .toList());

    // Sort non-supply items alphabetically
    if (!isSupplies) {
      displayItems.sort(
        (a, b) =>
            (a as String).toLowerCase().compareTo((b as String).toLowerCase()),
      );
    }

    Map<String, List<InventoryItem>> groups = {};
    if (isSupplies) {
      for (final item in displayItems) {
        final invItem = item as InventoryItem;
        final c = invItem.clinic.isEmpty ? 'Other' : invItem.clinic;
        groups.putIfAbsent(c, () => []).add(invItem);
      }
      // Sort items within each clinic group alphabetically
      for (final groupItems in groups.values) {
        groupItems.sort(
          (a, b) =>
              a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
        );
      }
    }

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
          if (displayItems.isNotEmpty || onAddCustom != null)
            const SizedBox(height: 12),
          if (isSupplies)
            ...groups.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value
                        .map(
                          (item) => _buildItemChip(
                            item: item,
                            isSupplies: true,
                            selectedItems: selectedItems,
                            accentColor: accentColor,
                          ),
                        )
                        .toList(),
                  ),
                  if (entry.key != groups.keys.last) const SizedBox(height: 12),
                ],
              );
            })
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayItems.map(
                  (item) => _buildItemChip(
                    item: item,
                    isSupplies: false,
                    selectedItems: selectedItems,
                    accentColor: accentColor,
                  ),
                ),
                if (showAll && onAddCustom != null)
                  ActionChip(
                    label: const Text('Add', style: TextStyle(fontSize: 13)),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: onAddCustom,
                    backgroundColor: AppTheme.cardLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: AppTheme.dividerColor),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItemChip({
    required dynamic item,
    required bool isSupplies,
    required Set<String> selectedItems,
    required Color accentColor,
  }) {
    final String name = isSupplies
        ? (item as InventoryItem).itemName
        : item as String;
    final String id = isSupplies ? (item as InventoryItem).id : name;
    final isSelected =
        selectedItems.contains(id) || selectedItems.contains(name);
    final bool isOutOfStock =
        isSupplies && (item as InventoryItem).quantity == 0;
    final bool isDisabled = isOutOfStock && !isSelected;

    Widget chipLabel = Text(
      isSupplies ? '$name (${(item as InventoryItem).quantity})' : name,
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
                  selectedItems.add(id);
                } else {
                  selectedItems.remove(id);
                  selectedItems.remove(name); // Legacy cleanup
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    if (isSupplies && (item as InventoryItem).isLowStock) {
      chip = Stack(
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

    // Multi-use item types that need a "fully consumed?" checkbox
    const multiUseTypes = {'bottle', 'roll', 'box', 'pack', 'pair', 'set'};

    if (isSupplies &&
        isSelected &&
        multiUseTypes.contains((item as InventoryItem).itemType)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip,
          const SizedBox(width: 4),
          Container(
            height: 32,
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value:
                      _fullyConsumedSupplies.contains(id) ||
                      _fullyConsumedSupplies.contains(name),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _fullyConsumedSupplies.add(id);
                      } else {
                        _fullyConsumedSupplies.remove(id);
                        _fullyConsumedSupplies.remove(name); // Legacy cleanup
                      }
                    });
                  },
                  activeColor: AppTheme.danger,
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Fully consumed?', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }

    return chip;
  }
}
