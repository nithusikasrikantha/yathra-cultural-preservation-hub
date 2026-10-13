import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _brown = Color(0xFF542717);
  static const _darkBrown = Color(0xFF2D1B14);
  static const _muted = Color(0xFF806D61);
  static const _cream = Color(0xFFF5F0E6);

  String? _selectedRole;
  String? _roleError;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isSubmitting = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedRole == null) {
      setState(() => _roleError = 'Please choose Elder or Youth / Learner.');
      return;
    }
    setState(() => _roleError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] as String? ??
                'Registration successful! Please log in.',
          ),
          backgroundColor: _brown,
        ),
      );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    appBar: AppBar(
      backgroundColor: _cream,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _darkBrown),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
      ),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Serif',
                  color: _darkBrown,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join YATHRA and be part of our cultural journey',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _fieldLabel('FULL NAME'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required.'
                    : null,
              ),
              const SizedBox(height: 9),
              _fieldLabel('EMAIL'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  hint: 'Enter your email',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email is required.';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$')
                      .hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 9),
              _fieldLabel('PASSWORD'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                decoration: _decoration(
                  hint: 'Create a password',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  if (value.length < 8 || value.length > 128) {
                    return 'Use 8 to 128 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              _fieldLabel('SELECT YOUR ROLE'),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: _RoleCard(
                        title: 'Elder',
                        subtitle: 'Share your knowledge',
                        icon: Icons.elderly_rounded,
                        selected: _selectedRole == 'elder',
                        onTap: () => _chooseRole('elder'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: _RoleCard(
                        title: 'Youth',
                        subtitle: 'Discover and learn',
                        icon: Icons.school_rounded,
                        selected: _selectedRole == 'youth',
                        onTap: () => _chooseRole('youth'),
                      ),
                    ),
                  ),
                ],
              ),
              if (_roleError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _roleError!,
                  style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                ),
              ],
              const SizedBox(height: 13),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Already have an account? ',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Login',
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
  );

  void _chooseRole(String role) => setState(() {
    _selectedRole = role;
    _roleError = null;
  });

  static Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: title,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEBDD) : const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFFD66A3D) : const Color(0xFFE5D8C9),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFFEBDD),
              child: Icon(icon, size: 19, color: const Color(0xFF8F351C)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF542717),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF806D61),
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
