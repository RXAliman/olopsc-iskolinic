import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../formatters/uppercase_text.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient;
  final int initialTabIndex;

  const PatientFormScreen({super.key, this.patient, this.initialTabIndex = 0});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _customExtensionCtrl;
  String _selectedExtension = 'None';
  late TextEditingController _numberCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _guardianNameCtrl;
  late TextEditingController _guardianContactCtrl;

  DateTime? _selectedBirthdate;
  String _selectedSex = 'Female';
  late TextEditingController _customSexCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _guardian2NameCtrl;
  late TextEditingController _guardian2ContactCtrl;
  late TextEditingController _allergicToCtrl;
  late TextEditingController _patientRemarksCtrl;

  bool get isEditing => widget.patient != null;

  final List<String> _presetDiseases = [
    'Chicken Pox',
    'Dengue',
    'Diphtheria',
    'German Measles',
    'Hepatitis',
    'Measles',
    'Mumps',
    'Primary Complex',
    'Typhoid Fever',
    'Whooping Cough',
    'Asthma',
    'Diabetes',
    'Ear Disorder',
    'Epilepsy',
    'Eye Disorder',
    'Heart Disease',
    'Kidney Disease',
    'Tuberculosis',
    'G6PD',
  ];

  late List<Map<String, dynamic>> _pastMedicalHistory;
  late List<Map<String, dynamic>> _vaccinationHistory;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(
      text: widget.patient?.firstName ?? '',
    );
    _lastNameCtrl = TextEditingController(text: widget.patient?.lastName ?? '');
    _middleNameCtrl = TextEditingController(
      text: widget.patient?.middleName ?? '',
    );

    final ext = widget.patient?.extension ?? '';
    if (ext.isEmpty || ext == 'None') {
      _selectedExtension = 'None';
      _customExtensionCtrl = TextEditingController();
    } else if (['Jr.', 'Sr.', 'I', 'II', 'III'].contains(ext)) {
      _selectedExtension = ext;
      _customExtensionCtrl = TextEditingController();
    } else {
      _selectedExtension = 'Others';
      _customExtensionCtrl = TextEditingController(text: ext);
    }
    _numberCtrl = TextEditingController(text: widget.patient?.idNumber ?? '');
    _addressCtrl = TextEditingController(text: widget.patient?.address ?? '');
    _guardianNameCtrl = TextEditingController(
      text: widget.patient?.guardianName ?? '',
    );
    _guardianContactCtrl = TextEditingController(
      text: widget.patient?.guardianContact ?? '',
    );
    _selectedBirthdate = widget.patient?.birthdate;
    final sex = widget.patient?.sex ?? '';
    if (sex.isEmpty) {
      _selectedSex = 'Female';
      _customSexCtrl = TextEditingController();
    } else if (['Male', 'Female'].contains(sex)) {
      _selectedSex = sex;
      _customSexCtrl = TextEditingController();
    } else {
      _selectedSex = 'Others';
      _customSexCtrl = TextEditingController(text: sex);
    }
    _contactCtrl = TextEditingController(
      text: widget.patient?.contactNumber ?? '',
    );
    _guardian2NameCtrl = TextEditingController(
      text: widget.patient?.guardian2Name ?? '',
    );
    _guardian2ContactCtrl = TextEditingController(
      text: widget.patient?.guardian2Contact ?? '',
    );
    _allergicToCtrl = TextEditingController(
      text: widget.patient?.allergicTo ?? '',
    );
    _patientRemarksCtrl = TextEditingController(
      text: widget.patient?.patientRemarks ?? '',
    );

    // Initialize Medical History
    _pastMedicalHistory = [];
    final existingMedical = widget.patient?.pastMedicalHistory ?? [];
    final existingMap = {
      for (var item in existingMedical) item['disease'] as String: item,
    };

    for (final disease in _presetDiseases) {
      if (existingMap.containsKey(disease)) {
        _pastMedicalHistory.add(
          Map<String, dynamic>.from(existingMap[disease]!),
        );
        existingMap.remove(disease);
      } else {
        _pastMedicalHistory.add({
          'disease': disease,
          'past': false,
          'present': false,
        });
      }
    }
    for (final customDisease in existingMap.values) {
      _pastMedicalHistory.add(Map<String, dynamic>.from(customDisease));
    }

    _vaccinationHistory =
        widget.patient?.vaccinationHistory
            .map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _customExtensionCtrl.dispose();
    _numberCtrl.dispose();
    _addressCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianContactCtrl.dispose();
    _customSexCtrl.dispose();
    _contactCtrl.dispose();
    _guardian2NameCtrl.dispose();
    _guardian2ContactCtrl.dispose();
    _allergicToCtrl.dispose();
    _patientRemarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Check custom required validation for Birthdate
    bool isValid = _formKey.currentState!.validate();
    if (_selectedBirthdate == null) {
      setState(() {}); // trigger rebuild to show error text
      isValid = false;
    }
    if (!isValid) return;

    final provider = context.read<PatientProvider>();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final middleName = _middleNameCtrl.text.trim();

    String ext = '';
    if (_selectedExtension == 'Others') {
      ext = _customExtensionCtrl.text.trim();
    } else if (_selectedExtension != 'None') {
      ext = _selectedExtension;
    }

    final patientName = '$lastName, $firstName $middleName $ext'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    String finalSex = '';
    if (_selectedSex == 'Others') {
      finalSex = _customSexCtrl.text.trim();
    } else {
      finalSex = _selectedSex;
    }

    if (isEditing) {
      final updated = widget.patient!.copyWith(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        extension: ext,
        patientName: patientName,
        idNumber: _numberCtrl.text.trim(),
        birthdate: _selectedBirthdate,
        sex: finalSex,
        contactNumber: _contactCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
        guardian2Name: _guardian2NameCtrl.text.trim(),
        guardian2Contact: _guardian2ContactCtrl.text.trim(),
        pastMedicalHistory: _pastMedicalHistory
            .where((m) => m['past'] == true || m['present'] == true)
            .toList(),
        vaccinationHistory: _vaccinationHistory
            .where((m) => m['name'].toString().trim().isNotEmpty)
            .toList(),
        allergicTo: _allergicToCtrl.text.trim(),
        patientRemarks: _patientRemarksCtrl.text.trim(),
      );
      await provider.updatePatient(updated);
      if (mounted) Navigator.pop(context);
    } else {
      final patient = Patient(
        id: const Uuid().v4(),
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        extension: ext,
        patientName: patientName,
        idNumber: _numberCtrl.text.trim(),
        birthdate: _selectedBirthdate,
        sex: finalSex,
        contactNumber: _contactCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
        guardian2Name: _guardian2NameCtrl.text.trim(),
        guardian2Contact: _guardian2ContactCtrl.text.trim(),
        pastMedicalHistory: _pastMedicalHistory
            .where((m) => m['past'] == true || m['present'] == true)
            .toList(),
        vaccinationHistory: _vaccinationHistory
            .where((m) => m['name'].toString().trim().isNotEmpty)
            .toList(),
        allergicTo: _allergicToCtrl.text.trim(),
        patientRemarks: _patientRemarksCtrl.text.trim(),
      );
      await provider.addPatient(patient);
      if (mounted) Navigator.pop(context, patient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: DefaultTabController(
        length: 2,
        initialIndex: widget.initialTabIndex,
        child: Container(
          width: 760,
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_rounded
                            : Icons.person_add_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEditing ? 'Edit Record' : 'New Record',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  tabs: [
                    Tab(text: 'Personal Information'),
                    Tab(text: 'Medical Information'),
                  ],
                  labelColor: Colors.white,
                  labelStyle: TextStyle(
                    fontFamily: GoogleFonts.inter().fontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: GoogleFonts.inter().fontFamily,
                    fontWeight: FontWeight.normal,
                  ),
                  indicator: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  dividerColor: AppTheme.accent,
                  dividerHeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                const SizedBox(height: 16),

                // Tabbed Fields
                Flexible(
                  child: TabBarView(
                    children: [_buildPersonalTab(), _buildMedicalTab()],
                  ),
                ),

                const SizedBox(height: 24),

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
                      child: Text(isEditing ? 'Save' : 'Add'),
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

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Name Row 1: First Name & Last Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name Row 2: Middle Name & Extension
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _middleNameCtrl,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: 'Middle Name',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(30),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: _selectedExtension == 'Others' ? 1 : 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedExtension,
                    decoration: const InputDecoration(
                      labelText: 'Extension',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: ['None', 'JR.', 'SR.', 'I', 'II', 'III', 'Others']
                        .map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        })
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedExtension = val);
                      }
                    },
                  ),
                ),
                if (_selectedExtension == 'Others') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _customExtensionCtrl,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Specify',
                        counterText: '',
                      ),
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ID Number
            TextFormField(
              controller: _numberCtrl,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'ID Number *',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(16),
              ],
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'ID number is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Birthdate & Sex
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthdate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedBirthdate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birthdate *',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _selectedBirthdate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(_selectedBirthdate!)
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedBirthdate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: _selectedSex == 'Others' ? 1 : 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSex,
                    decoration: const InputDecoration(
                      labelText: 'Sex *',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: ['Male', 'Female', 'Others'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSex = val);
                      }
                    },
                  ),
                ),
                if (_selectedSex == 'Others') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _customSexCtrl,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Specify',
                        counterText: '',
                      ),
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ],
            ),
            if (_selectedBirthdate == null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'Birthdate is required',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Contact Number
            TextFormField(
              controller: _contactCtrl,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone_outlined),
                counterText: '',
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressCtrl,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home_outlined),
                counterText: '',
              ),
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(150),
              ],
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _guardianNameCtrl,
                    maxLength: 65,
                    decoration: const InputDecoration(
                      labelText: 'Parent / Guardian Name',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      counterText: '',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(65),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _guardianContactCtrl,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Parent / Guardian Contact',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _guardian2NameCtrl,
                    maxLength: 65,
                    decoration: const InputDecoration(
                      labelText: 'Second Guardian Name',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      counterText: '',
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(65),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _guardian2ContactCtrl,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Second Guardian Contact',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAllergiesSection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildMedicalHistorySection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildVaccinationSection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildPatientRemarksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allergies', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _allergicToCtrl,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'The patient is allergic to...',
            prefixIcon: Icon(Icons.coronavirus_outlined),
          ),
          inputFormatters: [UpperCaseTextFormatter()],
        ),
      ],
    );
  }

  Widget _buildPatientRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Patient Remarks',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _patientRemarksCtrl,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'Remarks',
            prefixIcon: Icon(Icons.note_alt_outlined),
          ),
          inputFormatters: [UpperCaseTextFormatter()],
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Past Medical History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _pastMedicalHistory.insert(0, {
                    'disease': '',
                    'past': false,
                    'present': false,
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Disease',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        'Past',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        'Present',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // spacer for delete button
                ],
              ),
              const Divider(),
              ...List.generate(_pastMedicalHistory.length, (index) {
                final item = _pastMedicalHistory[index];
                final isPreset = _presetDiseases.contains(item['disease']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: isPreset
                            ? Text(item['disease'])
                            : TextFormField(
                                initialValue: item['disease'],
                                decoration: const InputDecoration(
                                  hintText: 'Enter disease name',
                                  isDense: true,
                                ),
                                onChanged: (val) => item['disease'] = val,
                              ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Checkbox(
                            value: item['past'] == true,
                            onChanged: (val) {
                              setState(() => item['past'] = val);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Checkbox(
                            value: item['present'] == true,
                            onChanged: (val) {
                              setState(() => item['present'] = val);
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: !isPreset
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.danger,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _pastMedicalHistory.removeAt(index);
                                  });
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vaccination History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _vaccinationHistory.add({'name': '', 'dateGiven': null});
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Vaccine', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_vaccinationHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No vaccines added',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ..._vaccinationHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: item['name'],
                      decoration: const InputDecoration(
                        labelText: 'Vaccine Name',
                        prefixIcon: Icon(Icons.vaccines_outlined),
                      ),
                      onChanged: (val) => item['name'] = val,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: item['dateGiven'] != null
                              ? DateTime.parse(item['dateGiven'])
                              : DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            item['dateGiven'] = date.toIso8601String();
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date Given',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          item['dateGiven'] != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(DateTime.parse(item['dateGiven']))
                              : 'Select Date',
                          style: TextStyle(
                            color: item['dateGiven'] != null
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.danger,
                    ),
                    onPressed: () {
                      setState(() {
                        _vaccinationHistory.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
