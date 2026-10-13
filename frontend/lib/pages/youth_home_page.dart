import 'package:flutter/material.dart';
import '../widgets/home_header.dart';

import '../models/story.dart';
import '../services/youth_dummy_content_store.dart';
import '../widgets/youth_story_card.dart';
import '../services/story_service.dart';
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

  final YouthDummyContentStore _dummyStore = YouthDummyContentStore.instance;
  List<Story> _stories = const [];
  bool _showingDummyStories = false;
  String _search = "";
  bool _isLoading = true;
  bool _following = false;
  String? _feedError;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _dummyStore.addListener(_onBookmarksChanged);
    _load();
  }

  @override
  void dispose() {
    _dummyStore.removeListener(_onBookmarksChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _isLoading = true;
      _feedError = null;
    });
    try {
      final stories = _following
          ? (await const StoryService().fetchStories(
              page: 1,
              limit: 50,
              following: true,
            )).items
          : _dummyStore.stories;
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _stories = stories;
        _showingDummyStories = !_following;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted && version == _loadVersion)
        setState(() {
          _isLoading = false;
          _feedError = 'Could not load stories. Please retry.';
        });
    }
  }

  void _toggleBookmark(Story story) => _dummyStore.toggleBookmark(story.id);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: HomeTopBar(isElder: false, onProfile: widget.onProfile),
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

  Widget _buildGreetingBanner() => DiscoveryHeading(
    onSearch: (value) => setState(() => _search = value.trim().toLowerCase()),
  );

  Widget _buildSubTabs() => Row(
    children: [
      for (final following in [false, true])
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: InkWell(
            onTap: () {
              setState(() => _following = following);
              _load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    following ? 'Following' : 'For you',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: _following == following
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _following == following
                          ? _primaryBrown
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    width: following ? 80 : 60,
                    color: _following == following
                        ? _accentBrown
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      const Spacer(),
      IconButton(
        onPressed: () => Navigator.pushNamed(context, '/youth-saved'),
        tooltip: 'Saved stories',
        icon: const Icon(Icons.bookmarks_outlined, color: _accentBrown),
      ),
    ],
  );

  Widget _buildStoryFeed() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(color: _accentBrown)),
      );
    }
    if (_feedError != null)
      return _MessageCard(message: _feedError!, onRetry: _load);
    if (_following && _stories.isEmpty)
      return _MessageCard(
        message: 'Follow communities to see their published stories here.',
        onRetry: widget.onExplore,
      );
    if (_stories.isEmpty) {
      return const _MessageCard(
        message: 'No cultural stories have been shared yet.',
      );
    }
    return Column(
      children: [
        for (final story in _stories.where(
          (s) => '${s.title} ${s.storyText} ${s.location ?? ''}'
              .toLowerCase()
              .contains(_search),
        ))
          YouthStoryCard(
            story: story,
            dummyMetadata: _showingDummyStories
                ? _dummyStore.metadataFor(story.id)
                : null,
            onTap: () => _openStory(story),
            isBookmarked: _dummyStore.isBookmarked(story.id),
            onBookmark: () => _toggleBookmark(story),
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
