import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/medical_provider.dart';
import '../theme/app_theme.dart';

class UploadMedicalDataScreen extends StatefulWidget {
  final String studentId;
  const UploadMedicalDataScreen({super.key, required this.studentId});

  @override
  State<UploadMedicalDataScreen> createState() =>
      _UploadMedicalDataScreenState();
}

class _UploadMedicalDataScreenState extends State<UploadMedicalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicalProvider>();
    await provider.addRecord(
      studentId: widget.studentId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      filePath: _selectedFilePath ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medical record uploaded!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Medical Data')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Document',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload medical records, lab results, prescriptions, or other health documents.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Blood Test Results',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Provide additional details...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // File Picker
                Text(
                  'Attach Document',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.dividerColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedFileName != null
                              ? Icons.check_circle_rounded
                              : Icons.cloud_upload_rounded,
                          size: 40,
                          color: _selectedFileName != null
                              ? AppTheme.accent
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFileName ?? 'Tap to select a file',
                          style: TextStyle(
                            color: _selectedFileName != null
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                            fontWeight: _selectedFileName != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG, DOC supported',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleUpload,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload Record'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
