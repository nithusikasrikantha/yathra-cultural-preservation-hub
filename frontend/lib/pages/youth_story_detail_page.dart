import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';

class YouthStoryDetailPage extends StatefulWidget {
  const YouthStoryDetailPage({super.key, required this.storyId});

  final String storyId;

  @override
  State<YouthStoryDetailPage> createState() => _YouthStoryDetailPageState();
}

class _YouthStoryDetailPageState extends State<YouthStoryDetailPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  final StoryService _storyService = const StoryService();

  Story? _story;
  bool _isLoading = true;
  bool _isNotFound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    setState(() {
      _isLoading = true;
      _isNotFound = false;
      _errorMessage = null;
    });

    try {
      final story = await _storyService.fetchStoryById(widget.storyId);
      if (!mounted) return;

      setState(() {
        _story = story;
        _isLoading = false;
      });
    } on StoryNotFoundException {
      if (!mounted) return;

      setState(() {
        _story = null;
        _isNotFound = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _story = null;
        _errorMessage = 'We could not load this story. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Story Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Semantics(
          label: 'Loading story details',
          child: CircularProgressIndicator(color: _primaryBrown),
        ),
      );
    }

    if (_isNotFound) {
      return _buildMessageState(
        icon: Icons.find_in_page_outlined,
        title: 'Story unavailable',
        message: 'This story may have been removed or is no longer available.',
        actionLabel: 'Go back',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load story',
        message: _errorMessage!,
        actionLabel: 'Retry',
        onPressed: _loadStory,
      );
    }

    final story = _story;
    if (story == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          child: Card(
            color: Colors.white,
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailChip(
                        icon: Icons.category_outlined,
                        label: story.category,
                      ),
                      _DetailChip(
                        icon: Icons.language_outlined,
                        label: story.language,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    story.title,
                    style: const TextStyle(
                      color: _darkBrown,
                      fontSize: 28,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (story.createdAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Shared ${_formatDate(story.createdAt!)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  if (story.tags.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        color: _darkBrown,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: story.tags
                          .map((tag) => _TagChip(label: tag))
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const Divider(),
                  const SizedBox(height: 18),
                  Text(
                    story.storyText,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      height: 1.65,
                    ),
                  ),
                  if (story.audioPath != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E5D5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.mic_none_outlined, color: _primaryBrown),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Audio is available for this story, but shared playback is not available yet.',
                              style: TextStyle(
                                color: _darkBrown,
                                fontSize: 16,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Icon(icon, size: 64, color: _primaryBrown),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _darkBrown,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(_isNotFound ? Icons.arrow_back : Icons.refresh),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E5D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF6B4226)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A2C1A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6B4226)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A2C1A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
