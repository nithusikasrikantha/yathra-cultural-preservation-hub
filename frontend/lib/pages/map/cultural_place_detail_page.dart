import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../config/api_config.dart';
import '../../models/cultural_place.dart';
import '../../models/story.dart';
import '../../services/bookmark_service.dart';
import '../../services/cultural_place_bookmark_service.dart';
import '../../services/cultural_place_service.dart';
import '../../services/story_service.dart';
import '../../widgets/map/cultural_map_widgets.dart';
import '../../widgets/youth_story_card.dart';
import '../youth_story_detail_page.dart';

class CulturalPlaceDetailPage extends StatefulWidget {
  const CulturalPlaceDetailPage({
    super.key,
    required this.place,
    required this.userRole,
    required this.initiallySaved,
    this.userLocation,
  });

  final CulturalPlace place;
  final String userRole;
  final bool initiallySaved;
  final Position? userLocation;

  @override
  State<CulturalPlaceDetailPage> createState() =>
      _CulturalPlaceDetailPageState();
}

class _CulturalPlaceDetailPageState extends State<CulturalPlaceDetailPage> {
  late bool _isSaved;
  final StoryService _storyService = const StoryService();
  final CulturalPlaceService _placeService = CulturalPlaceService();
  final CulturalPlaceBookmarkService _savedPlaceService =
      CulturalPlaceBookmarkService.instance;
  final BookmarkService _bookmarkService = BookmarkService.instance;
  List<Story> _relatedStories = const [];
  List<CulturalPlace> _nearbyPlaces = const [];
  bool _isLoadingStories = true;
  bool _isLoadingNearby = true;
  String? _relatedStoriesError;

