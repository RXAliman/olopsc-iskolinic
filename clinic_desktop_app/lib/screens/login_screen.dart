import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@clinic.app');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/app-icon-colored.png',
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'IskoLinic Staff Sign In',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage the clinic',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 36),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password is required'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppTheme.dividerColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppTheme.dividerColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // TODO: Implement Google Sign-In
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Google Sign-In requires Firebase setup',
                                    ),
                                  ),
                                );
                              },
                        icon: Image.asset(
                          'assets/google-logo.png',
                          width: 22,
                          height: 22,
                        ),
                        label: const Text('Sign in with Google'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Default: admin@clinic.app / admin123',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
