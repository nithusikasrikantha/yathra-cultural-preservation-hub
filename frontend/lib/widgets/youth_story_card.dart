import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/youth_dummy_content_store.dart';

class YouthStoryCard extends StatelessWidget {
  const YouthStoryCard({
    super.key,
    required this.story,
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmark,
    this.dummyMetadata,
    this.onLike,
    this.onComment,
  });

  final Story story;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final YouthDummyStoryMetadata? dummyMetadata;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _cardBackground = Color(0xFFFFFDF8);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '${story.title}, ${story.category}, ${story.language}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  if (dummyMetadata != null) ...[
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    story.storyText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StoryMedia(
                    story: story,
                    imageAssetPath: dummyMetadata?.imageAssetPath,
                  ),
                  const SizedBox(height: 14),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final metadata = dummyMetadata;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accentBrown.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            metadata == null
                ? Icons.auto_stories_outlined
                : Icons.person_outline_rounded,
            color: _accentBrown,
            size: metadata == null ? 21 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metadata?.sourceName ?? story.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metadata == null
                    ? _realMetadata
                    : '${metadata.relativeTime} • ${story.language} • ${story.category}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final metadata = dummyMetadata;
    return Row(
      children: [
        if (metadata != null) ...[
          _SocialAction(
            icon: metadata.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            count: metadata.likeCount,
            color: metadata.isLiked ? const Color(0xFFD9534F) : Colors.black54,
            tooltip: metadata.isLiked ? 'Unlike' : 'Like',
            onPressed: onLike,
          ),
          const SizedBox(width: 10),
          _SocialAction(
            icon: Icons.chat_bubble_outline_rounded,
            count: metadata.commentCount,
            color: Colors.black54,
            tooltip: 'Comments',
            onPressed: onComment,
          ),
        ],
        const Spacer(),
        IconButton(
          onPressed: onBookmark,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Save story',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _accentBrown,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Read Story',
          style: TextStyle(
            color: _accentBrown,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_forward_rounded, size: 18, color: _accentBrown),
      ],
    );
  }

  String get _realMetadata {
    final values = <String>[];
    if (story.createdAt != null) values.add(_formatDate(story.createdAt!));
    values
      ..add(story.language)
      ..add(story.category);
    return values.join(' • ');
  }

  static String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }
}

class _SocialAction extends StatelessWidget {
  const _SocialAction({
    required this.icon,
    required this.count,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final int count;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryMedia extends StatelessWidget {
  const _StoryMedia({required this.story, this.imageAssetPath});

  final Story story;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 180,
        color: YouthStoryCard._accentBrown.withValues(alpha: 0.1),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (imageAssetPath case final assetPath?)
              Image.asset(
                assetPath,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _MediaPlaceholder(story: story),
              )
            else
              _MediaPlaceholder(story: story),
            if (story.audioPath != null)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Audio included',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          story.audioPath == null
              ? Icons.menu_book_rounded
              : Icons.graphic_eq_rounded,
          size: 48,
          color: YouthStoryCard._accentBrown,
        ),
        const SizedBox(height: 8),
        Text(
          story.category,
          style: const TextStyle(
            color: YouthStoryCard._primaryBrown,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
