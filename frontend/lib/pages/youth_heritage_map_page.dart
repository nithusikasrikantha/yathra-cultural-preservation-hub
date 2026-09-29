import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/bookmark_service.dart';
import '../services/story_service.dart';
import '../widgets/youth_story_card.dart';
import 'youth_story_detail_page.dart';

class YouthHeritageMapPage extends StatefulWidget {
  const YouthHeritageMapPage({super.key});

  @override
  State<YouthHeritageMapPage> createState() => _YouthHeritageMapPageState();
}

class _YouthHeritageMapPageState extends State<YouthHeritageMapPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const List<String> _districts = [
    'Jaffna',
    'Kandy',
    'Galle',
    'Colombo',
  ];

  final StoryService _storyService = const StoryService();
  final BookmarkService _bookmarkService = BookmarkService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Story> _stories = const [];
  String? _selectedDistrict;
  String _districtQuery = '';
  bool _isLoading = false;
  bool _bookmarksReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookmarkService.addListener(_onBookmarksChanged);
    _bookmarkService.load().then((_) {
      if (mounted) setState(() => _bookmarksReady = true);
    });
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_onBookmarksChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onBookmarksChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectDistrict(String district) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedDistrict = district;
      _searchController.text = district;
      _districtQuery = district;
      _isLoading = true;
      _error = null;
      _stories = const [];
    });
    try {
      final page = await _storyService.fetchStories(
        page: 1,
        limit: 20,
        tags: [district],
      );
      if (!mounted || _selectedDistrict != district) return;
      setState(() {
        _stories = page.items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || _selectedDistrict != district) return;
      setState(() {
        _error = 'Stories for this region could not be loaded.';
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final visibleDistricts = _districts
        .where(
          (district) => district.toLowerCase().contains(
            _districtQuery.trim().toLowerCase(),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Heritage Guide',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          const Text(
            'Explore by cultural region',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a district to discover stories tagged for that region.',
            style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search districts or cultural regions',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _districtQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _districtQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _districtQuery = value),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1E5D5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.map_outlined, size: 72, color: _primaryBrown),
                SizedBox(height: 8),
                Text(
                  'Sri Lanka Cultural Regions',
                  style: TextStyle(
                    color: _darkBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleDistricts
                .map(
                  (district) => ChoiceChip(
                    label: Text(district),
                    selected: _selectedDistrict == district,
                    selectedColor: _primaryBrown,
                    labelStyle: TextStyle(
                      color: _selectedDistrict == district
                          ? Colors.white
                          : _darkBrown,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => _selectDistrict(district),
                  ),
                )
                .toList(growable: false),
          ),
          if (visibleDistricts.isEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'No supported district matches your search.',
              textAlign: TextAlign.center,
            ),
          ],
          if (_selectedDistrict != null) ...[
            const SizedBox(height: 26),
            Text(
              'Stories from $_selectedDistrict',
              style: const TextStyle(
                color: _darkBrown,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: _primaryBrown),
                ),
              )
            else if (_error != null)
              _MapMessage(
                message: _error!,
                onRetry: () => _selectDistrict(_selectedDistrict!),
              )
            else if (_stories.isEmpty)
              const _MapMessage(
                message: 'No cultural stories found for this region yet.',
              )
            else
              for (final story in _stories)
                YouthStoryCard(
                  story: story,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          YouthStoryDetailPage(storyId: story.id),
                    ),
                  ),
                  isBookmarked:
                      _bookmarksReady &&
                      _bookmarkService.isBookmarked(story.id),
                  onBookmark: _bookmarksReady
                      ? () => _toggleBookmark(story.id)
                      : null,
                ),
          ],
        ],
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.location_off_outlined, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
