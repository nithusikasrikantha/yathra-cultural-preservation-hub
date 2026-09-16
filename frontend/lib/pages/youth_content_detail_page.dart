import 'package:flutter/material.dart';

import '../models/cultural_story.dart';

class YouthContentDetailPage extends StatelessWidget {
  const YouthContentDetailPage({super.key, required this.story});

  final CulturalStory story;

  static const Color _bgColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryBrown,
        foregroundColor: Colors.white,
        title: const Text(
          'Story Details',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Semantics(
            label: 'Bookmark ${story.title} placeholder',
            button: true,
            child: IconButton(
              tooltip: 'Bookmark',
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _MediaPlaceholder(story: story),
            const SizedBox(height: 22),
            Text(
              story.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailPill(text: story.category),
                _DetailPill(text: story.language),
                _DetailPill(text: story.region),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'By ${story.contributor}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _primaryBrown,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.story});

  final CulturalStory story;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);
  static const Color _softGold = Color(0xFFE9C46A);

  @override
  Widget build(BuildContext context) {
    final _MediaPlaceholderData data = _placeholderData(story.mediaType);

    return Semantics(
      label: '${data.label} for ${story.title}',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 210),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: _softGold.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _primaryBrown.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: _primaryBrown, size: 42),
            ),
            const SizedBox(height: 14),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MediaPlaceholderData _placeholderData(String? mediaType) {
    switch (mediaType?.toLowerCase()) {
      case 'image':
        return const _MediaPlaceholderData(
          icon: Icons.image,
          title: 'Image placeholder',
          subtitle: 'Visual media will appear here in a future update.',
          label: 'Image media placeholder',
        );
      case 'audio':
        return const _MediaPlaceholderData(
          icon: Icons.graphic_eq,
          title: 'Audio placeholder',
          subtitle: 'Audio playback will be added later.',
          label: 'Audio media placeholder',
        );
      case 'video':
        return const _MediaPlaceholderData(
          icon: Icons.play_circle_outline,
          title: 'Video placeholder',
          subtitle: 'Video playback will be added later.',
          label: 'Video media placeholder',
        );
      default:
        return const _MediaPlaceholderData(
          icon: Icons.perm_media,
          title: 'Media placeholder',
          subtitle: 'Story media will appear here in a future update.',
          label: 'Generic media placeholder',
        );
    }
  }
}

class _MediaPlaceholderData {
  const _MediaPlaceholderData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.text});

  final String text;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _primaryBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _darkBrown,
        ),
      ),
    );
  }
}
