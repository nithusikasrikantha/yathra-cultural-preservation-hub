import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';

/// Standalone elder cultural knowledge search and discovery page.
///
/// This page uses the existing Stories API through [StoryService]. It can be
/// added to the app's navigation later without changing its data or UI layer.
class ElderKnowledgeDiscoveryPage extends StatefulWidget {
  const ElderKnowledgeDiscoveryPage({
    super.key,
    this.storyService = const StoryService(),
  });

  final StoryService storyService;

  @override
  State<ElderKnowledgeDiscoveryPage> createState() =>
      _ElderKnowledgeDiscoveryPageState();
}

class _ElderKnowledgeDiscoveryPageState
    extends State<ElderKnowledgeDiscoveryPage> {
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

  final TextEditingController _searchController = TextEditingController();
  final List<Story> _stories = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;
  String? _selectedCategory;
  String? _activeSearch;
  String? _activeCategory;
  int _currentPage = 0;
  int _totalPages = 0;
  int _requestGeneration = 0;

  bool get _hasMorePages => _currentPage < _totalPages;
  bool get _hasActiveFilters =>
      _activeSearch != null || _activeCategory != null;

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
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      _loadMoreError = null;
      _stories.clear();
      _currentPage = 0;
      _totalPages = 0;
    });

    try {
      final page = await widget.storyService.fetchStories(
        page: 1,
        limit: _pageSize,
        search: _activeSearch,
        category: _activeCategory,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _stories.addAll(page.items);
        _currentPage = page.pagination.currentPage;
        _totalPages = page.pagination.totalPages;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _requestGeneration) return;

      setState(() {
        _errorMessage =
            'We could not load cultural knowledge. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore || !_hasMorePages) return;

    final requestGeneration = _requestGeneration;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await widget.storyService.fetchStories(
        page: _currentPage + 1,
        limit: _pageSize,
        search: _activeSearch,
        category: _activeCategory,
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
    });
    _loadFirstPage();
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _activeSearch = null;
      _activeCategory = null;
    });
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cultural Knowledge')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _isLoading && _stories.isEmpty
                ? _buildInitialLoading()
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: _loadFirstPage,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                      children: [
                        _buildIntroduction(),
                        const SizedBox(height: 22),
                        _buildSearchPanel(),
                        const SizedBox(height: 22),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          _buildMessage(
                            icon: Icons.cloud_off_outlined,
                            title: 'Knowledge could not be loaded',
                            message: _errorMessage!,
                            actionLabel: 'Try again',
                            onPressed: _loadFirstPage,
                          )
                        else if (_stories.isEmpty)
                          _buildMessage(
                            icon: Icons.auto_stories_outlined,
                            title: _hasActiveFilters
                                ? 'No matching knowledge found'
                                : 'No stories have been shared yet',
                            message: _hasActiveFilters
                                ? 'Try another search or category, or clear your filters.'
                                : 'Stories and traditions shared by the community will appear here.',
                            actionLabel: _hasActiveFilters
                                ? 'Clear filters'
                                : null,
                            onPressed: _hasActiveFilters ? _clearFilters : null,
                          )
                        else ...[
                          Text(
                            _hasActiveFilters
                                ? 'Search results'
                                : 'Recently shared',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 12),
                          for (final story in _stories)
                            _KnowledgeStoryCard(story: story),
                          if (_loadMoreError != null)
                            _buildMessage(
                              icon: Icons.wifi_off_outlined,
                              title: 'More stories were not loaded',
                              message: _loadMoreError!,
                              actionLabel: 'Retry',
                              onPressed: _loadMoreStories,
                            ),
                          if (_hasMorePages && _loadMoreError == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingMore
                                    ? null
                                    : _loadMoreStories,
                                icon: _isLoadingMore
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more),
                                label: Text(
                                  _isLoadingMore
                                      ? 'Loading stories...'
                                      : 'Load more stories',
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'ELDER KNOWLEDGE LIBRARY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Discover wisdom passed down through generations',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 25, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore stories, traditions, recipes, and local knowledge shared by elders and community members.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find cultural knowledge',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search stories and traditions',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Browse by category',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                _categoryChip('All knowledge', null),
                for (final category in _categories)
                  _categoryChip(category, category),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _applyFilters,
                icon: const Icon(Icons.search),
                label: const Text('Search knowledge'),
              ),
            ),
            if (_hasActiveFilters ||
                _selectedCategory != null ||
                _searchController.text.trim().isNotEmpty)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear search and filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? value) {
    final selected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppTheme.accentColor,
      side: BorderSide(
        color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.35)
            : AppTheme.accentColor,
      ),
      onSelected: (_) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildInitialLoading() {
    return Center(
      child: Semantics(
        label: 'Loading cultural knowledge',
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: AppTheme.secondaryTextColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}

class _KnowledgeStoryCard extends StatelessWidget {
  const _KnowledgeStoryCard({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final preview = story.storyText.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentColor.withValues(alpha: 0.72),
          child: const Icon(Icons.menu_book_outlined),
        ),
        title: Text(
          story.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 7,
            runSpacing: 4,
            children: [
              _StoryLabel(label: story.category),
              _StoryLabel(label: story.language),
            ],
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
          if (story.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: story.tags
                    .map((tag) => _StoryLabel(label: '#$tag'))
                    .toList(growable: false),
              ),
            ),
          ],
          if (story.audioPath != null) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.volume_up_outlined, size: 18),
                SizedBox(width: 6),
                Text('Audio recording available'),
              ],
            ),
          ],
          if (story.createdAt != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Shared ${_formatDate(story.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }
}

class _StoryLabel extends StatelessWidget {
  const _StoryLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.secondaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
