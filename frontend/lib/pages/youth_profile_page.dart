import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class YouthProfilePage extends StatefulWidget {
  const YouthProfilePage({super.key, this.onProfileSaved});

  final ValueChanged<Map<String, dynamic>>? onProfileSaved;

  @override
  State<YouthProfilePage> createState() => _YouthProfilePageState();
}

class _YouthProfilePageState extends State<YouthProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  static const List<String> _languages = ['Tamil', 'Sinhala', 'English'];
  static const List<String> _interests = [
    'Folklore',
    'Traditional Food',
    'Music',
    'Dance',
    'Festivals',
    'Language',
    'History',
    'Crafts',
  ];

  final Set<String> _selectedInterests = <String>{};
  String? _selectedLanguage;
  String? _avatar;
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _profileComplete = false;

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _authService.getYouthProfile();
      if (!mounted) return;

      final language = profile['preferredLanguage'];
      final profileInterests = profile['interests'];
      setState(() {
        _nameController.text = profile['name'] is String
            ? profile['name'] as String
            : '';
        _ageController.text = profile['ageGroup'] is String
            ? profile['ageGroup'] as String
            : '';
        _locationController.text = profile['location'] is String
            ? profile['location'] as String
            : '';
        _selectedLanguage = language is String && _languages.contains(language)
            ? language
            : null;
        _selectedInterests
          ..clear()
          ..addAll(
            profileInterests is List
                ? profileInterests.whereType<String>().where(
                    _interests.contains,
                  )
                : const <String>[],
          );
        _avatar = profile['avatar'] is String
            ? profile['avatar'] as String
            : null;
        _avatarController.text = _avatar ?? '';
        _profileComplete = profile['profileComplete'] == true;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (_selectedInterests.isEmpty) {
      _showSnackBar('Select at least one cultural interest.');
      return;
    }
    if (!formIsValid || _selectedLanguage == null) return;

    setState(() => _isSaving = true);
    try {
      final profile = await _authService.updateYouthProfile(
        name: _nameController.text.trim(),
        ageGroup: _ageController.text.trim(),
        preferredLanguage: _selectedLanguage!,
        location: _locationController.text.trim(),
        interests: _selectedInterests.toList(growable: false),
        avatar: _avatarController.text.trim().isEmpty
            ? null
            : _avatarController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _profileComplete = profile['profileComplete'] == true);
      widget.onProfileSaved?.call(profile);
      _showSnackBar('Youth profile saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleInterest(String interest, bool selected) {
    setState(() {
      if (selected) {
        _selectedInterests.add(interest);
      } else {
        _selectedInterests.remove(interest);
      }
    });
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: _darkBrown,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to access your Youth Hub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Youth Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBrown),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: _primaryBrown,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load youth profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkBrown,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage your details and choose the cultural topics you want to explore.',
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkBrown,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (!_profileComplete) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E5D5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _primaryBrown),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Complete the required fields and select at least one interest to finish your profile.',
                            style: TextStyle(color: _darkBrown, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Semantics(
                    label: 'Profile avatar placeholder',
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryBrown.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: _primaryBrown,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _avatarController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    label: 'Avatar image URL (optional)',
                    hint: 'https://example.com/avatar.jpg',
                  ),
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isEmpty) return null;
                    final uri = Uri.tryParse(url);
                    if (uri == null ||
                        !uri.hasScheme ||
                        !['http', 'https'].contains(uri.scheme)) {
                      return 'Enter a valid HTTP or HTTPS URL.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                _buildSectionLabel('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: _buildInputDecoration(
                    label: 'Name',
                    hint: 'Enter your name',
                  ),
                  validator: (value) => _requiredValidator(value, 'Name', 100),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Age or Age Group'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  maxLength: 30,
                  decoration: _buildInputDecoration(
                    label: 'Age or age group',
                    hint: 'Example: 16 or 13-18',
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'Age or age group', 30),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Preferred Language'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedLanguage),
                  initialValue: _selectedLanguage,
                  decoration: _buildInputDecoration(
                    label: 'Preferred language',
                    hint: 'Select a language',
                  ),
                  items: _languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSaving
                      ? null
                      : (language) =>
                            setState(() => _selectedLanguage = language),
                  validator: (value) =>
                      value == null ? 'Preferred language is required.' : null,
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Location or Region'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  decoration: _buildInputDecoration(
                    label: 'Location or region',
                    hint: 'Enter your city, district, or region',
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'Location', 100),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Cultural Interests'),
                const SizedBox(height: 8),
                const Text('Select one or more interests.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _interests
                      .map((interest) {
                        final isSelected = _selectedInterests.contains(
                          interest,
                        );
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          selectedColor: _primaryBrown,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _darkBrown,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: _isSaving
                              ? null
                              : (selected) =>
                                    _toggleInterest(interest, selected),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.bookmarks_outlined,
                          color: _primaryBrown,
                        ),
                        title: const Text('Saved Stories'),
                        subtitle: const Text(
                          'View stories saved on this device',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.of(context).pushNamed('/youth-saved'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text('Logout'),
                        onTap: _isSaving ? null : _logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value, String field, int maxLength) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$field is required.';
    }
    if (normalized.length > maxLength) {
      return '$field cannot exceed $maxLength characters.';
    }
    return null;
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _darkBrown,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBrown, width: 2),
      ),
    );
  }
}
