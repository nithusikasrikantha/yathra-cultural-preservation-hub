import 'package:flutter/material.dart';

enum CulturalPlaceCategory {
  heritage('Heritage', Icons.account_balance_outlined),
  temple('Temples', Icons.temple_hindu_outlined),
  food('Traditional Food', Icons.restaurant_outlined),
  festival('Festivals', Icons.celebration_outlined),
  musicDance('Music & Dance', Icons.music_note_outlined),
  craft('Crafts', Icons.palette_outlined),
  historical('Historical Places', Icons.fort_outlined),
  folklore('Folklore', Icons.auto_stories_outlined),
  story('Stories', Icons.menu_book_outlined);

  const CulturalPlaceCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class CulturalPlace {
  const CulturalPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.province,
    required this.district,
    required this.categories,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.languages,
    required this.storyCount,
    this.imageAssetPath,
    this.relatedStoryIds = const [],
    this.traditions = const [],
  });

  final String id;
  final String name;
  final String description;
  final String province;
  final String district;
  final List<CulturalPlaceCategory> categories;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final List<String> languages;
  final int storyCount;
  final String? imageAssetPath;
  final List<String> relatedStoryIds;
  final List<String> traditions;

  String get locationLabel => '$district, $province Province';
  CulturalPlaceCategory get primaryCategory => categories.first;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      description,
      province,
      district,
      ...tags,
      ...categories.map((category) => category.label),
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class CulturalRegion {
  const CulturalRegion({
    required this.name,
    required this.province,
    required this.storyCount,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String province;
  final int storyCount;
  final double latitude;
  final double longitude;
}
