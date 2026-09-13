import 'package:flutter/material.dart';

class YouthFeedPage extends StatelessWidget {
  const YouthFeedPage({super.key});

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const Color _softGold = Color(0xFFE9C46A);

  static const List<String> _categories = [
    'All',
    'Folklore',
    'Food',
    'Festivals',
    'Music',
    'Crafts',
    'History',
  ];

  static const List<_CulturalStory> _stories = [
    _CulturalStory(
      title: 'The Moonlit Banyan Tale',
      category: 'Folklore',
      language: 'Tamil',
      region: 'Jaffna',
      contributor: 'Elder Kamala',
      description:
          'A village story about kindness, courage, and the old banyan tree that gathered families at dusk.',
      icon: Icons.auto_stories,
    ),
    _CulturalStory(
      title: 'Kiribath for New Beginnings',
      category: 'Traditional Food',
      language: 'Sinhala',
      region: 'Kandy',
      contributor: 'Elder Sunil',
      description:
          'A short memory about preparing milk rice for celebrations and sharing the first plate with neighbors.',
      icon: Icons.rice_bowl,
    ),
    _CulturalStory(
      title: 'Lanterns of Vesak Night',
      category: 'Festivals',
      language: 'English',
      region: 'Colombo',
      contributor: 'Aunty Malini',
      description:
          'How families made paper lanterns together and lit the street with color during Vesak.',
      icon: Icons.celebration,
    ),
    _CulturalStory(
      title: 'Drums Across the Courtyard',
      category: 'Music',
      language: 'Tamil',
      region: 'Batticaloa',
      contributor: 'Elder Arul',
      description:
          'A remembered rhythm from temple gatherings, taught by listening before learning the steps.',
      icon: Icons.music_note,
    ),
    _CulturalStory(
      title: 'Hands That Weave Palmyrah',
      category: 'Crafts',
      language: 'Tamil',
      region: 'Mannar',
      contributor: 'Paati Selvi',
      description:
          'A gentle introduction to palmyrah weaving and the patience behind everyday handmade items.',
      icon: Icons.handyman,
    ),
    _CulturalStory(
      title: 'A Fort by the Sea',
      category: 'History',
      language: 'English',
      region: 'Galle',
      contributor: 'Uncle Nimal',
      description:
          'A short historical note about walking the old fort walls and hearing stories from the coast.',
      icon: Icons.account_balance,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryBrown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Youth Discover',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Discover cultural stories',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore traditions, memories, and knowledge shared by elders.',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: _darkBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'Search cultural stories placeholder',
              textField: true,
              child: TextField(
                enabled: false,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search stories, places, or traditions',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(Icons.search, color: _primaryBrown),
                  filled: true,
                  fillColor: Colors.white,
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _primaryBrown.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final String category = _categories[index];
                  final bool isSelected = index == 0;

                  return Semantics(
                    label: '$category category chip',
                    selected: isSelected,
                    child: Chip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _darkBrown,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? _primaryBrown
                          : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? _primaryBrown
                            : _primaryBrown.withValues(alpha: 0.35),
                        width: 1.3,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ..._stories.map(
              (story) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _StoryCard(story: story),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final _CulturalStory story;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const Color _softGold = YouthFeedPage._softGold;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _primaryBrown.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '${story.category} media placeholder',
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _softGold.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(story.icon, color: _primaryBrown, size: 38),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              story.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _darkBrown,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Semantics(
                            label: 'Bookmark ${story.title} placeholder',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Bookmark',
                              icon: const Icon(Icons.bookmark_border),
                              color: _primaryBrown,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(text: story.category),
                          _MetaPill(text: story.language),
                          _MetaPill(text: story.region),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'By ${story.contributor}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _primaryBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _darkBrown,
        ),
      ),
    );
  }
}

class _CulturalStory {
  const _CulturalStory({
    required this.title,
    required this.category,
    required this.language,
    required this.region,
    required this.contributor,
    required this.description,
    required this.icon,
  });

  final String title;
  final String category;
  final String language;
  final String region;
  final String contributor;
  final String description;
  final IconData icon;
}
