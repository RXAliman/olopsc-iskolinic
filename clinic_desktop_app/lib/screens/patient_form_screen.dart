import 'package:flutter/material.dart';
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
  late TextEditingController _nameCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _guardianNameCtrl;
  late TextEditingController _guardianContactCtrl;

  bool get isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.patient?.studentName ?? '');
    _numberCtrl = TextEditingController(
      text: widget.patient?.studentNumber ?? '',
    );
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
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _addressCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PatientProvider>();

    if (isEditing) {
      final updated = widget.patient!.copyWith(
        studentName: _nameCtrl.text.trim(),
        studentNumber: _numberCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
      );
      await provider.updatePatient(updated);
    } else {
      final patient = Patient(
        id: const Uuid().v4(),
        studentName: _nameCtrl.text.trim(),
        studentNumber: _numberCtrl.text.trim(),
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
        width: 500,
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
                    isEditing ? 'Edit Patient' : 'Add New Patient',
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

              // Student Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Student Number
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Number *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Student number is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Guardian Name
              TextFormField(
                controller: _guardianNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Name',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 16),

              // Guardian Contact
              TextFormField(
                controller: _guardianContactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Contact',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
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
                    child: Text(isEditing ? 'Save Changes' : 'Add Patient'),
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
