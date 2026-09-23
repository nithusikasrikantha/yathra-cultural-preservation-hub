import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_service.dart';

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

  final StoryService _storyService = const StoryService();
  final List<Story> _stories = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _initialError;
  String? _loadMoreError;
  int _currentPage = 0;
  int _totalPages = 0;

  bool get _hasMorePages => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _initialError = null;
      _loadMoreError = null;
    });

    try {
      final page = await _storyService.fetchStories(page: 1, limit: _pageSize);
      if (!mounted) return;

      setState(() {
        _stories
          ..clear()
          ..addAll(page.items);
        _currentPage = page.pagination.currentPage;
        _totalPages = page.pagination.totalPages;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _initialError = 'We could not load cultural stories. Please try again.';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await _storyService.fetchStories(
        page: _currentPage + 1,
        limit: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _stories.addAll(page.items);
        _currentPage = page.pagination.currentPage;
        _totalPages = page.pagination.totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadMoreError = 'More stories could not be loaded. Please try again.';
        _isLoadingMore = false;
      });
    }
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

    if (_initialError != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load stories',
        message: _initialError!,
        actionLabel: 'Retry',
        onPressed: _loadFirstPage,
      );
    }

    if (_stories.isEmpty) {
      return _buildMessageState(
        icon: Icons.auto_stories_outlined,
        title: 'No stories yet',
        message: 'Cultural stories will appear here when they are published.',
        actionLabel: 'Refresh',
        onPressed: _loadFirstPage,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          itemCount: _stories.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
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
              );
            }

            if (index <= _stories.length) {
              return _StoryCard(story: _stories[index - 1]);
            }

            return _buildPaginationFooter();
          },
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

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final Story story;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${story.title}, ${story.category}, ${story.language}',
      child: Card(
        color: Colors.white,
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            ],
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
