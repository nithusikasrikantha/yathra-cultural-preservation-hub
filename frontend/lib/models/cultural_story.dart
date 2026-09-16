import 'package:flutter/material.dart';

class CulturalStory {
  const CulturalStory({
    required this.title,
    required this.category,
    required this.language,
    required this.region,
    required this.contributor,
    required this.description,
    required this.icon,
    this.mediaType,
  });

  final String title;
  final String category;
  final String language;
  final String region;
  final String contributor;
  final String description;
  final IconData icon;
  final String? mediaType;

  bool matchesTag(String tag) {
    final String normalizedTag = tag.toLowerCase();

    return language.toLowerCase() == normalizedTag ||
        category.toLowerCase() == normalizedTag;
  }
}
