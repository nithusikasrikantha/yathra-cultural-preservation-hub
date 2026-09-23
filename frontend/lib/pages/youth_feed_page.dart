import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';
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
  final List<Story> _stories = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTags = {};

  bool _isInitialLoading = true;
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
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Youth / Discover',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
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
                _StoryCard(story: story, onTap: () => _openStory(story.id)),
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

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '${story.title}, ${story.category}, ${story.language}',
      child: Card(
        color: Colors.white,
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetadataChip(
                      icon: Icons.category_outlined,
                      label: story.category,
                    ),
                    _MetadataChip(
                      icon: Icons.language_outlined,
                      label: story.language,
                    ),
                    if (story.audioPath != null)
                      const _MetadataChip(
                        icon: Icons.mic_none_outlined,
                        label: 'Audio included',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  story.title,
                  style: const TextStyle(
                    color: _darkBrown,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  story.storyText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                if (story.createdAt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Shared ${_formatDate(story.createdAt!)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Read full story',
                      style: TextStyle(
                        color: _primaryBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 19, color: _primaryBrown),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E5D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: _StoryCard._primaryBrown),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _StoryCard._darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
