import 'package:flutter/material.dart';

import '../../models/cultural_place.dart';

const mapBackgroundColor = Color(0xFFF8F3EA);
const mapPrimaryBrown = Color(0xFF4A2C1A);
const mapAccentBrown = Color(0xFF6B4226);
const mapPeach = Color(0xFFEADCC9);
const mapCardColor = Color(0xFFFFFDF8);

class YathraMapHeader extends StatelessWidget implements PreferredSizeWidget {
  const YathraMapHeader({super.key, this.subtitle = 'Cultural Map'});

  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: mapBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_florist, color: mapAccentBrown, size: 18),
              SizedBox(width: 7),
              Text(
                'YATHRA',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: mapPrimaryBrown,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class CulturalMapSearchBar extends StatelessWidget {
  const CulturalMapSearchBar({
    super.key,
    required this.onTap,
    required this.onFilter,
    required this.hasActiveFilters,
  });

  final VoidCallback onTap;
  final VoidCallback onFilter;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 15),
              const Icon(Icons.search_rounded, color: mapAccentBrown),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Search places, districts or cultural topics...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: Colors.black45),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onFilter,
                    tooltip: 'Map filters',
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: mapPrimaryBrown,
                    ),
                  ),
                  if (hasActiveFilters)
                    const Positioned(
                      right: 8,
                      top: 7,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xFFD9534F),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class CulturalMapFilterChips extends StatelessWidget {
  const CulturalMapFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CulturalPlaceCategory? selected;
  final ValueChanged<CulturalPlaceCategory?> onSelected;

  static const categories = <CulturalPlaceCategory>[
    CulturalPlaceCategory.heritage,
    CulturalPlaceCategory.temple,
    CulturalPlaceCategory.food,
    CulturalPlaceCategory.festival,
    CulturalPlaceCategory.story,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _chip(context, label: 'All', category: null),
          for (final category in categories)
            _chip(context, label: category.label, category: category),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required CulturalPlaceCategory? category,
  }) {
    final isSelected = selected == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(category),
        showCheckmark: false,
        selectedColor: mapAccentBrown,
        backgroundColor: mapCardColor,
        side: BorderSide(
          color: isSelected
              ? mapAccentBrown
              : mapAccentBrown.withValues(alpha: 0.18),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : mapPrimaryBrown,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
      ),
    );
  }
}

class CulturalMapMarkerPreview extends StatelessWidget {
  const CulturalMapMarkerPreview({
    super.key,
    required this.place,
    required this.canSave,
    required this.isSaved,
    required this.onDismiss,
    required this.onSave,
    required this.onViewDetails,
  });

  final CulturalPlace place;
  final bool canSave;
  final bool isSaved;
  final VoidCallback onDismiss;
  final VoidCallback onSave;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: BoxDecoration(
        color: mapCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mapAccentBrown.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlaceThumbnail(place: place, size: 74),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mapPrimaryBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${place.primaryCategory.label} • ${place.storyCount} cultural stories',
                        style: const TextStyle(
                          color: mapAccentBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Close preview',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (canSave) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSave,
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                      ),
                      label: Text(isSaved ? 'Saved' : 'Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mapAccentBrown,
                        side: const BorderSide(color: mapAccentBrown),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: canSave ? 2 : 1,
                  child: FilledButton(
                    onPressed: onViewDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: mapAccentBrown,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CulturalPlaceCard extends StatelessWidget {
  const CulturalPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.actionLabel = 'View on Map',
  });

  final CulturalPlace place;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mapCardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 210,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mapAccentBrown.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              _PlaceThumbnail(place: place, size: 58),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mapPrimaryBrown,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${place.district} • ${place.primaryCategory.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: mapAccentBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CulturalMapEmptyState extends StatelessWidget {
  const CulturalMapEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: mapCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mapAccentBrown.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_outlined : Icons.travel_explore,
              color: mapAccentBrown,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mapPrimaryBrown,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _PlaceThumbnail extends StatelessWidget {
  const _PlaceThumbnail({required this.place, required this.size});

  final CulturalPlace place;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = place.imageAssetPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: mapPeach,
        child: asset == null
            ? Icon(place.primaryCategory.icon, color: mapAccentBrown, size: 30)
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  place.primaryCategory.icon,
                  color: mapAccentBrown,
                  size: 30,
                ),
              ),
      ),
    );
  }
}
