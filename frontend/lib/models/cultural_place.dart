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
    this.imageUrl,
    this.region = '',
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
  final String? imageUrl;
  final String region;
  final List<String> relatedStoryIds;
  final List<String> traditions;

  factory CulturalPlace.fromJson(Map<String, dynamic> json) {
    final categories = _stringList(
      json['categories'] ?? json['category'],
    ).map(_categoryFromString).toSet().toList(growable: false);
    return CulturalPlace(
      id: _stringValue(json['_id'] ?? json['id']),
      name: _stringValue(json['name'] ?? json['title']),
      description: _stringValue(json['description']),
      province: _stringValue(json['province']),
      district: _stringValue(json['district']),
      region: _stringValue(json['region']),
      categories: categories.isEmpty
          ? const [CulturalPlaceCategory.heritage]
          : categories,
      latitude: _numberValue(json['latitude']),
      longitude: _numberValue(json['longitude']),
      tags: _stringList(json['tags']),
      languages: _stringList(json['languages'] ?? json['language']),
      storyCount:
          _intValue(json['storyCount']) ??
          _stringList(json['relatedStoryIds']).length,
      imageUrl: _optionalString(json['imageUrl'] ?? json['image']),
      relatedStoryIds: _stringList(json['relatedStoryIds']),
      traditions: _stringList(json['traditions']),
    );
  }

  String get locationLabel => '$district, $province Province';
  CulturalPlaceCategory get primaryCategory =>
      categories.isEmpty ? CulturalPlaceCategory.heritage : categories.first;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      description,
      province,
      district,
      ...tags,
      region,
      ...languages,
      ...traditions,
      ...categories.map((category) => category.label),
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  static CulturalPlaceCategory _categoryFromString(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return switch (normalized) {
      'temple' || 'temples' => CulturalPlaceCategory.temple,
      'food' || 'traditionalfood' || 'recipe' => CulturalPlaceCategory.food,
      'festival' || 'festivals' => CulturalPlaceCategory.festival,
      'musicdance' || 'music' || 'dance' => CulturalPlaceCategory.musicDance,
      'craft' || 'crafts' => CulturalPlaceCategory.craft,
      'historical' ||
      'historicalplaces' ||
      'history' => CulturalPlaceCategory.historical,
      'folklore' => CulturalPlaceCategory.folklore,
      'story' || 'stories' => CulturalPlaceCategory.story,
      _ => CulturalPlaceCategory.heritage,
    };
  }

  static String _stringValue(dynamic value) =>
      value is String ? value.trim() : '';

  static String? _optionalString(dynamic value) {
    final result = _stringValue(value);
    return result.isEmpty ? null : result;
  }

  static double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _intValue(dynamic value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }
    if (value is num) {
      return value.toInt().clamp(0, 1 << 30);
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String> _stringList(dynamic value) {
    if (value is String) {
      return value.trim().isEmpty ? const [] : [value.trim()];
    }
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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
