import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';

import 'share_story_page.dart';
import 'story_details_page.dart';
import '../../widgets/social_story_card.dart';
import '../../models/story.dart';
import '../../services/story_service.dart';
import '../../services/published_content_signal.dart';

class ElderHomePage extends StatefulWidget {
  const ElderHomePage({
    super.key,
    this.userName = 'Kamala',
    this.onProfile,
    this.avatar,
  });

  final String userName;
  final String? avatar;
  final VoidCallback? onProfile;

  @override
  State<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends State<ElderHomePage> {
  static const Color _bgColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);

  final StoryService _storyService = const StoryService();

  String _search = "";
  bool _isLoadingStories = true;
  int _selectedTab = 0; // 0: For You, 1: Following
  List<Story> _publishedStories = const [];

  @override
  void initState() {
    super.initState();
    PublishedContentSignal.revision.addListener(_loadPublishedStories);
    _loadPublishedStories();
  }

  @override
  void didUpdateWidget(covariant ElderHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar != widget.avatar) _loadPublishedStories();
  }

  @override
  void dispose() {
    PublishedContentSignal.revision.removeListener(_loadPublishedStories);
    super.dispose();
  }

  Future<void> _loadPublishedStories() async {
    try {
      final page = await _storyService.fetchStories(
        page: 1,
        limit: 20,
        following: _selectedTab == 1,
      );
      if (mounted) {
        setState(() {
          _publishedStories = page.items;
          _isLoadingStories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStories = false);
    }
  }

  void _openShareStory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ShareStoryPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: HomeTopBar(
        isElder: true,
        onProfile: widget.onProfile,
        avatar: widget.avatar,
        userName: widget.userName,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPublishedStories,
          color: _accentBrown,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Header Banner
                _buildGreetingBanner(),

                const SizedBox(height: 20),

                // For You / Following Sub-Tabs
                _buildSubTabs(),

                const SizedBox(height: 20),

                if (_isLoadingStories && _publishedStories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: _accentBrown),
                    ),
                  ),

                // Real Stories Published from Backend
                if (_publishedStories.isNotEmpty) ...[
                  for (final story in _publishedStories.where(
                    (s) => '${s.title} ${s.storyText} ${s.location ?? ''}'
                        .toLowerCase()
                        .contains(_search),
                  )) ...[
                    _buildRealStoryCard(story),
                    const SizedBox(height: 20),
                  ],
                ],

                if (!_isLoadingStories && _publishedStories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      _selectedTab == 1
                          ? 'Follow communities to see their published stories here.'
                          : 'No cultural stories have been shared yet.',
                      style: const TextStyle(
                        fontSize: 17,
                        color: _primaryBrown,
                      ),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),

      // Floating Action Button (+)
      floatingActionButton: FloatingActionButton(
        onPressed: _openShareStory,
        backgroundColor: _accentBrown,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34, color: Colors.white),
      ),
    );
  }

  Widget _buildGreetingBanner() => DiscoveryHeading(
    onSearch: (value) => setState(() => _search = value.trim().toLowerCase()),
  );

  Widget _buildSubTabs() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _selectedTab = 0);
            _loadPublishedStories();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: _selectedTab == 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedTab == 0 ? _primaryBrown : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              if (_selectedTab == 0)
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
        ),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: () {
            setState(() => _selectedTab = 1);
            _loadPublishedStories();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Following',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: _selectedTab == 1
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedTab == 1 ? _primaryBrown : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              if (_selectedTab == 1)
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
        ),
      ],
    );
  }

  void _openStoryDetails({Story? story, Map<String, dynamic>? storyData}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailsPage(story: story, storyData: storyData),
      ),
    );
  }

  Widget _buildRealStoryCard(Story story) => SocialStoryCard(
    key: ValueKey(story.id),
    story: story,
    authorName: widget.userName,
    onTap: () => _openStoryDetails(story: story),
  );
}
