import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../config/api_config.dart';

enum RecordingState { notRecorded, recording, recorded, playing }

class ShareStoryPage extends StatefulWidget {
  final Map<String, dynamic>? storyToEdit;

  const ShareStoryPage({super.key, this.storyToEdit});

  @override
  State<ShareStoryPage> createState() => _ShareStoryPageState();
}

class _ShareStoryPageState extends State<ShareStoryPage> {
  int _currentStep =
      0; // 0: Must Details, 1: Optional Context, 2: AI Assistance, 3: Review

  // Step 1: Must Details Controllers
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

  final List<String> _languages = ['Tamil', 'Sinhala', 'English'];

  String _selectedCategory = 'Traditional Story';
  String _selectedLanguage = 'Tamil';

  // Step 2: Optional Context Controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();
  String? _bannerImage;
  final List<String> _additionalImages = [];
  bool _isUploadingImages = false;

  final List<String> _timePeriods = [
    'Specific year',
    'My childhood',
    'When I was a young adult',
    'Many years ago',
    'I don\'t remember',
    'Skip',
  ];
  String _selectedTimePeriod = 'My childhood';

  // Step 3: AI Assistance State
  bool _aiSummaryAccepted = true;
  final String _aiSummary =
      'A warm reflection on village heritage and cultural unity.';

  // Step 4: Visibility
  String _visibility = 'Public'; // Public, YATHRA Community, Private

  // Audio & Speech Engines (Nullable & Safely Initialized)
  AudioRecorder? _audioRecorder;
  AudioPlayer? _audioPlayer;
  SpeechToText? _speechToText;
  FlutterTts? _flutterTts;

  bool _isConvertingToText = false;
  bool _isSpeaking = false;
  bool _isPublishing = false;

  RecordingState _recordingState = RecordingState.notRecorded;
  String? _recordedFilePath;
  int _recordingSeconds = 0;
  Timer? _timer;
  StreamSubscription? _playerStateSubscription;

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  bool get _isEditing =>
      widget.storyToEdit != null && widget.storyToEdit!['_id'] != null;
  String? get _editingStoryId =>
      widget.storyToEdit != null ? widget.storyToEdit!['_id'] : null;