  bool get _canSave => widget.userRole != 'elder';

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
    _bookmarkService.addListener(_handleBookmarksChanged);
    _savedPlaceService.addListener(_handleSavedPlaceChanged);
    _initializeRelatedContent();
    _loadSavedPlace();
  }

  @override
  void dispose() {
    _bookmarkService.removeListener(_handleBookmarksChanged);
    _savedPlaceService.removeListener(_handleSavedPlaceChanged);
    super.dispose();
  }

  Future<void> _initializeRelatedContent() async {
    await Future.wait([_loadRelatedStories(), _loadNearbyPlaces()]);
    try {
      await _bookmarkService.load();
    } catch (_) {
      // The story cards remain usable when bookmark loading is unavailable.
    }
  }

  Future<void> _loadSavedPlace() async {
    try {
      await _savedPlaceService.load();
      if (mounted) {
        setState(() => _isSaved = _savedPlaceService.isSaved(widget.place.id));
      }
    } catch (_) {
      // Keep the state supplied by the map when local storage is unavailable.
    }
  }

  Future<void> _toggleSavedPlace() async {
    if (!_canSave) return;
    final previous = _isSaved;
    setState(() => _isSaved = !previous);
    try {
      await _savedPlaceService.toggle(widget.place.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaved = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved place could not be updated.')),
      );
    }
  }

  void _handleSavedPlaceChanged() {
    if (mounted && _savedPlaceService.isLoaded) {
      setState(() => _isSaved = _savedPlaceService.isSaved(widget.place.id));
    }
  }

  Future<void> _loadRelatedStories() async {
    if (widget.place.relatedStoryIds.isEmpty) {
      if (mounted) setState(() => _isLoadingStories = false);
      return;
    }
    final results = await Future.wait(
      widget.place.relatedStoryIds.map((id) async {
        try {
          return await _storyService.fetchStoryById(id);
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    final stories = results.whereType<Story>().toList(growable: false);
    setState(() {
      _relatedStories = stories;
      _isLoadingStories = false;
      _relatedStoriesError = stories.isEmpty
          ? 'Related stories could not be loaded right now.'
          : null;
    });
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final page = await _placeService.fetchPlaces(limit: 100);
      if (!mounted) return;
      setState(() {
        final nearby = page.items
            .where(
              (place) =>
                  place.id != widget.place.id &&
                  _hasValidCoordinates(place) &&
                  (widget.userLocation != null ||
                      place.district == widget.place.district ||
                      place.province == widget.place.province),
            )
            .toList(growable: false);
        if (widget.userLocation != null) {
          nearby.sort(
            (first, second) =>
                _distanceTo(first).compareTo(_distanceTo(second)),
          );
        }
        _nearbyPlaces = nearby.take(3).toList(growable: false);
        _isLoadingNearby = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  double _distanceTo(CulturalPlace place) => Geolocator.distanceBetween(
    widget.userLocation!.latitude,
    widget.userLocation!.longitude,
    place.latitude,
    place.longitude,
  );

  bool _hasValidCoordinates(CulturalPlace place) =>
      place.latitude >= -90 &&
      place.latitude <= 90 &&
      place.longitude >= -180 &&
      place.longitude <= 180 &&
      !(place.latitude == 0 && place.longitude == 0);

  void _handleBookmarksChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mapBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 245,
            pinned: true,
            backgroundColor: mapBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: _roundAppBarButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back to cultural map',
              onPressed: () => Navigator.of(context).pop(_isSaved),
            ),
            actions: [
              if (_canSave)
                _roundAppBarButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  tooltip: _isSaved ? 'Remove saved place' : 'Save place',
                  onPressed: _toggleSavedPlace,
                ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(place: widget.place),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  widget.place.name,
                  style: const TextStyle(
                    color: mapPrimaryBrown,
                    fontFamily: 'Serif',
                    fontSize: 27,
                    height: 1.15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: mapAccentBrown,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.place.locationLabel,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (widget.place.region.isNotEmpty ||
                    widget.place.languages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.place.region.isNotEmpty)
                        _tag(widget.place.region),
                      ...widget.place.languages.map(_tag),
                    ],
                  ),
                if (widget.place.region.isNotEmpty ||
                    widget.place.languages.isNotEmpty)
                  const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.place.categories.map(
                      (category) => _tag(category.label),
                    ),
                    ...widget.place.tags.take(1).map(_tag),
                  ],
                ),
                const SizedBox(height: 26),
                _sectionTitle('About'),
                const SizedBox(height: 9),
                Text(
                  widget.place.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 27),
                _sectionTitle('Related Cultural Stories'),
                const SizedBox(height: 11),
                _buildRelatedStories(),
                const SizedBox(height: 26),
                _sectionTitle('Local Traditions'),
                const SizedBox(height: 11),
                if (widget.place.traditions.isEmpty)
                  _infoCard(
                    Icons.local_florist_outlined,
                    'Traditions for this place are still being documented.',
                  )
                else
                  for (final tradition in widget.place.traditions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _infoCard(Icons.local_florist_outlined, tradition),
                    ),
                const SizedBox(height: 17),
                _sectionTitle('Nearby Cultural Places'),
                const SizedBox(height: 11),
                if (_isLoadingNearby)
                  const Center(child: CircularProgressIndicator())
                else if (_nearbyPlaces.isEmpty)
                  _infoCard(
                    Icons.explore_outlined,
                    'More nearby places are being documented.',
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearbyPlaces.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => CulturalPlaceCard(
                        place: _nearbyPlaces[index],
                        onTap: () =>
                            Navigator.of(context).pop(_nearbyPlaces[index]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAppBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: mapCardColor.withValues(alpha: 0.94),
          foregroundColor: mapPrimaryBrown,
        ),
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildRelatedStories() {
    if (_isLoadingStories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_relatedStoriesError != null && _relatedStories.isEmpty) {
      return _infoCard(Icons.cloud_off_outlined, _relatedStoriesError!);
    }
    if (_relatedStories.isEmpty) {
      return _infoCard(
        Icons.auto_stories_outlined,
        'Stories from this place will appear here as the cultural archive grows.',
      );
    }
    return Column(
      children: [
        for (final story in _relatedStories)
          YouthStoryCard(
            story: story,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => YouthStoryDetailPage(
                  storyId: story.id,
                  userRole: widget.userRole,
                ),
              ),
            ),
            isBookmarked: _bookmarkService.isBookmarked(story.id),
            onBookmark: widget.userRole == 'elder'
                ? null
                : () async {
                    try {
                      await _bookmarkService.toggle(story.id);
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The bookmark could not be updated.'),
                        ),
                      );
                    }
                  },
          ),
      ],
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: mapPeach.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: mapAccentBrown,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: mapPrimaryBrown,
      fontSize: 19,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _infoCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: mapCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mapAccentBrown.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mapAccentBrown, size: 21),
          const SizedBox(width: 11),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.place});

  final CulturalPlace place;

  @override
  Widget build(BuildContext context) {
    final asset = place.imageAssetPath;
    final imageUrl = place.imageUrl;
    final resolvedImageUrl = imageUrl == null
        ? null
        : imageUrl.startsWith('/uploads/')
        ? '${ApiConfig.baseUrl}$imageUrl'
        : Uri.tryParse(imageUrl)?.scheme == 'http' ||
              Uri.tryParse(imageUrl)?.scheme == 'https'
        ? imageUrl
        : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (asset != null)
          Image.asset(asset, fit: BoxFit.cover)
        else if (resolvedImageUrl != null)
          Image.network(
            resolvedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackImage(),
          )
        else
          _fallbackImage(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x55000000),
                Colors.transparent,
                Color(0x33000000),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: mapPeach,
      child: Icon(place.primaryCategory.icon, size: 88, color: mapAccentBrown),
    );
  }
}
