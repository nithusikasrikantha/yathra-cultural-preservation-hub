import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import '../widgets/youth_story_card.dart';
import 'youth_story_detail_page.dart';

class YouthHomePage extends StatefulWidget {
  const YouthHomePage({
    super.key,
    required this.profileComplete,
    required this.onExplore,
    required this.onProfile,
  });

  final bool? profileComplete;
  final VoidCallback onExplore;
  final VoidCallback onProfile;

  @override
  State<YouthHomePage> createState() => _YouthHomePageState();
}

class _YouthHomePageState extends State<YouthHomePage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const List<String> _categories = [
    'Traditional Story',
    'Recipe',
    'Song',
    'Local History',
  ];

  final StoryService _storyService = const StoryService();
  final BookmarkService _bookmarkService = BookmarkService.instance;
  List<Story> _stories = const [];
  bool _isLoading = true;
  bool _bookmarksReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookmarkService.addListener(_onBookmarksChanged);
    _load();
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_onBookmarksChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _bookmarkService.load();
      final page = await _storyService.fetchStories(page: 1, limit: 4);
      if (!mounted) return;
      setState(() {
        _bookmarksReady = true;
        _stories = page.items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Recent cultural stories could not be loaded.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark(String storyId) async {
    try {
      await _bookmarkService.toggle(storyId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The bookmark could not be updated.')),
      );
    }
  }

  void _openStory(String storyId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => YouthStoryDetailPage(storyId: storyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'YATHRA',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(letterSpacing: 2),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/youth-saved'),
            tooltip: 'Saved stories',
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Text(
              'Discover your cultural heritage',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stories, traditions, and knowledge shared by the community.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (widget.profileComplete == false) ...[
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFFF1E5D5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: _primaryBrown),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete your profile',
                              style: TextStyle(
                                color: _darkBrown,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Add your interests to personalize your journey.',
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onProfile,
                        child: const Text('Complete Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            InkWell(
              onTap: widget.onExplore,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Search stories, folklore, crafts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.arrow_forward),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: const Text(
                  'Search stories, folklore, crafts...',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Explore categories',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (category) => ActionChip(
                      avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: Text(category),
                      onPressed: widget.onExplore,
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Latest stories',
                    style: TextStyle(
                      color: _darkBrown,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onExplore,
                  child: const Text('Explore more'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: CircularProgressIndicator(color: _primaryBrown),
                ),
              )
            else if (_error != null)
              _MessageCard(message: _error!, onRetry: _load)
            else if (_stories.isEmpty)
              const _MessageCard(
                message: 'No cultural stories have been shared yet.',
              )
            else
              for (final story in _stories)
                YouthStoryCard(
                  story: story,
                  onTap: () => _openStory(story.id),
                  isBookmarked:
                      _bookmarksReady &&
                      _bookmarkService.isBookmarked(story.id),
                  onBookmark: _bookmarksReady
                      ? () => _toggleBookmark(story.id)
                      : null,
                ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.auto_stories_outlined, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
