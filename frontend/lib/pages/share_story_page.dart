import 'package:flutter/material.dart';

class ShareStoryPage extends StatefulWidget {
  const ShareStoryPage({super.key});

  @override
  State<ShareStoryPage> createState() => _ShareStoryPageState();
}

class _ShareStoryPageState extends State<ShareStoryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();

  final List<String> _categories = [
    'Traditional Story',
    'Recipe',
    'Song',
    'Proverb',
    'Traditional Practice',
    'Local History',
    'Language',
    'Other',
  ];

  final List<String> _languages = [
    'Tamil',
    'Sinhala',
    'English',
  ];

  String? _selectedCategory = 'Traditional Story';
  String? _selectedLanguage = 'Tamil';

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
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
          'Share Your Story',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              const Text(
                'Preserve cultural heritage by sharing your memories and wisdom.',
                style: TextStyle(
                  fontSize: 16,
                  color: _darkBrown,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Story Title Field
              _buildSectionLabel('Story Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 18, color: _darkBrown),
                decoration: _buildInputDecoration('Enter a title for your story'),
              ),
              const SizedBox(height: 24),

              // 2. Category Dropdown
              _buildSectionLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(fontSize: 18, color: _darkBrown),
                icon: const Icon(Icons.arrow_drop_down, color: _primaryBrown, size: 32),
                decoration: _buildInputDecoration('Select a category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 3. Language Dropdown
              _buildSectionLabel('Language'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                style: const TextStyle(fontSize: 18, color: _darkBrown),
                icon: const Icon(Icons.arrow_drop_down, color: _primaryBrown, size: 32),
                decoration: _buildInputDecoration('Select a language'),
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

              // 4. Your Story Multiline Field
              _buildSectionLabel('Your Story'),
              const SizedBox(height: 8),
              TextField(
                controller: _storyController,
                maxLines: 8,
                style: const TextStyle(fontSize: 18, color: _darkBrown),
                decoration: _buildInputDecoration('Write your story here...'),
              ),
              const SizedBox(height: 28),

              // 5. Voice Story Card (Placeholder for YTH-23)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: _primaryBrown.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryBrown.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: _primaryBrown,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Record Your Voice',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _darkBrown,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share your story using your voice',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _showSnackBar('Voice recording will be available in the next step.');
                      },
                      child: const Text(
                        'Record',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: _primaryBrown, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showSnackBar('Story saved as draft');
                      },
                      child: const Text(
                        'Save Draft',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryBrown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showSnackBar('Continue to the next step');
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
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

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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
