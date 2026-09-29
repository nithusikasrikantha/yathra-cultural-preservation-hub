import 'package:flutter/material.dart';

import '../models/story.dart';

class YouthStoryCard extends StatelessWidget {
  const YouthStoryCard({
    super.key,
    required this.story,
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmark,
  });

  final Story story;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmark;

  static const Color _primaryBrown = Color(0xFF6B4226);
  static const Color _darkBrown = Color(0xFF4A2C1A);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '${story.title}, ${story.category}, ${story.language}',
      child: Card(
        color: Colors.white,
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: onBookmark,
                      tooltip: isBookmarked ? 'Remove bookmark' : 'Save story',
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: _primaryBrown,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Read full story',
                      style: TextStyle(
                        color: _primaryBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      size: 19,
                      color: _primaryBrown,
                    ),
                  ],
                ),
              ],
            ),
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
          Icon(icon, size: 17, color: YouthStoryCard._primaryBrown),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YouthStoryCard._darkBrown,
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
