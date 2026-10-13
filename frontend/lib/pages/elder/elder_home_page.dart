import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';

import 'share_story_page.dart';
import 'story_details_page.dart';
import '../../widgets/social_story_card.dart';
import '../../models/story.dart';
import '../../services/story_service.dart';
import '../../services/published_content_signal.dart';

class ElderHomePage extends StatefulWidget {
  const ElderHomePage({super.key, this.userName = 'Kamala', this.onProfile});

  final String userName;
  final VoidCallback? onProfile;

  @override
  State<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends State<ElderHomePage> {
  static const Color _bgColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _cardBg = Color(0xFFFFFDF8);

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
      appBar: HomeTopBar(isElder: true, onProfile: widget.onProfile),
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

                // Sample Feed Posts
                _buildFeedCard(
                  authorName: 'Thiruvarangan',
                  authorAvatarUrl:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                  timeMeta: '2h • Tamil • Traditional Story',
                  storyTitle: 'The Village Harvest Celebration',
                  storyText:
                      'The story of our village harvest, when the whole community came together to celebrate the season...',
                  imageUrl:
                      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
                  location: 'Jaffna',
                  timePeriod: 'Childhood era',
                  community: 'Northern Tamil Heritage',
                  likes: 24,
                  comments: 8,
                ),

                const SizedBox(height: 20),

                _buildFeedCard(
                  authorName: 'Lakshmi Amma',
                  authorAvatarUrl:
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
                  timeMeta: 'Yesterday • Tamil • Recipe',
                  storyTitle: 'Traditional Palmyra Syrup Sweet Recipe',
                  storyText:
                      'A traditional recipe passed down from my grandmother. This dish brings back so many childhood memories...',
                  imageUrl:
                      'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?auto=format&fit=crop&w=800&q=80',
                  location: 'Kandy',
                  timePeriod: '1970s',
                  community: 'Traditional Culinary Guild',
                  likes: 41,
                  comments: 12,
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

  Widget _buildFeedCard({
    required String authorName,
    required String authorAvatarUrl,
    required String timeMeta,
    required String storyTitle,
    required String storyText,
    required String imageUrl,
    String? location,
    String? timePeriod,
    String? community,
    required int likes,
    required int comments,
  }) {
    if (_selectedTab == 1) return const SizedBox.shrink();
    final storyData = {
      'title': storyTitle,
      'category': timeMeta.split('•').last.trim(),
      'language': 'Tamil',
      'storyText': storyText,
      'imageUrl': imageUrl,
      'location': location,
      'timePeriod': timePeriod,
      'community': community,
    };

    return InkWell(
      onTap: () => _openStoryDetails(storyData: storyData),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(authorAvatarUrl),
                  backgroundColor: _accentBrown.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeMeta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Story Image with Overlaid "🔊 Listen" Button
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: _accentBrown.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.image,
                        size: 48,
                        color: _accentBrown,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Listen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEADCC9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                storyData['category'] as String,
                style: const TextStyle(color: _primaryBrown, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              storyTitle,
              style: const TextStyle(
                fontFamily: 'Serif',
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            // Story Text Content
            Text(
              storyText,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                const Text(
                  'Tamil',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (location != null)
                  Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                Text(
                  '${(storyText.split(RegExp(r"\s+")).length / 180).ceil().clamp(1, 999)} min read',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const Divider(),
            // Social Footer Bar (Likes, Comments, Share)
            Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  '$likes',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  '$comments',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.reply_rounded,
                    size: 20,
                    color: Colors.black54,
                  ),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
