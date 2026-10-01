import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import '../services/youth_dummy_content_store.dart';
import '../widgets/youth_story_card.dart';
import 'youth_story_detail_page.dart';

class YouthHomePage extends StatefulWidget {
  const YouthHomePage({
    super.key,
    required this.userName,
    required this.profileComplete,
    required this.onExplore,
    required this.onProfile,
  });

  final String userName;
  final bool? profileComplete;
  final VoidCallback onExplore;
  final VoidCallback onProfile;

  @override
  State<YouthHomePage> createState() => _YouthHomePageState();
}

class _YouthHomePageState extends State<YouthHomePage> {
  static const Color _backgroundColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _cardBackground = Color(0xFFFFFDF8);

  final StoryService _storyService = const StoryService();
  final BookmarkService _bookmarkService = BookmarkService.instance;
  final YouthDummyContentStore _dummyStore = YouthDummyContentStore.instance;
  List<Story> _stories = const [];
  bool _showingDummyStories = false;
  bool _isLoading = true;
  bool _bookmarksReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookmarkService.addListener(_onBookmarksChanged);
    _dummyStore.addListener(_onBookmarksChanged);
    _load();
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_onBookmarksChanged);
    _dummyStore.removeListener(_onBookmarksChanged);
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
      final page = await _storyService.fetchStories(page: 1, limit: 4);
      if (page.items.isNotEmpty) {
        await _bookmarkService.load();
      }
      if (!mounted) return;
      setState(() {
        _bookmarksReady = page.items.isNotEmpty;
        _showingDummyStories = page.items.isEmpty;
        _stories = page.items.isEmpty ? _dummyStore.stories : page.items;
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

  Future<void> _toggleBookmark(Story story) async {
    if (_dummyStore.isDummyId(story.id)) {
      _dummyStore.toggleBookmark(story.id);
      return;
    }
    try {
      await _bookmarkService.toggle(story.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The bookmark could not be updated.')),
      );
    }
  }

  void _openStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => YouthStoryDetailPage(
          storyId: story.id,
          preloadedStory: _dummyStore.isDummyId(story.id) ? story : null,
        ),
      ),
    );
  }

  void _showDummyComments() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: _accentBrown),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comments are demo-only for temporary Youth content.',
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _greetingName {
    final normalizedName = widget.userName.trim();
    if (normalizedName.isEmpty) return 'Explorer';
    return normalizedName.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: _primaryBrown, size: 28),
          onPressed: () {},
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _accentBrown.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_florist,
                color: _accentBrown,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'YATHRA',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: _primaryBrown,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _primaryBrown,
                  size: 26,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9534F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: _primaryBrown,
              size: 28,
            ),
            onPressed: widget.onProfile,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingBanner(),
                const SizedBox(height: 20),
                _buildSubTabs(),
                const SizedBox(height: 20),
                _buildStoryFeed(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_greetingName!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Discover, learn and connect with our culture.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: widget.onProfile,
            customBorder: const CircleBorder(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accentBrown.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: _accentBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: _accentBrown,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: widget.onExplore,
          child: const Padding(
            padding: EdgeInsets.only(bottom: 7),
            child: Text(
              'Explore',
              style: TextStyle(fontSize: 18, color: Colors.black45),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/youth-saved'),
          tooltip: 'Saved stories',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.bookmarks_outlined, color: _accentBrown),
        ),
      ],
    );
  }

  Widget _buildStoryFeed() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(color: _accentBrown)),
      );
    }
    if (_error != null) return _MessageCard(message: _error!, onRetry: _load);
    if (_stories.isEmpty) {
      return const _MessageCard(
        message: 'No cultural stories have been shared yet.',
      );
    }
    return Column(
      children: [
        for (final story in _stories)
          YouthStoryCard(
            story: story,
            dummyMetadata: _showingDummyStories
                ? _dummyStore.metadataFor(story.id)
                : null,
            onTap: () => _openStory(story),
            isBookmarked: _showingDummyStories
                ? _dummyStore.isBookmarked(story.id)
                : _bookmarksReady && _bookmarkService.isBookmarked(story.id),
            onBookmark: _showingDummyStories || _bookmarksReady
                ? () => _toggleBookmark(story)
                : null,
            onLike: _showingDummyStories
                ? () => _dummyStore.toggleLike(story.id)
                : null,
            onComment: _showingDummyStories ? _showDummyComments : null,
          ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 28,
            color: Color(0xFF6B4226),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black54, height: 1.3),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              tooltip: 'Retry',
              icon: const Icon(Icons.refresh, color: Color(0xFF6B4226)),
            ),
        ],
      ),
    );
  }
}
