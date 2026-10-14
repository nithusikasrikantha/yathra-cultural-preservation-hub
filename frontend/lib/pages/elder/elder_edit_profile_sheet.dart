import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';
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
  Uint8List? _photo;
  String? _photoName;
  bool _choosing = false;
  String? _uploadedAvatar;
  bool _saving = false;

  Future<void> _choosePhoto() async {
    setState(() => _choosing = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024)
        throw Exception('Choose a picture smaller than 8 MB.');
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoName = image.name;
        _uploadedAvatar = null;
        _error = null;
      });
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _choosing || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_photo != null && _uploadedAvatar == null) {
        final extension = _photoName!.split('.').last.toLowerCase();
        final mime = extension == 'png'
            ? 'png'
            : extension == 'webp'
            ? 'webp'
            : 'jpeg';
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/images'),
        );
        final headers = await AuthService.authenticatedHeaders();
        headers.remove('Content-Type');
        request.headers.addAll(headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _photo!,
            filename: _photoName,
            contentType: MediaType('image', mime),
          ),
        );
        final response = await http.Response.fromStream(
          await request.send(),
        ).timeout(const Duration(seconds: 40));
        final result = jsonDecode(response.body);
        if (response.statusCode != 201)
          throw Exception(result['message'] ?? 'Picture upload failed.');
        _uploadedAvatar = result['imageUrl'] as String;
      }
      final profile = await AuthService().updateElderProfile({
        if (_uploadedAvatar != null) 'avatar': _uploadedAvatar,
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
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFF1E5D7),
              backgroundImage: _photo != null ? MemoryImage(_photo!) : null,
              child: _photo != null
                  ? null
                  : ClipOval(
                      child: Image.network(
                        (widget.profile['avatar']?.toString() ?? '').startsWith(
                              '/',
                            )
                            ? '${ApiConfig.baseUrl}${widget.profile['avatar']}'
                            : widget.profile['avatar']?.toString() ?? '',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          size: 48,
                          color: Color(0xFF6F432A),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving || _choosing ? null : _choosePhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _choosing ? 'Opening photos...' : 'Choose profile picture',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6F432A),
                minimumSize: const Size(0, 48),
              ),
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
                  onPressed: _saving || _choosing ? null : _save,
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
