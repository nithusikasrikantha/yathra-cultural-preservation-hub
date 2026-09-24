import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import 'youth_story_detail_page.dart';

class YouthSavedPostsPage extends StatefulWidget {
  const YouthSavedPostsPage({super.key});

  @override
  State<YouthSavedPostsPage> createState() => _YouthSavedPostsPageState();
}

class _YouthSavedPostsPageState extends State<YouthSavedPostsPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  final BookmarkService _bookmarkService = BookmarkService.instance;
  final StoryService _storyService = const StoryService();
  final Map<String, Story> _storiesById = {};
  final Set<String> _missingIds = {};
  final Set<String> _failedIds = {};

  bool _isLoading = true;
  String? _loadError;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bookmarkService.addListener(_handleBookmarksChanged);
    _loadSavedStories();
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_handleBookmarksChanged);
    super.dispose();
  }

  void _handleBookmarksChanged() {
    _loadSavedStories();
  }

  Future<void> _loadSavedStories() async {
    final requestGeneration = ++_requestGeneration;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await _bookmarkService.load();
      if (!mounted || requestGeneration != _requestGeneration) return;

      final ids = List<String>.of(_bookmarkService.storyIds);
      if (ids.isEmpty) {
        setState(() {
          _storiesById.clear();
          _missingIds.clear();
          _failedIds.clear();
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait(
        ids.map((id) async {
          try {
            final story = await _storyService.fetchStoryById(id);
            return _SavedStoryResult.available(id, story);
          } on StoryNotFoundException {
            return _SavedStoryResult.missing(id);
          } catch (_) {
            return _SavedStoryResult.failed(id);
          }
        }),
      );
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _storiesById
          ..clear()
          ..addEntries(
            results
                .where((result) => result.story != null)
                .map((result) => MapEntry(result.id, result.story!)),
          );
        _missingIds
          ..clear()
          ..addAll(
            results
                .where((result) => result.isMissing)
                .map((result) => result.id),
          );
        _failedIds
          ..clear()
          ..addAll(
            results
                .where((result) => result.hasFailed)
                .map((result) => result.id),
          );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _requestGeneration) return;
      setState(() {
        _loadError = 'Saved stories could not be loaded. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(String storyId) async {
    try {
      await _bookmarkService.remove(storyId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The bookmark could not be removed.')),
      );
    }
  }

  Future<void> _openStory(String storyId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => YouthStoryDetailPage(storyId: storyId),
      ),
    );
    if (mounted) {
      _loadSavedStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Saved Posts',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
      return _buildMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load saved posts',
        message: _loadError!,
        actionLabel: 'Retry',
        onPressed: _loadSavedStories,
      );
    }

    final ids = _bookmarkService.storyIds;
    if (ids.isEmpty) {
      return _buildMessageState(
        icon: Icons.bookmark_border,
        title: 'No saved posts yet',
        message: 'Stories you bookmark will appear here.',
        actionLabel: 'Go back',
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Text(
              'Your saved cultural stories',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bookmarks are stored on this device.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 20),
            for (final id in ids)
              if (_storiesById[id] case final story?)
                _SavedStoryCard(
                  story: story,
                  onOpen: () => _openStory(id),
                  onRemove: () => _removeBookmark(id),
                )
              else if (_missingIds.contains(id))
                _UnavailableBookmarkCard(
                  message:
                      'This saved story was removed or is no longer available.',
                  actionLabel: 'Remove bookmark',
                  onPressed: () => _removeBookmark(id),
                )
              else if (_failedIds.contains(id))
                _UnavailableBookmarkCard(
                  message: 'This saved story could not be loaded right now.',
                  actionLabel: 'Retry',
                  onPressed: _loadSavedStories,
                ),
          ],
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
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedStoryResult {
  const _SavedStoryResult._({
    required this.id,
    this.story,
    this.isMissing = false,
    this.hasFailed = false,
  });

  factory _SavedStoryResult.available(String id, Story story) {
    return _SavedStoryResult._(id: id, story: story);
  }

  factory _SavedStoryResult.missing(String id) {
    return _SavedStoryResult._(id: id, isMissing: true);
  }

  factory _SavedStoryResult.failed(String id) {
    return _SavedStoryResult._(id: id, hasFailed: true);
  }

  final String id;
  final Story? story;
  final bool isMissing;
  final bool hasFailed;
}

class _SavedStoryCard extends StatelessWidget {
  const _SavedStoryCard({
    required this.story,
    required this.onOpen,
    required this.onRemove,
  });

  final Story story;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: _YouthSavedPostsPageState._darkBrown,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${story.category} • ${story.language}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      story.storyText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove bookmark',
                icon: const Icon(
                  Icons.bookmark,
                  color: _YouthSavedPostsPageState._primaryBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableBookmarkCard extends StatelessWidget {
  const _UnavailableBookmarkCard({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
