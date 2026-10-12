import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/community_theme.dart';
import '../models/story.dart';
import '../services/published_content_signal.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'community_details_page.dart';
import 'youth_story_detail_page.dart';

String _fallbackArt(String category) => switch (category.toLowerCase()) {
  'performing arts' => 'assets/images/onboarding/performing_arts.png',
  'history' => 'assets/images/onboarding/connection.png',
  'local dialects' => 'assets/images/onboarding/stories.png',
  _ => 'assets/images/onboarding/heritage.png',
};

/// Explore Page (Page 2 in the required flow)
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);

  final TextEditingController _searchController = TextEditingController();
  final StoryService _storyService = const StoryService();
  final List<CulturalTheme> _themes = MockCulturalData.getPopularThemes();
  final List<CategoryItem> _categories = MockCulturalData.getCategories();
  List<Story> _publishedStories = const [];
  bool _storiesLoading = true;

  @override
  void initState() {
    super.initState();
    PublishedContentSignal.revision.addListener(_reloadPublishedStories);
    _loadPublishedStories();
  }

  Future<void> _loadPublishedStories() async {
    try {
      final page = await _storyService.fetchStories(page: 1, limit: 6);
      if (!mounted) return;
      setState(() {
        _publishedStories = page.items;
        _storiesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _storiesLoading = false);
    }
  }

  void _reloadPublishedStories() => _loadPublishedStories();

  @override
  void dispose() {
    _searchController.dispose();
    PublishedContentSignal.revision.removeListener(_reloadPublishedStories);
    super.dispose();
  }

  void _openCommunityDetails(CulturalTheme theme) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityDetailsPage(theme: theme),
      ),
    );
  }

  void _openCategory(CategoryItem category) {
    final relatedThemes = _themes
        .where((theme) => theme.category.toLowerCase() == category.title.toLowerCase())
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreCategoryPage(
          category: category,
          themes: relatedThemes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visibleThemes = _themes.where((theme) {
      final searchable =
          '${theme.title} ${theme.category} ${theme.description}'.toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
    final visibleCategories = _categories.where((category) {
      final searchable = '${category.title} ${category.subtitle}'.toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cultural Knowledge Header Banner
              _buildHeaderBanner(),

              const SizedBox(height: 20),

              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 24),

              // Popular Cultural Themes Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Cultural Themes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${visibleThemes.length} cultural communities',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _primaryBrown.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: _primaryBrown,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Horizontal Scrollable Popular Cultural Theme Cards
              if (visibleThemes.isNotEmpty)
                SizedBox(
                  height: 185,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: visibleThemes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final theme = visibleThemes[index];
                      return _ThemeCard(
                        theme: theme,
                        onTap: () => _openCommunityDetails(theme),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No cultural communities match your search yet.',
                    style: TextStyle(color: Color(0xFF745F50)),
                  ),
                ),

              const SizedBox(height: 28),

              // Explore by Category Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explore by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryBrown,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_searchController.clear),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _accentBrown,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: _accentBrown,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Category Cards Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final category = visibleCategories[index];
                  return _CategoryCard(
                    category: category,
                    onTap: () => _openCategory(category),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildPublishedStoriesSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Published',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
          ),
        ),
        const SizedBox(height: 12),
        if (_storiesLoading)
          const Center(child: CircularProgressIndicator())
        else if (_publishedStories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Elder-reviewed community stories will appear here.'),
          )
        else
          ..._publishedStories.map(
            (story) => Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: story.imageDataUri == null
                    ? Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEADCC9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: _accentBrown),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(story.imageDataUri!.split(',').last),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                title: Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${story.category} • ${story.language}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => YouthStoryDetailPage(storyId: story.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEADCC9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _primaryBrown,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CULTURAL KNOWLEDGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _primaryBrown.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cultural Knowledge',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore Sri Lankan traditions, stories and knowledge shared by our elders',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: _primaryBrown.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search stories, traditions, recipes...',
          hintStyle: TextStyle(
            color: _primaryBrown.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _primaryBrown.withValues(alpha: 0.6),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: _primaryBrown.withValues(alpha: 0.8),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Card representing a Popular Cultural Theme
class _ThemeCard extends StatelessWidget {
  final CulturalTheme theme;
  final VoidCallback onTap;

  const _ThemeCard({required this.theme, required this.onTap});

  static const Color _primaryBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      theme.imageUrl,
      height: 105,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        _fallbackArt(theme.category),
        height: 105,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: image,
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryBrown,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.membersCount,
                    style: TextStyle(
                      fontSize: 11,
                      color: _primaryBrown.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Category Card in Grid
class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  static const Color _primaryBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      category.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        _fallbackArt(category.title),
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: image,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: _primaryBrown.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class ExploreCategoryPage extends StatelessWidget {
  const ExploreCategoryPage({
    super.key,
    required this.category,
    required this.themes,
  });

  final CategoryItem category;
  final List<CulturalTheme> themes;

  String get _description => switch (category.categoryKey) {
    'history' =>
      'Explore local landmarks, temple heritage, inscriptions and the memories elders share about their communities.',
    'food' =>
      'Discover family recipes, regional ingredients and the stories behind traditional cooking.',
    'performing_arts' =>
      'Learn about dance forms, ceremonial clothing, rhythms and the people who keep these performances alive.',
    'music' =>
      'Listen to folk songs, work chants, lullabies and the instruments and memories carried with them.',
    'dialects' =>
      'Collect regional words, everyday sayings and pronunciation with context from local speakers.',
    _ =>
      'Explore family knowledge of home gardens, traditional plants and preparation customs for cultural learning.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(title: Text(category.title)),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 220,
            child: Image.network(
              category.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                _fallbackArt(category.title),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          category.title,
          style: const TextStyle(
            color: Color(0xFF4A2C1A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _description,
          style: const TextStyle(
            color: Color(0xFF655344),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Communities to explore',
          style: TextStyle(
            color: Color(0xFF4A2C1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (themes.isEmpty)
          const Text('Community content will appear here as elders share it.')
        else
          for (final theme in themes)
            Card(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CommunityDetailsPage(theme: theme),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Image.network(
                        theme.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          _fallbackArt(theme.category),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.title,
                              style: const TextStyle(
                                color: Color(0xFF4A2C1A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${theme.membersCount}  •  ${theme.activeEldersCount}',
                              style: const TextStyle(
                                color: Color(0xFF806A58),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}
