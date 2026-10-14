import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/api_config.dart';
import '../../widgets/story_header_decoration.dart';
import '../../models/community_theme.dart';
import '../../services/community_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/published_content_signal.dart';

enum RecordingState { notRecorded, recording, recorded, playing }

class ShareStoryPage extends StatefulWidget {
  final Map<String, dynamic>? storyToEdit;

  final String? collaborationId;
  final bool embedded;
  final bool readOnly;
  final ValueChanged<Map<String, dynamic> Function()>? onFieldsReady;
  final String? communityId;
  final String? communityName;
  const ShareStoryPage({
    super.key,
    this.storyToEdit,
    this.collaborationId,
    this.embedded = false,
    this.readOnly = false,
    this.onFieldsReady,
    this.communityId,
    this.communityName,
  });

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
    'Food',
    'History',
    'Performing Arts',
    'Traditional Music',
    'Local Dialects',
    'Ayurveda & Healing',
  ];

  final List<String> _languages = ['Tamil', 'Sinhala', 'English'];

  String _selectedCategory = 'Traditional Story';
  final _categoryController = TextEditingController(text: 'Traditional Story');
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
  bool _aiSummaryAccepted = false;
  final _summaryController = TextEditingController();
  String get _aiSummary => _summaryController.text.trim();
  bool _summaryBusy = false;
  String? _summarySource;
  List<CulturalTheme> _communities = [];
  String? _communityId;
  String? _communityError;
  bool _communitiesLoading = true;
  String get _source =>
      '${_titleController.text}\n${_selectedLanguage}\n${_storyController.text}';

  // Step 4: Visibility
  String _visibility = 'Public'; // Public, YATHRA Community, Private

  // Audio & Speech Engines (Nullable & Safely Initialized)
  AudioRecorder? _audioRecorder;
  AudioPlayer? _audioPlayer;

  bool _isConvertingToText = false;
  bool _isSpeaking = false;
  final AudioPlayer _narrationPlayer = AudioPlayer();
  StreamSubscription? _narrationSubscription;
  int _narrationRequest = 0;
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
    _communityId = widget.communityId;
    _communityController.text = widget.communityName ?? "";
    _loadCommunities();
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
    _categoryController.addListener(_categoryEdited);
    _titleController.addListener(_sourceEdited);
    _storyController.addListener(_sourceEdited);
  }

  void _categoryEdited() {
    setState(() => _selectedCategory = _categoryController.text.trim());
  }

  void _sourceEdited() {
    if (_aiSummaryAccepted && _summarySource != _source)
      setState(() => _aiSummaryAccepted = false);
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
  }

  void _populateEditData() {
    if (widget.storyToEdit != null) {
      final story = widget.storyToEdit!;
      _bannerImage = story['bannerImage'] ?? story['imageUrl'];
      _additionalImages.addAll(
        List<String>.from(story['additionalImages'] ?? []),
      );
      _locationController.text = story['location'] ?? '';
      _communityId = story['communityId'];
      _communityController.text =
          story['communityName'] ?? story['community'] ?? '';
      _summaryController.text = story['aiSummary'] ?? '';
      _aiSummaryAccepted = story['summaryStatus'] == 'approved';
      if (_timePeriods.contains(story['timePeriod'])) {
        _selectedTimePeriod = story['timePeriod'];
      }
      _titleController.text = story['title'] ?? '';
      _storyController.text = story['storyText'] ?? '';
      if (story['category'] is String) {
        _selectedCategory = story['category'];
        _categoryController.text = _selectedCategory;
      }
      if (story['language'] != null && _languages.contains(story['language'])) {
        _selectedLanguage = story['language'];
      }
      _summarySource = _source;
      if (story['audioPath'] != null &&
          story['audioPath'].toString().isNotEmpty) {
        _recordedFilePath = story['audioPath'];
        _recordingState = RecordingState.recorded;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    try {
      _audioRecorder?.dispose();
    } catch (_) {}
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    _narrationRequest++;
    _narrationSubscription?.cancel();
    _narrationPlayer.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _titleController.dispose();
    _storyController.dispose();
    _locationController.dispose();
    _communityController.dispose();
    _peopleController.dispose();

    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      final items = await CommunityService().list();
      if (mounted)
        setState(() {
          _communities = items;
          _communitiesLoading = false;
          _communityError = null;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _communitiesLoading = false;
          _communityError = 'Could not load communities. Retry';
        });
    }
  }

  Future<void> _chooseCommunity() async {
    final result = await showModalBottomSheet<CulturalTheme>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, update) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .7,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Post to community',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search communities',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (text) =>
                          update(() => query = text.toLowerCase()),
                    ),
                    ListTile(
                      title: const Text('General feed'),
                      onTap: () {
                        setState(() {
                          _communityId = null;
                          _communityController.clear();
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                    Expanded(
                      child: ListView(
                        children: _communities
                            .where((c) => c.title.toLowerCase().contains(query))
                            .map(
                              (c) => ListTile(
                                title: Text(c.title),
                                subtitle: Text(
                                  c.isFollowing
                                      ? 'My community'
                                      : 'Follow this community to post here',
                                ),
                                enabled: c.isFollowing,
                                onTap: () => Navigator.pop(sheetContext, c),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (result != null && mounted)
      setState(() {
        _communityId = result.id;
        _communityController.text = result.title;
      });
  }

  Future<void> _generateSummary() async {
    if (_storyController.text.trim().isEmpty) {
      _showSnackBar('Write your story first.');
      return;
    }
    final source = _source;
    setState(() {
      _summaryBusy = true;
      _aiSummaryAccepted = false;
    });
    try {
      final result = await ApiService(baseUrl: _baseUrl).post(
        '/api/ai/story-summary',
        headers: await AuthService.authenticatedHeaders(),
        body: {
          if (widget.collaborationId != null)
            'connectionId': widget.collaborationId,
          if (widget.embedded) '_uploading': _isUploadingImages,
          'title': _titleController.text.trim(),
          'storyText': _storyController.text.trim(),
          'language': _selectedLanguage,
        },
        timeout: const Duration(seconds: 40),
      );
      if (!mounted) return;
      if (_source != source) {
        _showSnackBar('Story changed. Generate a new summary.');
        return;
      }
      setState(() {
        _summaryController.text = result['summary'];
        _summarySource = source;
      });
    } catch (_) {
      _showSnackBar(
        'AI summary is unavailable. Retry or skip and publish your story.',
      );
    } finally {
      if (mounted) setState(() => _summaryBusy = false);
    }
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

  // Transcribe the saved recording; never start a new microphone session.
  Future<void> _convertVoiceToText() async {
    if (_isConvertingToText) return;
    final path = _recordedFilePath;
    if (path == null || !File(path).existsSync()) {
      _showSnackBar('No recorded audio file found to convert.');
      return;
    }
    if (_isSpeaking) await _stopSpeaking();
    if (_recordingState == RecordingState.playing) await _stopPlayback();
    if (!mounted) return;
    final originalText = _storyController.text;
    setState(() => _isConvertingToText = true);
    final client = http.Client();
    try {
      if (await File(path).length() > 24 * 1024 * 1024) {
        throw Exception(
          'Recording is too large. Use a recording smaller than 24 MB.',
        );
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/ai/audio-transcription'),
      );
      final headers = await AuthService.authenticatedHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.fields['language'] = _selectedLanguage;
      if (widget.collaborationId != null) {
        request.fields['connectionId'] = widget.collaborationId!;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          path,
          contentType: MediaType('audio', 'mp4'),
        ),
      );
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 120));
      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Voice conversion failed. Please retry.',
        );
      }
      final text = data['text'];
      if (text is! String || text.trim().isEmpty) {
        throw Exception('No speech was found in this recording.');
      }
      if (!mounted || _recordedFilePath != path) return;
      // Preserve any typing done while the request was running.
      setState(() {
        _storyController.text = _storyController.text == originalText
            ? text.trim()
            : '${_storyController.text.trim()}\n\n${text.trim()}'.trim();
      });
      _showSnackBar(
        'Recording converted to text. Review and edit the story below.',
      );
    } on TimeoutException {
      if (mounted) _showSnackBar('Voice conversion timed out. Please retry.');
    } catch (error) {
      if (mounted)
        _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      client.close();
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

    if (_recordingState == RecordingState.recording) {
      _showSnackBar('Stop recording before reading the story.');
      return;
    }
    if (_recordingState == RecordingState.playing) await _stopPlayback();
    final requestId = ++_narrationRequest;
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    _showSnackBar('Preparing spoken story...');
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/story-speech'),
            headers: await AuthService.authenticatedHeaders(),
            body: jsonEncode({'text': text, 'language': _selectedLanguage}),
          )
          .timeout(const Duration(seconds: 120));
      if (!mounted || requestId != _narrationRequest) return;
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Story reading failed.');
      }
      await _narrationSubscription?.cancel();
      _narrationSubscription = _narrationPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
      await _narrationPlayer.play(
        BytesSource(response.bodyBytes, mimeType: 'audio/wav'),
      );
    } catch (error) {
      if (mounted && requestId == _narrationRequest) {
        setState(() => _isSpeaking = false);
        _showSnackBar(
          error is TimeoutException
              ? 'Story reading timed out. Please retry.'
              : error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _stopSpeaking() async {
    _narrationRequest++;
    await _narrationPlayer.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  Map<String, dynamic> _storyFields() {
    return {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'language': _selectedLanguage,
      'storyText': _storyController.text.trim(),
      'audioPath': _recordedFilePath,
      'bannerImage': _bannerImage,
      'additionalImages': _additionalImages,
      'location': _locationController.text.trim(),
      'timePeriod': _selectedTimePeriod,
      'communityId': _communityId ?? '',
      'visibility': _visibility,
      'aiSummary':
          _aiSummaryAccepted &&
              (_summarySource == null || _summarySource == _source)
          ? _aiSummary
          : null,
      'summaryStatus':
          _aiSummaryAccepted &&
              (_summarySource == null || _summarySource == _source) &&
              _aiSummary.isNotEmpty
          ? 'approved'
          : 'skipped',
    };
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

    if (_selectedCategory.trim().isEmpty) {
      _showSnackBar('Please enter a category.');
      return;
    }
    if (_isUploadingImages) {
      _showSnackBar('Please wait for your photos to finish uploading.');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _isPublishing = true);

    try {
      final body = _storyFields();

      http.Response response;

      if (_isEditing) {
        final Uri url = Uri.parse('$_baseUrl/api/stories/$_editingStoryId');
        response = await http
            .put(
              url,
              headers: await AuthService.authenticatedHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
      } else {
        final Uri url = Uri.parse('$_baseUrl/api/stories');
        response = await http
            .post(
              url,
              headers: await AuthService.authenticatedHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        PublishedContentSignal.notify();
        _showSnackBar(
          _isEditing ? 'Story updated!' : 'Story published successfully!',
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && navigator.canPop()) {
            navigator.pop(true);
          }
        });
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message']?.toString() ?? 'Could not save story. Please retry.',
        );
      }
    } catch (e) {
      _showSnackBar('Failed to save story. Please try again.');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.onFieldsReady?.call(_storyFields);
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepProgressHeader(),
          const SizedBox(height: 20),
          AbsorbPointer(
            absorbing: widget.readOnly,
            child: Column(
              children: [
                if (_currentStep == 0) _buildStep1MustDetails(),
                if (_currentStep == 1) _buildStep2OptionalContext(),
                if (_currentStep == 2) _buildStep3AiAssistance(),
                if (_currentStep == 3) _buildStep4ReviewAndPublish(),
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: _bgColor,
        foregroundColor: _darkBrown,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('Back'),
          style: TextButton.styleFrom(foregroundColor: _primaryBrown),
        ),
        centerTitle: true,
        title: Text(
          'YATHRA',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            fontFamily: 'Serif',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 110),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      right: -12,
                      top: -20,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: SizedBox(
                            width: 145,
                            height: 110,
                            child: CustomPaint(
                              painter: StoryHeaderDecoration(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 76),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit your story' : 'Share your story',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _darkBrown,
                              fontFamily: 'Serif',
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your memories matter. Write or speak in your own words.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Fields marked * are required.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
        _buildNumberedHeading(1, 'Story details'),
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
        DropdownMenu<String>(
          controller: _categoryController,
          expandedInsets: EdgeInsets.zero,
          menuHeight: 220,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          hintText: 'Type a category or choose a suggestion',
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFFFFFDF8)),
          ),
          dropdownMenuEntries: _categories
              .map(
                (category) =>
                    DropdownMenuEntry(value: category, label: category),
              )
              .toList(),
          onSelected: (value) {
            if (value != null) setState(() => _selectedCategory = value);
          },
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Choose a suggestion or enter your own category.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Story language *'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          value: _selectedLanguage,
          items: _languages,
          onChanged: (val) {
            if (val != null) setState(() => _selectedLanguage = val);
          },
        ),
        const SizedBox(height: 20),

        const Text(
          'Choose the language you will write or speak.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _buildNumberedHeading(2, 'Tell your story'),
        const SizedBox(height: 6),
        const Text(
          'Type below, or use your voice.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        _buildVoiceRecordingCard(),
        const SizedBox(height: 24),
        _buildSectionLabel('Your story *'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          maxLines: 6,
          style: const TextStyle(fontSize: 17, color: _darkBrown),
          decoration: _buildInputDecoration('Write your memories here...'),
        ),
        const SizedBox(height: 10),
        const Text(
          'You can correct any words after converting your recording.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildNumberedHeading(3, 'Listen and review'),
        const SizedBox(height: 6),
        const Text(
          'Hear the text you have written.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _primaryBrown.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primaryBrown.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.headphones, color: _primaryBrown, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Listen to your story',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTtsButton(),
              const SizedBox(height: 8),
              const Text(
                'Check the words before publishing.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
        if (!widget.embedded) ...[
          const SizedBox(height: 12),
          _buildSaveDraftButton(),
        ],
      ],
    );
  }

  Widget _buildNumberedHeading(int number, String title) => Row(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: _primaryBrown.withValues(alpha: 0.12),
        child: Text(
          '$number',
          style: const TextStyle(
            color: _darkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkBrown,
            fontFamily: 'Serif',
          ),
        ),
      ),
    ],
  );

  Widget _buildSaveDraftButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      onPressed: () => _showSnackBar('Story saved as draft!'),
      icon: const Icon(Icons.save_outlined),
      label: const Text(
        'Save Draft',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBrown,
        side: const BorderSide(color: _primaryBrown, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _communityController.text.isEmpty
                ? 'General feed'
                : _communityController.text,
          ),
          subtitle: const Text('Select a community you follow'),
          trailing: const Icon(Icons.search),
          onTap: widget.embedded || _communitiesLoading
              ? null
              : _chooseCommunity,
        ),
        if (_communitiesLoading) const LinearProgressIndicator(),
        if (_communityError != null)
          TextButton(
            onPressed: _loadCommunities,
            child: Text(_communityError!),
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
  Widget _buildStep3AiAssistance() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'YATHRA AI Summary',
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
          color: _darkBrown,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Create an optional short preview for readers. Your original story stays unchanged.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _summaryBusy ? null : _generateSummary,
        icon: const Icon(Icons.auto_awesome),
        label: Text(
          _summaryBusy
              ? 'Generating...'
              : _aiSummary.isEmpty
              ? 'Generate summary'
              : 'Regenerate summary',
        ),
      ),
      if (_summaryBusy) const LinearProgressIndicator(),
      if (_summarySource != null && _summarySource != _source)
        const Text(
          'Your story changed. Review this preview before publishing.',
        ),
      const SizedBox(height: 16),
      TextField(
        controller: _summaryController,
        maxLength: 700,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Story preview',
          hintText: 'Generate or write a short preview',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _aiSummaryAccepted = false),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('I reviewed and approve this summary'),
        value: _aiSummaryAccepted,
        onChanged: _aiSummary.isEmpty || _summaryBusy
            ? null
            : (value) => setState(() {
                _aiSummaryAccepted = value ?? false;
                _summarySource = _source;
              }),
      ),
      const Text(
        'Without an approved summary, readers see an excerpt from your story.',
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _summaryBusy ? null : () => setState(() => _currentStep = 3),
        child: const Text('Next: Review & Publish'),
      ),
      TextButton(
        onPressed: () => setState(() {
          _aiSummaryAccepted = false;
          _currentStep = 3;
        }),
        child: const Text('Skip summary'),
      ),
    ],
  );

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

        if (!widget.embedded) ...[
          _buildSectionLabel('Story Visibility'),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            value: _visibility,
            items: ['Public', 'YATHRA Community', 'Private'],
            onChanged: (val) {
              if (val != null) setState(() => _visibility = val);
            },
          ),
        ],
        const SizedBox(height: 32),

        // Project actions are supplied by the workspace.
        if (!widget.embedded)
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

  Widget _buildNotRecordedState() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.mic, color: _primaryBrown, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speak to write',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkBrown,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Record your voice, then convert it to editable text.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic),
          label: const Text(
            'Start recording',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Speak in $_selectedLanguage. Tap Stop recording when you finish.',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  );

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
          'Convert Recording to Text',
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
