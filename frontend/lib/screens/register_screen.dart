import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedRole;
  String? _roleError;
  String _selectedLanguage = 'English';
  String _selectedRegion = 'Jaffna';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedRole == null) {
      setState(() => _roleError = 'Please select Elder or Youth.');
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
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
        title: const Text('Back', style: TextStyle(fontSize: 14)),
        titleSpacing: -10,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),

                const SizedBox(height: 24),

                // Persona / Role Selection Section
                _buildFieldLabel('SELECT YOUR EXPERIENCE'),
                const SizedBox(height: 8),

                // Elder Persona Card
                _buildPersonaCard(
                  role: 'elder',
                  title: 'Elder',
                  subtitle:
                      'Share stories, speak traditions, and guide the youth',
                ),

                const SizedBox(height: 12),

                // Youth Persona Card
                _buildPersonaCard(
                  role: 'youth',
                  title: 'Youth',
                  subtitle:
                      'Discover heritage, translate dialects, and co-create with elders',
                ),

                if (_roleError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _roleError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _buildFieldLabel('FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),

                const SizedBox(height: 20),

                _buildFieldLabel('LANGUAGE PREFERENCE'),
                _buildDropdown(
                  ['Tamil', 'Sinhala', 'English'],
                  _selectedLanguage,
                  (val) {
                    setState(() => _selectedLanguage = val!);
                  },
                ),

                const SizedBox(height: 20),

                _buildFieldLabel('REGION / DISTRICT'),
                _buildDropdown(
                  ['Jaffna', 'Kandy', 'Galle', 'Colombo'],
                  _selectedRegion,
                  (val) {
                    setState(() => _selectedRegion = val!);
                  },
                ),

                const SizedBox(height: 20),

                _buildFieldLabel('EMAIL OR PHONE NUMBER'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. email@example.com',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email is required.';
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildFieldLabel('PASSWORD'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Create a strong password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required.';
                    }
                    if (value.length < 8 || value.length > 128) {
                      return 'Password must be between 8 and 128 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _register,
                  child: Text(
                    _isSubmitting ? 'Creating account...' : 'Continue',
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      // Bottom Navigation Bar is removed as requested
    );
  }

  Widget _buildPersonaCard({
    required String role,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _roleError = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.withValues(alpha: 0.35),
            width: isSelected ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey,
                  width: isSelected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
