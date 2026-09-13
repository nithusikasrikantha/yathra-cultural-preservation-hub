import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

enum RecordingState {
  notRecorded,
  recording,
  recorded,
  playing,
}

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

  // Audio Recording & Playback state
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  RecordingState _recordingState = RecordingState.notRecorded;
  String? _recordedFilePath;
  int _recordingSeconds = 0;
  Timer? _timer;
  StreamSubscription? _playerStateSubscription;

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.recorded;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
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

  // 1. Start Recording
  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showSnackBar('Microphone permission is required to record your voice.');
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/story_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _recordingSeconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
        }
      });

      setState(() {
        _recordingState = RecordingState.recording;
        _recordedFilePath = filePath;
      });
    } catch (e) {
      _showSnackBar('Failed to start voice recording. Please try again.');
    }
  }

  // 2. Stop Recording
  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final String? path = await _audioRecorder.stop();

      if (path == null || path.isEmpty) {
        _showSnackBar('Failed to save recorded audio.');
        setState(() {
          _recordingState = RecordingState.notRecorded;
        });
        return;
      }

      setState(() {
        _recordedFilePath = path;
        _recordingState = RecordingState.recorded;
      });
    } catch (e) {
      _showSnackBar('Failed to stop recording cleanly.');
      setState(() {
        _recordingState = RecordingState.recorded;
      });
    }
  }

  // 3. Play Recording
  Future<void> _startPlayback() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) {
      _showSnackBar('No recorded audio file found to play.');
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      setState(() {
        _recordingState = RecordingState.playing;
      });
    } catch (e) {
      _showSnackBar('Failed to play recorded audio.');
    }
  }

  // 4. Stop Playback
  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _recordingState = RecordingState.recorded;
      });
    } catch (e) {
      _showSnackBar('Failed to stop audio playback.');
    }
  }

  // 5. Re-record
  Future<void> _reRecord() async {
    try {
      if (_recordingState == RecordingState.playing) {
        await _audioPlayer.stop();
      } else if (_recordingState == RecordingState.recording) {
        _timer?.cancel();
        await _audioRecorder.stop();
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
                initialValue: _selectedCategory,
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
                initialValue: _selectedLanguage,
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

              // 5. Voice Story Section (Interactive Voice Recording for YTH-24)
              _buildSectionLabel('Voice Story'),
              const SizedBox(height: 8),
              _buildVoiceRecordingCard(),
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

  Widget _buildVoiceRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _primaryBrown.withValues(alpha: 0.3), width: 1.5),
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

  // State: Not Recorded
  Widget _buildNotRecordedState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryBrown.withValues(alpha: 0.1),
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
          onPressed: _startRecording,
          child: const Text(
            'Record',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // State: Recording
  Widget _buildRecordingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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

  // State: Recorded
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
      ],
    );
  }

  // State: Playing
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
      ],
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
