import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import '../widgets/youth_story_card.dart';
import 'youth_story_detail_page.dart';

class YouthFeedPage extends StatefulWidget {
  const YouthFeedPage({super.key});

  @override
  State<YouthFeedPage> createState() => _YouthFeedPageState();
}

class _YouthFeedPageState extends State<YouthFeedPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const int _pageSize = 10;
  static const List<String> _categories = [
    'Traditional Story',
    'Recipe',
    'Song',
    'Proverb',
    'Traditional Practice',
    'Local History',
    'Language',
    'Other',
  ];
  static const List<String> _tagOptions = [
    'Folklore',
    'Traditional Food',
    'Music',
    'Dance',
    'Festivals',
    'Language',
    'History',
    'Crafts',
  ];

  final StoryService _storyService = const StoryService();
  final BookmarkService _bookmarkService = BookmarkService.instance;
  final List<Story> _stories = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTags = {};

  bool _isInitialLoading = true;
  bool _bookmarksReady = false;
  bool _isLoadingMore = false;
  String? _initialError;
  String? _loadMoreError;
  int _currentPage = 0;
  int _totalPages = 0;
  int _requestGeneration = 0;
  String? _selectedCategory;
  String? _activeSearch;
  String? _activeCategory;
  List<String> _activeTags = const [];

  bool get _hasMorePages => _currentPage < _totalPages;
  bool get _hasActiveFilters =>
      _activeSearch != null ||
      _activeCategory != null ||
      _activeTags.isNotEmpty;
  bool get _hasEditableFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedTags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _bookmarkService.addListener(_handleBookmarksChanged);
    _initializeBookmarks();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_handleBookmarksChanged);
    _searchController.dispose();
    super.dispose();
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
      _bookmarksReady = _bookmarkService.isLoaded;
    });
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

  Future<void> _loadFirstPage() async {
    final requestGeneration = ++_requestGeneration;
    final search = _activeSearch;
    final category = _activeCategory;
    final tags = List<String>.of(_activeTags);

    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _initialError = null;
      _loadMoreError = null;
      _stories.clear();
      _currentPage = 0;
      _totalPages = 0;
    });

    try {
      final page = await _storyService.fetchStories(
        page: 1,
        limit: _pageSize,
        search: search,
        category: category,
        tags: tags,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _stories
          ..clear()
          ..addAll(page.items);
        _currentPage = page.pagination.currentPage;
        _totalPages = page.pagination.totalPages;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _initialError = 'We could not load cultural stories. Please try again.';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore || !_hasMorePages) return;

    final requestGeneration = _requestGeneration;
    final search = _activeSearch;
    final category = _activeCategory;
    final tags = List<String>.of(_activeTags);

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await _storyService.fetchStories(
        page: _currentPage + 1,
        limit: _pageSize,
        search: search,
        category: category,
        tags: tags,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _stories.addAll(page.items);
        _currentPage = page.pagination.currentPage;
        _totalPages = page.pagination.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _loadMoreError = 'More stories could not be loaded. Please try again.';
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    final search = _searchController.text.trim();

    setState(() {
      _activeSearch = search.isEmpty ? null : search;
      _activeCategory = _selectedCategory;
      _activeTags = List<String>.unmodifiable(_selectedTags);
    });

    _loadFirstPage();
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();

    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedTags.clear();
      _activeSearch = null;
      _activeCategory = null;
      _activeTags = const [];
    });

    _loadFirstPage();
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
        title: const Text(
          'Search & Explore',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/youth-saved'),
            tooltip: 'Saved posts',
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBrown,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushNamed('/explore');
          } else if (index == 3) {
            Navigator.of(context).pushNamed('/youth-profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return Center(
        child: Semantics(
          label: 'Loading cultural stories',
          child: CircularProgressIndicator(color: _primaryBrown),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover cultural stories',
                    style: TextStyle(
                      color: _darkBrown,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Explore traditions, memories, and knowledge shared by the community.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _buildFilterPanel(),
            const SizedBox(height: 20),
            if (_initialError != null)
              _buildResultMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to load stories',
                message: _initialError!,
                actionLabel: 'Retry',
                onPressed: _loadFirstPage,
              )
            else if (_stories.isEmpty)
              _buildResultMessage(
                icon: Icons.auto_stories_outlined,
                title: _hasActiveFilters
                    ? 'No matching stories'
                    : 'No stories yet',
                message: _hasActiveFilters
                    ? 'Try changing or clearing your search and filters.'
                    : 'Cultural stories will appear here when they are published.',
                actionLabel: _hasActiveFilters ? 'Clear filters' : 'Refresh',
                onPressed: _hasActiveFilters ? _clearFilters : _loadFirstPage,
              )
            else ...[
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
              _buildPaginationFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find stories',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _applyFilters(),
              decoration: InputDecoration(
                labelText: 'Search stories',
                hintText: 'Search by title or story text',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCategory),
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'All categories',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Tags (match all selected)',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions
                  .map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: _primaryBrown,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _darkBrown,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search),
                label: const Text('Search stories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_hasEditableFilters || _hasActiveFilters) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filters'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    if (!_hasMorePages) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Center(
          child: Text(
            'You have reached the end of the stories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (_loadMoreError != null) ...[
            Text(
              _loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 15),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoadingMore ? null : _loadMoreStories,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBrown,
                side: const BorderSide(color: _primaryBrown),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'Load more stories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
