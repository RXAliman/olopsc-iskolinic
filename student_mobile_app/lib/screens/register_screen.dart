import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianEmailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      studentName: _nameController.text.trim(),
      studentNumber: _numberController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      guardianEmail: _guardianEmailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else if (auth.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Student Number',
                    hintText: 'e.g. STU-2025-001',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Student number is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Institutional Email',
                    hintText: 'student@school.edu.ph',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // Guardian Section
                Text(
                  'Parent / Guardian (optional)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your parent/guardian can link their Google account later.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guardianNameController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _guardianEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Email',
                    hintText: 'parent@gmail.com',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
