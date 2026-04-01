import 'package:flutter/material.dart';
import '../constants/symptoms.dart';
import '../formatters/uppercase_text.dart';
import '../theme/app_theme.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({super.key});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Patient fields
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianContactCtrl = TextEditingController();

  // Visitation fields
  final _treatmentCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final Set<String> _selectedSymptoms = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _addressCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianContactCtrl.dispose();
    _treatmentCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _numberCtrl.clear();
    _addressCtrl.clear();
    _guardianNameCtrl.clear();
    _guardianContactCtrl.clear();
    _treatmentCtrl.clear();
    _remarksCtrl.clear();
    setState(() => _selectedSymptoms.clear());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

    try {
      if (!mounted) return;
      _resetForm();
      Navigator.pushReplacementNamed(context, '/confirmation');
    } catch (e) {
      if (!mounted) return;
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              _SectionHeader(
                icon: Icons.person_outline_rounded,
                title: 'Patient Information',
              ),
              const SizedBox(height: 16),

              // Student Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                inputFormatters: [UpperCaseTextFormatter()],
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

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
              const SizedBox(height: 14),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Guardian Name
              TextFormField(
                controller: _guardianNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Name',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                inputFormatters: [UpperCaseTextFormatter()],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              // Guardian Contact
              TextFormField(
                controller: _guardianContactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Guardian / Parent Contact',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════
              //  SECTION 2 — Visitation Details
              // ═══════════════════════════════════════════════════
              _SectionHeader(
                icon: Icons.medical_services_outlined,
                title: 'Visitation Details',
              ),
              const SizedBox(height: 16),

              // Symptoms label
              Text(
                'Chief Complaints / Symptoms *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),

              // Symptom chips
              Wrap(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
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