  String get _baseUrl => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    try {
      _safeInitPlugins();
    } catch (e) {
      debugPrint('Plugin init error: $e');
    }
    try {
      _populateEditData();
    } catch (e) {
      debugPrint('Edit data error: $e');
    }
  }

  void _safeInitPlugins() {
    try {
      _audioRecorder = AudioRecorder();
    } catch (_) {}

    try {
      _audioPlayer = AudioPlayer();
      _playerStateSubscription = _audioPlayer?.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _recordingState = RecordingState.recorded;
          });
        }
      });
    } catch (_) {}

    try {
      _speechToText = SpeechToText();
    } catch (_) {}

    try {
      _flutterTts = FlutterTts();
      _flutterTts?.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts?.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts?.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts?.setErrorHandler((msg) {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
    } catch (_) {}
  }

  void _populateEditData() {
    if (_isEditing) {
      final story = widget.storyToEdit!;
      _bannerImage = story['bannerImage'] ?? story['imageUrl'];
      _additionalImages.addAll(
        List<String>.from(story['additionalImages'] ?? []),
      );
      _locationController.text = story['location'] ?? '';
      _communityController.text = story['community'] ?? '';
      if (_timePeriods.contains(story['timePeriod'])) {
        _selectedTimePeriod = story['timePeriod'];
      }
      _titleController.text = story['title'] ?? '';
      _storyController.text = story['storyText'] ?? '';
      if (story['category'] != null &&
          _categories.contains(story['category'])) {
        _selectedCategory = story['category'];
      }
      if (story['language'] != null && _languages.contains(story['language'])) {
        _selectedLanguage = story['language'];
      }
      if (story['audioPath'] != null &&
          story['audioPath'].toString().isNotEmpty) {
        _recordedFilePath = story['audioPath'];
        _recordingState = RecordingState.recorded;
      }
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts?.stop();
    } catch (_) {}
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    try {
      _audioRecorder?.dispose();
    } catch (_) {}
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    _titleController.dispose();
    _storyController.dispose();
    _locationController.dispose();
    _communityController.dispose();
    _peopleController.dispose();

    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: _darkBrown,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  String _getLocaleId() {
    switch (_selectedLanguage) {
      case 'Tamil':
        return 'ta_LK';
      case 'Sinhala':
        return 'si_LK';
      case 'English':
      default:
        return 'en_US';
    }
  }

  String _getTtsLanguageCode() {
    switch (_selectedLanguage) {
      case 'Tamil':
        return 'ta-LK';
      case 'Sinhala':
        return 'si-LK';
      case 'English':
      default:
        return 'en-US';
    }
  }

  // Audio Recording Actions
  Future<void> _startRecording() async {
    try {
      if (_isSpeaking) await _stopSpeaking();

      if (_audioRecorder == null || !await _audioRecorder!.hasPermission()) {
        _showSnackBar('Microphone permission is required to record voice.');
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/story_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _recordingSeconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordingSeconds++);
      });

      setState(() {
        _recordingState = RecordingState.recording;
        _recordedFilePath = filePath;
      });
    } catch (e) {
      _showSnackBar('Failed to start recording. Please try again.');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final String? path = await _audioRecorder?.stop();
      if (path == null || path.isEmpty) {
        _showSnackBar('Failed to save recorded audio.');
        setState(() => _recordingState = RecordingState.notRecorded);
        return;
      }
      setState(() {
        _recordedFilePath = path;
        _recordingState = RecordingState.recorded;
      });
    } catch (e) {
      _showSnackBar('Failed to stop recording.');
    }
  }

  Future<void> _startPlayback() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) {
      _showSnackBar('No recorded audio file found.');
      return;
    }
    try {
      if (_isSpeaking) await _stopSpeaking();
      await _audioPlayer?.play(DeviceFileSource(_recordedFilePath!));
      setState(() => _recordingState = RecordingState.playing);
    } catch (e) {
      _showSnackBar('Failed to play recorded audio.');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer?.stop();
      setState(() => _recordingState = RecordingState.recorded);
    } catch (e) {
      _showSnackBar('Failed to stop audio playback.');
    }
  }

  Future<void> _reRecord() async {
    try {
      if (_isSpeaking) await _stopSpeaking();
      if (_recordingState == RecordingState.playing) {
        await _audioPlayer?.stop();
      } else if (_recordingState == RecordingState.recording) {
        _timer?.cancel();
        await _audioRecorder?.stop();
      }
      setState(() {
        _recordedFilePath = null;
        _recordingSeconds = 0;
        _recordingState = RecordingState.notRecorded;
      });
    } catch (e) {
      setState(() {
        _recordedFilePath = null;
        _recordingSeconds = 0;
        _recordingState = RecordingState.notRecorded;
      });
    }
  }

  // Speech to Text Conversion
  Future<void> _convertVoiceToText() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) {
      _showSnackBar('No recorded audio file found to convert.');
      return;
    }

    if (_isSpeaking) await _stopSpeaking();

    setState(() => _isConvertingToText = true);

    try {
      if (_speechToText == null) {
        _showSnackBar(
          'Speech recognition service not supported on this device.',
        );
        setState(() => _isConvertingToText = false);
        return;
      }

      bool available = await _speechToText!.initialize();
      final String localeId = _getLocaleId();

      if (!available) {
        setState(() => _isConvertingToText = false);
        _showSnackBar('Speech recognition is unavailable.');
        return;
      }

      String transcribedResult = '';

      _showSnackBar('Listening to microphone... Speak into microphone now!');

      await _speechToText!.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
        onResult: (result) {
          transcribedResult = result.recognizedWords;
          if (transcribedResult.isNotEmpty && mounted) {
            setState(() {
              _storyController.text = transcribedResult;
            });
          }
        },
      );

      await Future.delayed(const Duration(seconds: 6));

      if (mounted) {
        if (_speechToText?.isListening == true) {
          await _speechToText?.stop();
        }

        setState(() => _isConvertingToText = false);

        if (transcribedResult.isNotEmpty) {
          _showSnackBar(
            'Voice converted to text! You can edit the story below.',
          );
        } else {
          _showSnackBar(
            'No live speech detected. Speak into microphone while converting.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isConvertingToText = false);
    }
  }

  // Text-to-Speech
  Future<void> _speakStory() async {
    final String text = _storyController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please write or record a story first.');
      return;
    }

    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }

    try {
      final String langCode = _getTtsLanguageCode();
      await _flutterTts?.setLanguage(langCode);
      await _flutterTts?.setSpeechRate(0.45);
      final dynamic result = await _flutterTts?.speak(text);
      if (mounted) setState(() => _isSpeaking = result == 1);
    } catch (e) {
      _showSnackBar('Failed to play voice narration.');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
    if (mounted) setState(() => _isSpeaking = false);
  }

  // Publishing Story
  Future<void> _publishOrUpdateStory() async {
    final String title = _titleController.text.trim();
    final String storyText = _storyController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Please enter a title for your story.');
      return;
    }
    if (storyText.isEmpty && _recordedFilePath == null) {
      _showSnackBar('Please write story text or record a voice story.');
      return;
    }

    if (_isUploadingImages) {
      _showSnackBar('Please wait for your photos to finish uploading.');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _isPublishing = true);

    try {
      final Map<String, dynamic> body = {
        'title': title,
        'category': _selectedCategory,
        'language': _selectedLanguage,
        'storyText': storyText,
        'audioPath': _recordedFilePath,
        'bannerImage': _bannerImage,
        'additionalImages': _additionalImages,
        'location': _locationController.text.trim(),
        'timePeriod': _selectedTimePeriod,
        'community': _communityController.text.trim(),
        'visibility': _visibility,
        'aiSummary': _aiSummaryAccepted ? _aiSummary : null,
      };

      http.Response response;

      if (_isEditing) {
        final Uri url = Uri.parse('$_baseUrl/api/stories/$_editingStoryId');
        response = await http
            .put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
      } else {
        final Uri url = Uri.parse('$_baseUrl/api/stories');
        response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
          _isEditing ? 'Story updated!' : 'Story published successfully!',
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && navigator.canPop()) {
            navigator.pop(true);
          }
        });
      } else {
        _showSnackBar('Failed to save story. Server returned error.');
      }
    } catch (e) {
      _showSnackBar('Failed to save story. Please try again.');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Story' : 'Add Cultural Story',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Serif',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Header
              _buildStepProgressHeader(),

              const SizedBox(height: 20),

              // Step Content
              if (_currentStep == 0) _buildStep1MustDetails(),
              if (_currentStep == 1) _buildStep2OptionalContext(),
              if (_currentStep == 2) _buildStep3AiAssistance(),
              if (_currentStep == 3) _buildStep4ReviewAndPublish(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryBrown.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildStepDot(0, '1. Story')),
          Expanded(child: _buildStepDot(1, '2. Context')),
          Expanded(child: _buildStepDot(2, '3. AI')),
          Expanded(child: _buildStepDot(3, '4. Review')),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, String label) {
    final bool isActive = _currentStep == stepIndex;
    final bool isDone = _currentStep > stepIndex;

    return InkWell(
      onTap: () => setState(() => _currentStep = stepIndex),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isActive
                ? _primaryBrown
                : (isDone ? Colors.green : Colors.grey.shade300),
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.black54,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? _darkBrown : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: MUST DETAILS
  Widget _buildStep1MustDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Primary Story Content',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Share your story by typing or recording your voice. Either text or voice is required.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Story Title *'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 18, color: _darkBrown),
          decoration: _buildInputDecoration('e.g. Village Harvest Memory'),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Category *'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          value: _selectedCategory,
          items: _categories,
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Language *'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          value: _selectedLanguage,
          items: _languages,
          onChanged: (val) {
            if (val != null) setState(() => _selectedLanguage = val);
          },
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Story Content'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          maxLines: 6,
          style: const TextStyle(fontSize: 17, color: _darkBrown),
          decoration: _buildInputDecoration('Write your story here...'),
        ),
        const SizedBox(height: 10),
        _buildTtsButton(),

        const SizedBox(height: 24),

        _buildSectionLabel('Voice Story'),
        const SizedBox(height: 8),
        _buildVoiceRecordingCard(),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_titleController.text.trim().isEmpty) {
                _showSnackBar('Please enter a story title.');
                return;
              }
              setState(() => _currentStep = 1);
            },
            child: const Text(
              'Next: Optional Story Context →',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _imageUrl(String path) =>
      path.startsWith('/') ? '$_baseUrl$path' : path;

  Widget _imagePreview(
    String image,
    VoidCallback remove, {
    bool banner = false,
  }) => SizedBox(
    width: banner ? double.infinity : 98,
    height: banner ? 170 : 98,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _imageUrl(image),
            fit: BoxFit.cover,
            errorBuilder: (_, error, trace) => const ColoredBox(
              color: Color(0xFFE8DDCD),
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton(
            tooltip: 'Remove photo',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: _isUploadingImages ? null : remove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickImages({required bool banner}) async {
    setState(() => _isUploadingImages = true);
    try {
      final picker = ImagePicker();
      final List<XFile> selected;
      if (banner) {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          imageQuality: 85,
        );
        selected = image == null ? [] : [image];
      } else {
        selected = await picker.pickMultiImage(
          maxWidth: 1800,
          imageQuality: 85,
        );
        if (selected.length > 8 - _additionalImages.length) {
          _showSnackBar(
            'Choose at most ${8 - _additionalImages.length} more photos.',
          );
          return;
        }
      }
      for (final image in selected) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 8 * 1024 * 1024) {
          throw Exception('Each photo must be smaller than 8 MB.');
        }
        final extension = image.name.toLowerCase().split('.').last;
        final mime = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/api/images'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
            contentType: MediaType.parse(mime),
          ),
        );
        final response = await http.Response.fromStream(
          await request.send().timeout(const Duration(seconds: 30)),
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode != 201) {
          throw Exception(data['message'] ?? 'Photo upload failed.');
        }
        if (!mounted) return;
        setState(() {
          if (banner) {
            _bannerImage = data['imageUrl'] as String;
          } else {
            _additionalImages.add(data['imageUrl'] as String);
          }
        });
      }
    } catch (error) {
      _showSnackBar('Unable to add photo: $error');
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  // STEP 2: OPTIONAL STORY CONTEXT
  Widget _buildStep2OptionalContext() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Optional Story Context',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'All fields below are optional. Skip any details you prefer not to include.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Where is this story connected to?'),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          style: const TextStyle(fontSize: 17, color: _darkBrown),
          decoration: _buildInputDecoration(
            'e.g. Jaffna, Kandy, Galle (or leave empty)',
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Time Period / Era'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          value: _selectedTimePeriod,
          items: _timePeriods,
          onChanged: (val) {
            if (val != null) setState(() => _selectedTimePeriod = val);
          },
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Community / Tradition'),
        const SizedBox(height: 8),
        TextField(
          controller: _communityController,
          style: const TextStyle(fontSize: 17, color: _darkBrown),
          decoration: _buildInputDecoration('e.g. Northern Tamil Heritage'),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Banner Image (Optional)'),
        const SizedBox(height: 6),
        const Text(
          'Choose one photo for the top of your story.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        if (_bannerImage != null)
          _imagePreview(
            _bannerImage!,
            () => setState(() => _bannerImage = null),
            banner: true,
          ),
        OutlinedButton.icon(
          onPressed: _isUploadingImages
              ? null
              : () => _pickImages(banner: true),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _bannerImage == null
                ? 'Choose banner image'
                : 'Change banner image',
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Additional Photos (Optional)'),
        const SizedBox(height: 6),
        const Text(
          'Add up to 8 photos to your archival gallery.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final image in _additionalImages)
              _imagePreview(
                image,
                () => setState(() => _additionalImages.remove(image)),
              ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _isUploadingImages || _additionalImages.length >= 8
              ? null
              : () => _pickImages(banner: false),
          icon: const Icon(Icons.collections_outlined),
          label: const Text('Add gallery photos'),
        ),
        if (_isUploadingImages)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),

        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _primaryBrown),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => setState(() => _currentStep = 2),
                child: const Text(
                  'Skip Optional Context',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => setState(() => _currentStep = 2),
                child: const Text(
                  'Next: AI Assistance →',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: YATHRA AI ASSISTANCE
  Widget _buildStep3AiAssistance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF4A5D23), size: 24),
            const SizedBox(width: 8),
            const Text(
              'YATHRA AI Assistance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
                fontFamily: 'Serif',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'AI suggestions enhance discovery for learners. You can accept, edit, or ignore any suggestion.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // AI Summary Suggestion Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF8A9A5B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8A9A5B).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF4A5D23),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested by YATHRA AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'AI Summary:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _aiSummary,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Accept Summary'),
                    selected: _aiSummaryAccepted,
                    onSelected: (val) =>
                        setState(() => _aiSummaryAccepted = val),
                    selectedColor: _primaryBrown,
                    labelStyle: TextStyle(
                      color: _aiSummaryAccepted ? Colors.white : _primaryBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Ignore'),
                    selected: !_aiSummaryAccepted,
                    onSelected: (val) =>
                        setState(() => _aiSummaryAccepted = !val),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => setState(() => _currentStep = 3),
            child: const Text(
              'Next: Review & Publish →',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 4: REVIEW & PUBLISH
  Widget _buildStep4ReviewAndPublish() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Review Your Story',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review all details before publishing to the YATHRA community.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // Review Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryBrown.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isNotEmpty
                    ? _titleController.text
                    : 'Untitled Story',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_selectedLanguage • $_selectedCategory',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const Divider(height: 24),
              Text(
                _storyController.text.isNotEmpty
                    ? _storyController.text
                    : '(Voice Story recorded)',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              if (_locationController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '📍 Connected Location: ${_locationController.text}',
                  style: const TextStyle(fontSize: 13, color: _primaryBrown),
                ),
              ],
              if (_selectedTimePeriod != 'Skip') ...[
                const SizedBox(height: 4),
                Text(
                  '⏳ Time Period: $_selectedTimePeriod',
                  style: const TextStyle(fontSize: 13, color: _primaryBrown),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionLabel('Story Visibility'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          value: _visibility,
          items: ['Public', 'YATHRA Community', 'Private'],
          onChanged: (val) {
            if (val != null) setState(() => _visibility = val);
          },
        ),

        const SizedBox(height: 32),

        // Action Buttons: Save Draft & Publish
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
                  _showSnackBar('Story saved as draft!');
                },
                child: const Text(
                  'Save Draft',
                  style: TextStyle(
                    fontSize: 17,
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
                onPressed: _isPublishing ? null : _publishOrUpdateStory,
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publish Story',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final String validValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          style: const TextStyle(fontSize: 18, color: _darkBrown),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: _primaryBrown,
            size: 30,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTtsButton() {
    if (_isSpeaking) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.stop_circle, size: 24),
          label: const Text(
            'Stop Reading',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _stopSpeaking,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: _primaryBrown, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.volume_up, color: _primaryBrown, size: 24),
        label: Text(
          'Listen to Story ($_selectedLanguage)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
          ),
        ),
        onPressed: _speakStory,
      ),
    );
  }

  Widget _buildVoiceRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _primaryBrown.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (_recordingState) {
            RecordingState.notRecorded => _buildNotRecordedState(),
            RecordingState.recording => _buildRecordingState(),
            RecordingState.recorded => _buildRecordedState(),
            RecordingState.playing => _buildPlayingState(),
          },
        ],
      ),
    );
  }

  Widget _buildNotRecordedState() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBrown.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mic, color: _primaryBrown, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            backgroundColor: _primaryBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _startRecording,
          child: const Text(
            'Record',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Recording...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _formatDuration(_recordingSeconds),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.stop, size: 24),
            label: const Text(
              'Stop Recording',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: _stopRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 26),
            const SizedBox(width: 8),
            const Text(
              'Story Recording',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
            const Spacer(),
            Text(
              _formatDuration(_recordingSeconds),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Play',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _startPlayback,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: _primaryBrown, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: _primaryBrown, size: 22),
                label: const Text(
                  'Re-record',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
                onPressed: _reRecord,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSpeechToTextButton(),
      ],
    );
  }

  Widget _buildPlayingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up, color: _primaryBrown, size: 26),
            const SizedBox(width: 8),
            const Text(
              'Playing...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
            const Spacer(),
            Text(
              _formatDuration(_recordingSeconds),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.stop, size: 24),
                label: const Text(
                  'Stop',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _stopPlayback,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: _primaryBrown, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: _primaryBrown, size: 22),
                label: const Text(
                  'Re-record',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
                onPressed: _reRecord,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSpeechToTextButton(),
      ],
    );
  }

  Widget _buildSpeechToTextButton() {
    if (_isConvertingToText) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _primaryBrown.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _primaryBrown,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Converting voice to text...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.record_voice_over, size: 22),
        label: const Text(
          'Convert Voice to Text',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: _convertVoiceToText,
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
