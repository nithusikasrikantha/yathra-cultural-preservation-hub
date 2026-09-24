import 'package:flutter/material.dart';

class YouthProfilePage extends StatefulWidget {
  const YouthProfilePage({super.key});

  @override
  State<YouthProfilePage> createState() => _YouthProfilePageState();
}

class _YouthProfilePageState extends State<YouthProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> _languages = ['Tamil', 'Sinhala', 'English'];

  final List<String> _interests = [
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
  String? _selectedLanguage = 'Tamil';

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Youth Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create your youth profile and choose the cultural topics you want to explore.',
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkBrown,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
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
                const SizedBox(height: 28),
                _buildSectionLabel('Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 18, color: _darkBrown),
                  decoration: _buildInputDecoration(
                    label: 'Name',
                    hint: 'Enter your name',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Age or Age Group'),
                const SizedBox(height: 8),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 18, color: _darkBrown),
                  decoration: _buildInputDecoration(
                    label: 'Age or age group',
                    hint: 'Example: 16 or 13-18',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Preferred Language'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  style: const TextStyle(fontSize: 18, color: _darkBrown),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: _primaryBrown,
                    size: 32,
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Preferred language',
                    hint: 'Select a language',
                  ),
                  items: _languages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Location or Region'),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 18, color: _darkBrown),
                  decoration: _buildInputDecoration(
                    label: 'Location or region',
                    hint: 'Enter your city, district, or region',
                  ),
                ),
                const SizedBox(height: 28),
                _buildSectionLabel('Cultural Interests'),
                const SizedBox(height: 8),
                const Text(
                  'Select one or more interests.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _interests.map((String interest) {
                    final bool isSelected = _selectedInterests.contains(
                      interest,
                    );

                    return FilterChip(
                      label: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.white : _darkBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: _primaryBrown,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? _primaryBrown
                            : _primaryBrown.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      onSelected: (bool selected) {
                        _toggleInterest(interest, selected);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      _showSnackBar('Youth profile saved for this session.');
                    },
                    child: const Text(
                      'Save and Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
      labelStyle: const TextStyle(color: _darkBrown, fontSize: 16),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBrown, width: 2),
      ),
    );
  }
}
