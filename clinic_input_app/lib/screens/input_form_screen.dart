import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/symptoms.dart';
import '../formatters/uppercase_text.dart';
import '../services/desktop_connection_service.dart';
import '../services/queue_service.dart';
import '../services/persistent_form_service.dart';
import '../theme/app_theme.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({super.key});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queueService = QueueService();
  bool _isSubmitting = false;

  // ── Patient fields ───────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _customExtensionCtrl = TextEditingController();
  String _selectedExtension = 'None';
  final _numberCtrl = TextEditingController();
  DateTime? _selectedBirthdate;
  String _selectedSex = 'Female';
  final _customSexCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianContactCtrl = TextEditingController();
  final _guardian2NameCtrl = TextEditingController();
  final _guardian2ContactCtrl = TextEditingController();
  final _allergicToCtrl = TextEditingController();

  // ── Visitation fields ────────────────────────────────────────────
  final Set<String> _selectedSymptoms = {};
  bool _showAllTraumatic = true;
  bool _showAllMedical = true;
  bool _showAllBehavioral = true;

  @override
  void initState() {
    super.initState();
    final p = PersistentFormService.instance;

    // Initialize state from persistence
    _firstNameCtrl.text = p.firstName;
    _lastNameCtrl.text = p.lastName;
    _middleNameCtrl.text = p.middleName;
    _numberCtrl.text = p.studentNumber;
    _contactCtrl.text = p.contactNumber;
    _addressCtrl.text = p.address;
    _guardianNameCtrl.text = p.guardianName;
    _guardianContactCtrl.text = p.guardianContact;
    _guardian2NameCtrl.text = p.guardian2Name;
    _guardian2ContactCtrl.text = p.guardian2Contact;
    _customExtensionCtrl.text = p.customExtension;
    _customSexCtrl.text = p.customSex;
    _allergicToCtrl.text = p.allergicTo;

    _selectedExtension = p.extension;
    _selectedBirthdate = p.birthdate;
    _selectedSex = p.sex;
    _selectedSymptoms.addAll(p.selectedSymptoms);

    // Add listeners to sync UI -> Persistent Service
    _firstNameCtrl.addListener(() => p.firstName = _firstNameCtrl.text);
    _lastNameCtrl.addListener(() => p.lastName = _lastNameCtrl.text);
    _middleNameCtrl.addListener(() => p.middleName = _middleNameCtrl.text);
    _customExtensionCtrl.addListener(() => p.customExtension = _customExtensionCtrl.text);
    _numberCtrl.addListener(() => p.studentNumber = _numberCtrl.text);
    _customSexCtrl.addListener(() => p.customSex = _customSexCtrl.text);
    _contactCtrl.addListener(() => p.contactNumber = _contactCtrl.text);
    _addressCtrl.addListener(() => p.address = _addressCtrl.text);
    _guardianNameCtrl.addListener(() => p.guardianName = _guardianNameCtrl.text);
    _guardianContactCtrl.addListener(() => p.guardianContact = _guardianContactCtrl.text);
    _guardian2NameCtrl.addListener(() => p.guardian2Name = _guardian2NameCtrl.text);
    _guardian2ContactCtrl.addListener(() => p.guardian2Contact = _guardian2ContactCtrl.text);
    _allergicToCtrl.addListener(() => p.allergicTo = _allergicToCtrl.text);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _customExtensionCtrl.dispose();
    _numberCtrl.dispose();
    _customSexCtrl.dispose();
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianContactCtrl.dispose();
    _guardian2NameCtrl.dispose();
    _guardian2ContactCtrl.dispose();
    _allergicToCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _middleNameCtrl.clear();
    _customExtensionCtrl.clear();
    _numberCtrl.clear();
    _customSexCtrl.clear();
    _contactCtrl.clear();
    _addressCtrl.clear();
    _guardianNameCtrl.clear();
    _guardianContactCtrl.clear();
    _guardian2NameCtrl.clear();
    _guardian2ContactCtrl.clear();
    _allergicToCtrl.clear();
    PersistentFormService.instance.clear();
    setState(() {
      _selectedExtension = 'None';
      _selectedBirthdate = null;
      _selectedSex = 'Female';
      _selectedSymptoms.clear();
    });
  }

  Future<void> _submit() async {
    bool isValid = _formKey.currentState!.validate();
    if (_selectedBirthdate == null) {
      setState(() {}); // trigger rebuild to show error text
      isValid = false;
    }

    if (!isValid) return;

    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one symptom'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Build full name: "LAST, FIRST MIDDLE EXT"
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final middleName = _middleNameCtrl.text.trim();
    String ext = '';
    if (_selectedExtension == 'Others') {
      ext = _customExtensionCtrl.text.trim();
    } else if (_selectedExtension != 'None') {
      ext = _selectedExtension;
    }
    final studentName = '$lastName, $firstName $middleName $ext'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    String finalSex = '';
    if (_selectedSex == 'Others') {
      finalSex = _customSexCtrl.text.trim();
    } else {
      finalSex = _selectedSex;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Submission'),
          ],
        ),
        content: const Text(
          'By submitting this form, you agree that the information provided is true and correct.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    // Initial connection check
    final isConnected = await DesktopConnectionService.instance.checkConnection();
    if (!isConnected) {
      if (mounted) setState(() => _isSubmitting = false);
      _showConnectionLostDialog();
      return;
    }

    try {
      await _queueService.addToQueue(
        studentName: studentName,
        studentNumber: _numberCtrl.text.trim(),
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        extension: ext,
        birthdate: _selectedBirthdate,
        sex: finalSex,
        contactNumber: _contactCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        guardianName: _guardianNameCtrl.text.trim(),
        guardianContact: _guardianContactCtrl.text.trim(),
        guardian2Name: _guardian2NameCtrl.text.trim(),
        guardian2Contact: _guardian2ContactCtrl.text.trim(),
        allergicTo: _allergicToCtrl.text.trim(),
        symptoms: _selectedSymptoms.toList(),
      );

      if (!mounted) return;
      _resetForm();
      Navigator.pushReplacementNamed(context, '/confirmation');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      // If the error message indicates a connection issue, show the special dialog
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('connection') || errorMsg.contains('reachable')) {
        _showConnectionLostDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Displays a dialog when the connection to the desktop app is lost.
  void _showConnectionLostDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Connection Lost'),
          ],
        ),
        content: const Text(
          'The connection to the clinic desktop app has been lost. Please ensure the tablet is still on the correct Wi-Fi network.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushReplacementNamed(context, '/scan');
            },
            child: const Text('Reset Connection'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _submit(); // Retry submission
            },
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // ── App bar area ──────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/welcome'),
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_information_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Patient & Visit Form',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════════
              //  SECTION 1 — Patient Information
              // ═══════════════════════════════════════════════════
              const _SectionHeader(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
              ),
              const SizedBox(height: 16),

              // First Name & Last Name
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
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Middle Name & Extension
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
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          PersistentFormService.instance.extension = val;
                        }
                      },
                    ),
                  ),
                  if (_selectedExtension == 'Others') ...[
                    const SizedBox(width: 12),
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
              const SizedBox(height: 14),

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
              const SizedBox(height: 14),

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
                          PersistentFormService.instance.birthdate = picked;
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
                  const SizedBox(width: 12),
                  Expanded(
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
                          PersistentFormService.instance.sex = val;
                        }
                      },
                    ),
                  ),
                  if (_selectedSex == 'Others') ...[
                    const SizedBox(width: 12),
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
              const SizedBox(height: 14),

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
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 14),

              // Guardian 1: Name & Contact
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 12),
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
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Guardian 2: Name & Contact
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 12),
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
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Allergic To
              TextFormField(
                controller: _allergicToCtrl,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'The patient is allergic to...',
                  prefixIcon: Icon(Icons.coronavirus_outlined),
                ),
                inputFormatters: [UpperCaseTextFormatter()],
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════
              //  SECTION 2 — Chief Complaints / Symptoms
              // ═══════════════════════════════════════════════════
              const _SectionHeader(
                icon: Icons.medical_services_outlined,
                title: 'Chief Complaints / Symptoms',
              ),
              const SizedBox(height: 16),

              // Traumatic
              _buildSymptomSection(
                title: 'Traumatic',
                allItems: kTraumaticSymptoms,
                showAll: _showAllTraumatic,
                onToggle: () =>
                    setState(() => _showAllTraumatic = !_showAllTraumatic),
              ),
              const SizedBox(height: 12),

              // Medical
              _buildSymptomSection(
                title: 'Medical',
                allItems: kMedicalSymptoms,
                showAll: _showAllMedical,
                onToggle: () =>
                    setState(() => _showAllMedical = !_showAllMedical),
              ),
              const SizedBox(height: 12),

              // Behavioral
              _buildSymptomSection(
                title: 'Behavioral',
                allItems: kBehavioralSymptoms,
                showAll: _showAllBehavioral,
                onToggle: () =>
                    setState(() => _showAllBehavioral = !_showAllBehavioral),
              ),
              const SizedBox(height: 32),

              // ── Submit button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Form'),
                ),
              ),
              const SizedBox(height: 12),

              // ── Clear form button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.danger,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Clear Form?'),
                          ],
                        ),
                        content: const Text(
                          'This will remove all entered data. Are you sure you want to clear the form?',
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) _resetForm();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear Form'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Symptom category section (adapted from desktop visitation form) ──
  Widget _buildSymptomSection({
    required String title,
    required List<String> allItems,
    required bool showAll,
    required VoidCallback onToggle,
  }) {
    final displayItems = showAll
        ? allItems
        : allItems.where((item) => _selectedSymptoms.contains(item)).toList();

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
                  style: const TextStyle(fontSize: 12, color: AppTheme.accent),
                ),
              ),
            ],
          ),
          if (displayItems.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayItems.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              return FilterChip(
                showCheckmark: false,
                label: Text(
                  symptom,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSymptoms.add(symptom);
                      PersistentFormService.instance.addSymptom(symptom);
                    } else {
                      _selectedSymptoms.remove(symptom);
                      PersistentFormService.instance.removeSymptom(symptom);
                    }
                  });
                },
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.cardLight,
                side: BorderSide(
                  color: isSelected ? AppTheme.accent : AppTheme.dividerColor,
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

// ── Section header widget ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.08),
            AppTheme.accent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentDim),
          ),
        ],
      ),
    );
  }
}
