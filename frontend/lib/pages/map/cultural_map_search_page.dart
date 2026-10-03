import 'package:flutter/material.dart';

import '../../data/cultural_map_dummy_data.dart';
import '../../models/cultural_place.dart';
import '../../widgets/map/cultural_map_widgets.dart';

class CulturalMapSearchPage extends StatefulWidget {
  const CulturalMapSearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<CulturalMapSearchPage> createState() => _CulturalMapSearchPageState();
}

class _CulturalMapSearchPageState extends State<CulturalMapSearchPage> {
  late final TextEditingController _controller;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = CulturalMapDummyData.places
        .where((place) => place.matches(_query))
        .toList(growable: false);
    final regions = CulturalMapDummyData.regions
        .where(
          (region) => region.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: mapBackgroundColor,
      appBar: AppBar(
        backgroundColor: mapBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Search Cultural Map',
          style: TextStyle(color: mapPrimaryBrown, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search places, districts or topics...',
                  prefixIcon: const Icon(Icons.search, color: mapAccentBrown),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildResults(places, regions)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    List<CulturalPlace> places,
    List<CulturalRegion> regions,
  ) {
    if (_query.trim().isNotEmpty && places.isEmpty && regions.isEmpty) {
      return CulturalMapEmptyState(
        title: 'No cultural places found',
        message: 'Try a different place, region, or cultural topic.',
        actionLabel: 'Clear Search',
        onAction: () {
          _controller.clear();
          setState(() => _query = '');
        },
      );
    }

    final shownPlaces = _query.trim().isEmpty
        ? CulturalMapDummyData.places.take(4).toList(growable: false)
        : places;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        _sectionLabel(_query.trim().isEmpty ? 'SUGGESTED PLACES' : 'PLACES'),
        const SizedBox(height: 8),
        for (final place in shownPlaces)
          _SearchResultTile(
            icon: place.primaryCategory.icon,
            title: place.name,
            subtitle: '${place.district} • ${place.primaryCategory.label}',
            onTap: () => Navigator.of(context).pop(place),
          ),
        if (regions.isNotEmpty || _query.trim().isEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('REGIONS'),
          const SizedBox(height: 8),
          for (final region
              in _query.trim().isEmpty ? CulturalMapDummyData.regions : regions)
            _SearchResultTile(
              icon: Icons.public_rounded,
              title: '${region.name} Cultural Stories',
              subtitle:
                  '${region.province} Province • ${region.storyCount} stories',
              onTap: () {
                final match = CulturalMapDummyData.places.firstWhere(
                  (place) => place.district == region.name,
                );
                Navigator.of(context).pop(match);
              },
            ),
        ],
        if (_query.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('STORIES'),
          const SizedBox(height: 8),
          _SearchResultTile(
            icon: Icons.auto_stories_outlined,
            title: 'Stories connected to “${_query.trim()}”',
            subtitle:
                '${places.fold<int>(0, (sum, place) => sum + place.storyCount)} cultural stories',
            onTap: places.isEmpty
                ? null
                : () => Navigator.of(context).pop(places.first),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: mapAccentBrown,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: mapCardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: mapAccentBrown.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        minTileHeight: 66,
        leading: CircleAvatar(
          backgroundColor: mapPeach.withValues(alpha: 0.75),
          child: Icon(icon, color: mapAccentBrown, size: 21),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: mapPrimaryBrown,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.north_west_rounded, size: 18),
      ),
    );
  }
}
