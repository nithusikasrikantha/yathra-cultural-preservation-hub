import 'package:flutter/material.dart';

import '../../data/cultural_map_dummy_data.dart';
import '../../models/cultural_place.dart';
import '../../services/youth_dummy_content_store.dart';
import '../../widgets/map/cultural_map_widgets.dart';
import '../../widgets/youth_story_card.dart';
import '../youth_story_detail_page.dart';

class CulturalPlaceDetailPage extends StatefulWidget {
  const CulturalPlaceDetailPage({
    super.key,
    required this.place,
    required this.userRole,
    required this.initiallySaved,
  });

  final CulturalPlace place;
  final String userRole;
  final bool initiallySaved;

  @override
  State<CulturalPlaceDetailPage> createState() =>
      _CulturalPlaceDetailPageState();
}

class _CulturalPlaceDetailPageState extends State<CulturalPlaceDetailPage> {
  late bool _isSaved;

  bool get _canSave => widget.userRole != 'elder';

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
  }

  @override
  Widget build(BuildContext context) {
    final relatedStories = widget.place.relatedStoryIds
        .map(YouthDummyContentStore.instance.storyById)
        .whereType()
        .toList(growable: false);
    final nearby = CulturalMapDummyData.places
        .where(
          (place) =>
              place.id != widget.place.id &&
              (place.district == widget.place.district ||
                  place.province == widget.place.province),
        )
        .take(3)
        .toList(growable: false);

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
              onPressed: () => Navigator.of(context).pop(_isSaved),
            ),
            actions: [
              if (_canSave)
                _roundAppBarButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  onPressed: () => setState(() => _isSaved = !_isSaved),
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
                if (relatedStories.isEmpty)
                  _infoCard(
                    Icons.auto_stories_outlined,
                    'Stories from this place will appear here as the cultural archive grows.',
                  )
                else
                  for (final story in relatedStories)
                    YouthStoryCard(
                      story: story,
                      dummyMetadata: YouthDummyContentStore.instance
                          .metadataFor(story.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => YouthStoryDetailPage(
                            storyId: story.id,
                            preloadedStory: story,
                            userRole: widget.userRole,
                          ),
                        ),
                      ),
                      isBookmarked: YouthDummyContentStore.instance
                          .isBookmarked(story.id),
                      onBookmark: widget.userRole == 'elder'
                          ? null
                          : () => setState(
                              () => YouthDummyContentStore.instance
                                  .toggleBookmark(story.id),
                            ),
                    ),
                const SizedBox(height: 26),
                _sectionTitle('Local Traditions'),
                const SizedBox(height: 11),
                for (final tradition in widget.place.traditions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _infoCard(Icons.local_florist_outlined, tradition),
                  ),
                const SizedBox(height: 17),
                _sectionTitle('Nearby Cultural Places'),
                const SizedBox(height: 11),
                if (nearby.isEmpty)
                  _infoCard(
                    Icons.explore_outlined,
                    'More nearby places are being documented.',
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearby.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => CulturalPlaceCard(
                        place: nearby[index],
                        onTap: () => Navigator.of(context).pop(nearby[index]),
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
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: mapCardColor.withValues(alpha: 0.94),
          foregroundColor: mapPrimaryBrown,
        ),
        icon: Icon(icon),
      ),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (asset != null)
          Image.asset(asset, fit: BoxFit.cover)
        else
          Container(
            color: mapPeach,
            child: Icon(
              place.primaryCategory.icon,
              size: 88,
              color: mapAccentBrown,
            ),
          ),
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
}
