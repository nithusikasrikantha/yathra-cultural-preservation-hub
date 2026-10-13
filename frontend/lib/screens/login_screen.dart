import 'package:flutter/material.dart';
import '../pages/youth_hub_shell.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;
  bool _showPassword = false;

  static const _brown = Color(0xFF542717);
  static const _darkBrown = Color(0xFF2D1B14);
  static const _muted = Color(0xFF806D61);
  static const _cream = Color(0xFFF5F0E6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goBack() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await _authService.login(email: email, password: password);
      if (!mounted) return;

      final user = Map<String, dynamic>.from(result['user'] as Map);
      final role = user['role'] as String? ?? 'youth';
      final name = user['name'] as String? ?? 'YATHRA member';

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => YouthHubShell(userRole: role, userName: name),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, color: _darkBrown),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const _AuthBrand(compact: true),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      color: _darkBrown,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue your journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _fieldLabel('EMAIL'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      hint: 'Enter your email',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('PASSWORD'),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: _decoration(
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide password' : 'Show password',
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password recovery is not set up yet.'),
                        ),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: _brown, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFD8C9BC))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: _muted)),
                      ),
                      Expanded(child: Divider(color: Color(0xFFD8C9BC))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Google sign-in is not set up yet. Use email and password.',
                        ),
                      ),
                    ),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF9D3D20),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      foregroundColor: _darkBrown,
                      side: const BorderSide(color: Color(0xFFD8C9BC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text(
                          "Don't have an account? ",
                          style: TextStyle(color: _muted),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: _brown,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
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

  static Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 19, color: _muted),
    filled: true,
    fillColor: const Color(0xFFFFFEFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8DED3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _brown, width: 1.5),
    ),
  );
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        Icons.spa_rounded,
        size: compact ? 38 : 52,
        color: const Color(0xFF9D3D20),
      ),
      const SizedBox(height: 2),
      Text(
        'YATHRA',
        style: TextStyle(
          fontFamily: 'Serif',
          color: const Color(0xFF542717),
          fontSize: compact ? 25 : 32,
          fontWeight: FontWeight.w800,
          letterSpacing: compact ? 2.6 : 3.5,
        ),
      ),
    ],
  );
}
