import 'package:flutter/material.dart';

import '../share_story_page.dart';

class ElderHomePage extends StatefulWidget {
  const ElderHomePage({
    super.key,
    this.userName = 'Kamala',
  });

  final String userName;

  @override
  State<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends State<ElderHomePage> {
  static const Color _bgColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _cardBg = Color(0xFFFFFDF8);

  int _selectedTab = 0; // 0: For You, 1: Following

  void _openShareStory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ShareStoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
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
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // Feed Post 1
                  _buildFeedCard(
                    authorName: 'Thiruvarangan',
                    authorAvatarUrl:
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                    timeMeta: '2h • Tamil • Traditional Story',
                    storyText:
                        'The story of our village harvest, when the whole community came together to celebrate the season...',
                    imageUrl:
                        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
                    likes: 24,
                    comments: 8,
                  ),

                  const SizedBox(height: 20),

                  // Feed Post 2
                  _buildFeedCard(
                    authorName: 'Lakshmi Amma',
                    authorAvatarUrl:
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
                    timeMeta: 'Yesterday • Tamil • Recipe',
                    storyText:
                        'A traditional recipe passed down from my grandmother. This dish brings back so many childhood memories...',
                    imageUrl:
                        'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?auto=format&fit=crop&w=800&q=80',
                    likes: 41,
                    comments: 12,
                  ),

                  const SizedBox(height: 90), // Spacing for floating button
                ],
              ),
            ),
          ),

          // Floating Action Button (+)
          Positioned(
            right: 22,
            bottom: 22,
            child: FloatingActionButton(
              onPressed: _openShareStory,
              backgroundColor: _accentBrown,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
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
                  'Good morning, ${widget.userName} 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your stories keep our heritage alive.',
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accentBrown.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person,
                  size: 40,
                  color: _accentBrown,
                ),
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
        GestureDetector(
          onTap: () => setState(() => _selectedTab = 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
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
          onTap: () => setState(() => _selectedTab = 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Following',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildFeedCard({
    required String authorName,
    required String authorAvatarUrl,
    required String timeMeta,
    required String storyText,
    required String imageUrl,
    required int likes,
    required int comments,
  }) {
    return Container(
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
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 12),

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
                    child: const Icon(Icons.image, size: 48, color: _accentBrown),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

          // Social Footer Bar (Likes, Comments, Share)
          Row(
            children: [
              const Icon(Icons.favorite_border_rounded,
                  size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                '$likes',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 20, color: Colors.black54),
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
                icon: const Icon(Icons.reply_rounded,
                    size: 20, color: Colors.black54),
                label: const Text(
                  'Share',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
