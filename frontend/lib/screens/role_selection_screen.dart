import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.authService, required this.initialUser});

  final AuthService authService;
  final Map<String, dynamic> initialUser;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isSubmitting = false;

  Future<void> _continue() async {
    final role = _selectedRole;
    if (role == null) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authService.updateRole(role);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose your role', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text('Welcome, ${widget.initialUser['name'] ?? ''}. Select how you would like to take part in YATHRA.'),
            const SizedBox(height: 28),
            _roleOption('elder', 'Elder', 'Share stories, traditions, and cultural wisdom.'),
            const SizedBox(height: 14),
            _roleOption('youth', 'Youth', 'Discover and preserve cultural heritage.'),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedRole == null || _isSubmitting ? null : _continue,
              child: Text(_isSubmitting ? 'Saving...' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(String role, String title, String description) {
    final selected = _selectedRole == role;
    return InkWell(
      onTap: _isSubmitting ? null : () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description),
            ])),
          ],
        ),
      ),
    );
  }
}
