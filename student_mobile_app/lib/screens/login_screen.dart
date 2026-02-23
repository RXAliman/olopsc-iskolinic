import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (auth.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (auth.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Title
                  Container(
                    width: 80,
                    height: 80,
                    decoration: AppTheme.accentCard(),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VVella Student',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your health companion on campus',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.account_circle_rounded, size: 22),
                      label: const Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppTheme.dividerColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or sign in with email',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppTheme.dividerColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email/Password Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'student@school.edu.ph',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Email is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Password is required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : _handleEmailLogin,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
