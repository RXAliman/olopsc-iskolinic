import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../formatters/uppercase_text.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

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

  bool get isEditing => widget.patient != null;

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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (isEditing) {
      final updated = widget.patient!.copyWith(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        extension: ext,
        patientName: patientName,
        idNumber: _numberCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
      );
      await provider.updatePatient(updated);
    } else {
      final patient = Patient(
        id: const Uuid().v4(),
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        extension: ext,
        patientName: patientName,
        idNumber: _numberCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
      );
      await provider.addPatient(patient);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
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
                      isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
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
              const SizedBox(height: 28),

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
                      inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(30)],
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
                      inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(30)],
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
                      inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(30)],
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
                        inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(5)],
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
                inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(16)],
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'ID number is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                  counterText: '',
                ),
                inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(150)],
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),

              // Guardian Name
              TextFormField(
                controller: _guardianNameCtrl,
                maxLength: 65,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Name',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                  counterText: '',
                ),
                inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(65)],
              ),
              const SizedBox(height: 16),

              // Guardian Contact
              TextFormField(
                controller: _guardianContactCtrl,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Contact',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
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
                    child: Text(isEditing ? 'Save' : 'Add'),
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
