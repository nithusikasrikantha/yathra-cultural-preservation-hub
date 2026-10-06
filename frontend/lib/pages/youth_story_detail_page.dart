import 'package:flutter/material.dart';

import '../data/elder_story_engagement_demo_data.dart';
import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import '../services/term_explanation_service.dart';
import '../services/translation_service.dart';
import '../services/vocabulary_translation_service.dart';
import '../services/youth_dummy_content_store.dart';

class YouthStoryDetailPage extends StatefulWidget {
  const YouthStoryDetailPage({
    super.key,
    required this.storyId,
    this.preloadedStory,
    this.userRole = 'youth',
  });

  final String storyId;
  final Story? preloadedStory;
  final String userRole;

  @override
  State<YouthStoryDetailPage> createState() => _YouthStoryDetailPageState();
}

class _YouthStoryDetailPageState extends State<YouthStoryDetailPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const List<String> _translationLanguages = [
    'Tamil',
    'Sinhala',
    'English',
  ];

  final StoryService _storyService = const StoryService();
  final TranslationService _translationService = TranslationService();
  final TermExplanationService _termExplanationService =
      TermExplanationService();
  final VocabularyTranslationService _vocabularyTranslationService =
      VocabularyTranslationService();
  final BookmarkService _bookmarkService = BookmarkService.instance;
  final YouthDummyContentStore _dummyStore = YouthDummyContentStore.instance;

  bool get _isDummyStory =>
      widget.preloadedStory != null && _dummyStore.isDummyId(widget.storyId);
  bool get _isElder => widget.userRole == 'elder';

  Story? _story;
  bool _bookmarksReady = false;
  bool _isLoading = true;
  bool _isNotFound = false;
  String? _errorMessage;
  StoryTranslation? _translation;
  bool _isTranslating = false;
  bool _showTranslation = false;
  String? _translationError;
  String _selectedTargetLanguage = 'Tamil';

  @override
  void initState() {
    super.initState();
    _attachStoryListeners();
    _loadStory();
  }

  @override
  void didUpdateWidget(covariant YouthStoryDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId == widget.storyId &&
        oldWidget.preloadedStory == widget.preloadedStory &&
        oldWidget.userRole == widget.userRole) {
      return;
    }

    _detachStoryListeners(oldWidget);
    _attachStoryListeners();
    _loadStory();
  }

  @override
  void dispose() {
    _detachStoryListeners(widget);
    super.dispose();
  }

  bool _isDummyFor(YouthStoryDetailPage page) =>
      page.preloadedStory != null && _dummyStore.isDummyId(page.storyId);

  void _attachStoryListeners() {
    if (_isElder) {
      _bookmarksReady = false;
    } else if (_isDummyStory) {
      _dummyStore.addListener(_handleBookmarksChanged);
      _bookmarksReady = true;
    } else {
      _bookmarkService.addListener(_handleBookmarksChanged);
      _bookmarksReady = false;
      _initializeBookmarks();
    }
  }

  void _detachStoryListeners(YouthStoryDetailPage page) {
    if (page.userRole == 'elder') return;
    if (_isDummyFor(page)) {
      _dummyStore.removeListener(_handleBookmarksChanged);
    } else {
      _bookmarkService.removeListener(_handleBookmarksChanged);
    }
  }

  Future<void> _initializeBookmarks() async {
    try {
      await _bookmarkService.load();
      if (!mounted) return;
      setState(() {
        _bookmarksReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookmarksReady = false;
      });
    }
  }

  void _handleBookmarksChanged() {
    if (!mounted) return;
    setState(() {
      _bookmarksReady = _isDummyStory || _bookmarkService.isLoaded;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isDummyStory) {
      _dummyStore.toggleBookmark(widget.storyId);
      return;
    }
    try {
      await _bookmarkService.toggle(widget.storyId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The bookmark could not be updated.')),
      );
    }
  }

  Future<void> _loadStory() async {
    _resetTranslationState(
      sourceLanguage: _isDummyStory ? widget.preloadedStory?.language : null,
    );
    if (_isDummyStory) {
      setState(() {
        _story = widget.preloadedStory;
        _isLoading = false;
        _isNotFound = false;
        _errorMessage = null;
      });
      return;
    }
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
        _selectedTargetLanguage = _defaultTargetLanguage(story.language);
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

  void _resetTranslationState({String? sourceLanguage}) {
    _translation = null;
    _showTranslation = false;
    _isTranslating = false;
    _translationError = null;
    if (sourceLanguage != null) {
      _selectedTargetLanguage = _defaultTargetLanguage(sourceLanguage);
    }
  }

  String _defaultTargetLanguage(String sourceLanguage) {
    final normalizedSource = sourceLanguage.trim().toLowerCase();
    return _translationLanguages.firstWhere(
      (language) => language.toLowerCase() != normalizedSource,
      orElse: () => 'English',
    );
  }

  bool _isSourceLanguage(String language) =>
      language.toLowerCase() == _story?.language.trim().toLowerCase();

  void _selectTargetLanguage(String language) {
    if (_selectedTargetLanguage == language || _isTranslating) return;
    setState(() {
      _selectedTargetLanguage = language;
      _translation = null;
      _showTranslation = false;
      _translationError = null;
    });
  }

  Future<void> _translateStory() async {
    if (_isTranslating) return;

    if (_translation != null) {
      setState(() => _showTranslation = true);
      return;
    }

    final story = _story;
    if (story == null) return;

    setState(() {
      _isTranslating = true;
      _translationError = null;
    });
    try {
      final translation = _isDummyStory
          ? await _translationService.translateDemoStory(
              storyId: story.id,
              storyText: story.storyText,
              sourceLanguage: story.language,
              targetLanguage: _selectedTargetLanguage,
            )
          : await _translationService.translateStory(
              storyId: widget.storyId,
              targetLanguage: _selectedTargetLanguage,
            );
      if (!mounted) return;
      setState(() {
        _translation = translation;
        _showTranslation = true;
        _isTranslating = false;
        _translationError = null;
      });
    } catch (error) {
      if (!mounted) return;
      const message =
          'We could not translate this story right now. Please try again.';
      setState(() {
        _isTranslating = false;
        _translationError = message;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(message)));
    }
  }

  Future<void> _openTermExplanation() async {
    final story = _story;
    if (story == null || _isElder) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TermExplanationSheet(
        service: _termExplanationService,
        storyId: story.id,
        isDemo: _isDummyStory,
        initialLanguage: _selectedTargetLanguage,
      ),
    );
  }

  Future<void> _openVocabularyTranslation() async {
    final story = _story;
    if (story == null || _isElder) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _VocabularyTranslationSheet(
        service: _vocabularyTranslationService,
        storyId: story.id,
        isDemo: _isDummyStory,
        initialLanguage: _selectedTargetLanguage,
      ),
    );
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
        actions: [
          if (!_isElder)
            IconButton(
              onPressed: _story != null && _bookmarksReady
                  ? _toggleBookmark
                  : null,
              tooltip: _isBookmarked ? 'Remove bookmark' : 'Save story',
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  bool get _isBookmarked => _isDummyStory
      ? _dummyStore.isBookmarked(widget.storyId)
      : _bookmarkService.isBookmarked(widget.storyId);

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
                children: _isElder
                    ? _buildElderStoryContent(story)
                    : _buildYouthStoryContent(story),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildYouthStoryContent(Story story) {
    final metadata = _isDummyStory ? _dummyStore.metadataFor(story.id) : null;
    return [
      if (metadata != null) ...[
        _buildDemoHero(metadata, story),
        const SizedBox(height: 18),
        _buildDemoSource(metadata),
        const SizedBox(height: 18),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DetailChip(icon: Icons.category_outlined, label: story.category),
          _DetailChip(icon: Icons.language_outlined, label: story.language),
          if (story.createdAt != null)
            _DetailChip(
              icon: Icons.calendar_today_outlined,
              label: _formatDate(story.createdAt!),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        story.title,
        style: const TextStyle(
          color: _darkBrown,
          fontFamily: 'Serif',
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (story.tags.isNotEmpty) ...[
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: story.tags
              .map((tag) => _TagChip(label: tag))
              .toList(growable: false),
        ),
      ],
      const SizedBox(height: 24),
      if (_translation != null) ...[
        _buildTranslationSelector(),
        const SizedBox(height: 18),
      ],
      _buildStoryBody(story),
      if (story.audioPath != null) ...[
        const SizedBox(height: 20),
        _buildAudioAvailability(),
      ],
      const SizedBox(height: 20),
      _buildTranslationTools(),
      if (metadata != null) ...[
        const SizedBox(height: 20),
        _buildYouthEngagement(metadata),
      ],
    ];
  }

  List<Widget> _buildElderStoryContent(Story story) => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DetailChip(icon: Icons.category_outlined, label: story.category),
        _DetailChip(icon: Icons.language_outlined, label: story.language),
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
        style: const TextStyle(color: Colors.black54, fontSize: 15),
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
      style: const TextStyle(color: Colors.black87, fontSize: 18, height: 1.65),
    ),
    if (story.audioPath != null) ...[
      const SizedBox(height: 28),
      _buildAudioAvailability(),
    ],
    const SizedBox(height: 26),
    const Divider(),
    const SizedBox(height: 12),
    _ElderEngagementFooter(
      engagement: ElderStoryEngagementDemoData.forStory(widget.storyId),
    ),
  ];

  Widget _buildDemoHero(YouthDummyStoryMetadata metadata, Story story) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        metadata.imageAssetPath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: 200,
          color: const Color(0xFFF1E5D5),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: _primaryBrown,
              ),
              const SizedBox(height: 8),
              Text(
                story.category,
                style: const TextStyle(
                  color: _darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSource(YouthDummyStoryMetadata metadata) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primaryBrown.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline_rounded, color: _primaryBrown),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metadata.sourceName,
                style: const TextStyle(
                  color: _darkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metadata.relativeTime,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryBody(Story story) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBrown.withValues(alpha: 0.1)),
      ),
      child: Text(
        _showTranslation
            ? _translation?.translatedText ?? story.storyText
            : story.storyText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildAudioAvailability() {
    return Container(
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
    );
  }

  Widget _buildTranslationSelector() {
    final translation = _translation!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E5D5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading in ${translation.targetLanguage}',
            style: const TextStyle(
              color: _darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Original')),
              ButtonSegment(value: true, label: Text('Translation')),
            ],
            selected: {_showTranslation},
            onSelectionChanged: (selection) =>
                setState(() => _showTranslation = selection.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(_darkBrown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouthEngagement(YouthDummyStoryMetadata metadata) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryBrown.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ReadOnlyMetric(
              icon: Icons.favorite_border_rounded,
              count: metadata.likeCount,
              label: 'Likes',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: _primaryBrown.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _ReadOnlyMetric(
              icon: Icons.chat_bubble_outline_rounded,
              count: metadata.commentCount,
              label: 'Comments',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationTools() {
    final translation = _translation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E5D5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryBrown.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI LEARNING TOOLS',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Translate this story to',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _translationLanguages
                .map((language) {
                  final isSource = _isSourceLanguage(language);
                  return ChoiceChip(
                    label: Text(language),
                    selected: _selectedTargetLanguage == language,
                    onSelected: isSource || _isTranslating
                        ? null
                        : (_) => _selectTargetLanguage(language),
                    selectedColor: _primaryBrown,
                    backgroundColor: const Color(0xFFFFFDF8),
                    disabledColor: Colors.black.withValues(alpha: 0.06),
                    labelStyle: TextStyle(
                      color: _selectedTargetLanguage == language
                          ? Colors.white
                          : isSource
                          ? Colors.black38
                          : _darkBrown,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSource
                          ? Colors.black12
                          : _primaryBrown.withValues(alpha: 0.3),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          if (_story != null) ...[
            const SizedBox(height: 7),
            Text(
              '${_story!.language} is the original story language.',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          if (translation != null)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _primaryBrown),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Translation ready in ${translation.targetLanguage}.',
                    style: const TextStyle(
                      color: _darkBrown,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _isTranslating ? null : _translateStory,
              icon: _isTranslating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate_rounded),
              label: Text(_isTranslating ? 'Translating…' : 'Translate Story'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
            if (_translationError != null) ...[
              const SizedBox(height: 12),
              Text(
                _translationError!,
                style: const TextStyle(color: _darkBrown, height: 1.35),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isTranslating ? null : _translateStory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Divider(color: _primaryBrown.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          const Text(
            'Learn about a word or phrase from this story.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openTermExplanation,
            icon: const Icon(Icons.lightbulb_outline_rounded),
            label: const Text('Explain Cultural Term'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBrown,
              side: const BorderSide(color: _primaryBrown),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openVocabularyTranslation,
            icon: const Icon(Icons.text_fields_rounded),
            label: const Text('Translate Word / Phrase'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBrown,
              side: const BorderSide(color: _primaryBrown),
            ),
          ),
        ],
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

class _VocabularyTranslationSheet extends StatefulWidget {
  const _VocabularyTranslationSheet({
    required this.service,
    required this.storyId,
    required this.isDemo,
    required this.initialLanguage,
  });

  final VocabularyTranslationService service;
  final String storyId;
  final bool isDemo;
  final String initialLanguage;

  @override
  State<_VocabularyTranslationSheet> createState() =>
      _VocabularyTranslationSheetState();
}

class _VocabularyTranslationSheetState
    extends State<_VocabularyTranslationSheet> {
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const List<String> _languages = ['Tamil', 'Sinhala', 'English'];

  final TextEditingController _textController = TextEditingController();
  late String _selectedLanguage;
  VocabularyTranslation? _translation;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languages.contains(widget.initialLanguage)
        ? widget.initialLanguage
        : 'English';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    if (_isLoading) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Enter a word or short phrase.');
      return;
    }
    if (text.length > 100) {
      setState(() => _errorMessage = 'Use 100 characters or fewer.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _translation = null;
    });
    try {
      final translation = await widget.service.translate(
        text: text,
        targetLanguage: _selectedLanguage,
        storyId: widget.storyId,
        isDemo: widget.isDemo,
      );
      if (!mounted) return;
      setState(() {
        _translation = translation;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'We could not translate this word or phrase right now. Please try again.';
      });
    }
  }

  void _startAnotherTranslation() {
    setState(() {
      _textController.clear();
      _translation = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _primaryBrown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Translate Word / Phrase',
                      style: TextStyle(
                        color: _darkBrown,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Translate a specific word or short phrase using this story for context.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _textController,
                enabled: !_isLoading,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _translate(),
                decoration: InputDecoration(
                  labelText: 'Enter a word or short phrase from this story',
                  hintText: 'Example: harvest festival',
                  filled: true,
                  fillColor: const Color(0xFFFFFDF8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _primaryBrown,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Target language',
                style: TextStyle(
                  color: _darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages
                    .map(
                      (language) => ChoiceChip(
                        label: Text(language),
                        selected: _selectedLanguage == language,
                        onSelected: _isLoading
                            ? null
                            : (_) => setState(() {
                                _selectedLanguage = language;
                                _translation = null;
                                _errorMessage = null;
                              }),
                        selectedColor: _primaryBrown,
                        backgroundColor: const Color(0xFFFFFDF8),
                        labelStyle: TextStyle(
                          color: _selectedLanguage == language
                              ? Colors.white
                              : _darkBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _translate,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate_rounded),
                  label: Text(_isLoading ? 'Translating…' : 'Translate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _primaryBrown,
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(_errorMessage!)),
                      if (_textController.text.trim().isNotEmpty)
                        TextButton(
                          onPressed: _isLoading ? null : _translate,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              ],
              if (_translation != null) ...[
                const SizedBox(height: 18),
                _VocabularyTranslationCard(translation: _translation!),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _startAnotherTranslation,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Translate another word'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabularyTranslationCard extends StatelessWidget {
  const _VocabularyTranslationCard({required this.translation});

  final VocabularyTranslation translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x336B4226)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Original', translation.original),
          _section('Translation', translation.translatedText),
          _section('Contextual Meaning', translation.contextualMeaning),
          if (translation.example.isNotEmpty)
            _section('Use In Sentence', translation.example, isLast: true),
        ],
      ),
    );
  }

  Widget _section(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B4226),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4A2C1A),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermExplanationSheet extends StatefulWidget {
  const _TermExplanationSheet({
    required this.service,
    required this.storyId,
    required this.isDemo,
    required this.initialLanguage,
  });

  final TermExplanationService service;
  final String storyId;
  final bool isDemo;
  final String initialLanguage;

  @override
  State<_TermExplanationSheet> createState() => _TermExplanationSheetState();
}

class _TermExplanationSheetState extends State<_TermExplanationSheet> {
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const List<String> _languages = ['Tamil', 'Sinhala', 'English'];

  final TextEditingController _termController = TextEditingController();
  late String _selectedLanguage;
  CulturalTermExplanation? _explanation;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languages.contains(widget.initialLanguage)
        ? widget.initialLanguage
        : 'English';
  }

  @override
  void dispose() {
    _termController.dispose();
    super.dispose();
  }

  Future<void> _explain() async {
    if (_isLoading) return;
    final term = _termController.text.trim();
    if (term.isEmpty) {
      setState(() => _errorMessage = 'Enter a cultural word or phrase.');
      return;
    }
    if (term.length > 80) {
      setState(() => _errorMessage = 'Use 80 characters or fewer.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _explanation = null;
    });
    try {
      final explanation = await widget.service.explainTerm(
        term: term,
        targetLanguage: _selectedLanguage,
        storyId: widget.storyId,
        isDemo: widget.isDemo,
      );
      if (!mounted) return;
      setState(() {
        _explanation = explanation;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'We could not explain this term right now. Please try again.';
      });
    }
  }

  void _startAnotherTerm() {
    setState(() {
      _termController.clear();
      _explanation = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _primaryBrown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Explain Cultural Term',
                      style: TextStyle(
                        color: _darkBrown,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Learn the meaning and cultural context of a word or phrase.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _termController,
                enabled: !_isLoading,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _explain(),
                decoration: InputDecoration(
                  labelText: 'Enter a cultural word or phrase',
                  hintText: 'Example: Thai Pongal, Kolam, Koothu',
                  filled: true,
                  fillColor: const Color(0xFFFFFDF8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _primaryBrown,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explanation language',
                style: TextStyle(
                  color: _darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages
                    .map(
                      (language) => ChoiceChip(
                        label: Text(language),
                        selected: _selectedLanguage == language,
                        onSelected: _isLoading
                            ? null
                            : (_) => setState(() {
                                _selectedLanguage = language;
                                _explanation = null;
                                _errorMessage = null;
                              }),
                        selectedColor: _primaryBrown,
                        backgroundColor: const Color(0xFFFFFDF8),
                        labelStyle: TextStyle(
                          color: _selectedLanguage == language
                              ? Colors.white
                              : _darkBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _explain,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_isLoading ? 'Explaining…' : 'Explain Term'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _primaryBrown,
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(_errorMessage!)),
                      if (_termController.text.trim().isNotEmpty)
                        TextButton(
                          onPressed: _isLoading ? null : _explain,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              ],
              if (_explanation != null) ...[
                const SizedBox(height: 18),
                _TermExplanationCard(explanation: _explanation!),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _startAnotherTerm,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Explain another term'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TermExplanationCard extends StatelessWidget {
  const _TermExplanationCard({required this.explanation});

  final CulturalTermExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x336B4226)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Term', explanation.term),
          _section('Meaning', explanation.meaning),
          _section('Cultural Context', explanation.culturalContext),
          if (explanation.example.isNotEmpty)
            _section('Example', explanation.example, isLast: true),
        ],
      ),
    );
  }

  Widget _section(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B4226),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4A2C1A),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ElderEngagementFooter extends StatelessWidget {
  const _ElderEngagementFooter({required this.engagement});

  final ElderStoryEngagement engagement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${engagement.likes} likes, ${engagement.comments} comments, ${engagement.saves} saves',
      child: Row(
        children: [
          Expanded(
            child: _metric(
              Icons.favorite_border_rounded,
              engagement.likes,
              'Likes',
            ),
          ),
          Expanded(
            child: _metric(
              Icons.chat_bubble_outline_rounded,
              engagement.comments,
              'Comments',
            ),
          ),
          Expanded(
            child: _metric(
              Icons.bookmark_border_rounded,
              engagement.saves,
              'Saves',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, int count, String label) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF6B4226)),
          const SizedBox(height: 4),
          Text(
            '$count $label',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A2C1A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyMetric extends StatelessWidget {
  const _ReadOnlyMetric({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count $label',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: const Color(0xFF6B4226)),
            const SizedBox(height: 5),
            Text(
              '$count $label',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4A2C1A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
