import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ElderEditProfileSheet extends StatefulWidget {
  const ElderEditProfileSheet({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override
  State<ElderEditProfileSheet> createState() => _ElderEditProfileSheetState();
}

class _ElderEditProfileSheetState extends State<ElderEditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.profile['name']?.toString() ?? '',
  );
  late final _bio = TextEditingController(
    text: widget.profile['bio']?.toString() ?? '',
  );
  late final _location = TextEditingController(
    text: widget.profile['location']?.toString() ?? '',
  );
  late String _language =
      widget.profile['preferredLanguage']?.toString() ?? 'Tamil';
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await AuthService().updateElderProfile({
        'name': _name.text.trim(),
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
        'preferredLanguage': _language,
      });
      if (mounted) Navigator.pop(context, profile);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name'
                  : null,
            ),
            TextFormField(
              controller: _bio,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            TextFormField(
              controller: _location,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Preferred language',
              ),
              items: ['Tamil', 'Sinhala', 'English']
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(language),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _language = value);
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
