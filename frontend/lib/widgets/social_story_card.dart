import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../models/story.dart';
import 'author_avatar.dart';

class SocialStoryCard extends StatefulWidget {
  const SocialStoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.authorName = 'Elder Knowledge Keeper',
    this.isBookmarked = false,
    this.onBookmark,
    this.onComment,
  });
  final Story story;
  final VoidCallback onTap;
  final String authorName;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final VoidCallback? onComment;
  @override
  State<SocialStoryCard> createState() => _SocialStoryCardState();
}

class _SocialStoryCardState extends State<SocialStoryCard> {
  static const _ink = Color(0xFF3C261C);
  static const _rust = Color(0xFF984A2B);
  bool _liked = false;

  String get _time {
    final date = widget.story.createdAt;
    if (date == null) return 'Shared story';
    final age = DateTime.now().difference(date);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    if (age.inDays < 7) return '${age.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: '${widget.story.title}\n\n${widget.story.storyText}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story copied. Paste it into a message to share.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final author = story.contributorNames.length > 1
        ? story.displayAuthor
        : story.authorName ?? widget.authorName;
    final image =
        story.bannerImage ??
        (story.additionalImages.isNotEmpty
            ? story.additionalImages.first
            : null);
    final imageCount =
        story.additionalImages.length + (story.bannerImage != null ? 1 : 0);
    return Semantics(
      container: true,
      label: '${story.title}, ${story.category}, ${story.language}',
      child: Material(
        color: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE9DFD3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 12),
                child: Row(
                  children: [
                    AuthorAvatar(
                      name: author,
                      image: story.authorAvatar,
                      radius: 22,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            maxLines: story.contributorNames.length > 1 ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (story.community?.isNotEmpty == true)
                                story.community!,
                              _time,
                            ].join(' \u00b7 '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF88796D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Read full story',
                      onPressed: widget.onTap,
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF88796D),
                      ),
                    ),
                  ],
                ),
              ),
              if (image != null && image.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            image.startsWith('/')
                                ? '${ApiConfig.baseUrl}$image'
                                : image,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const ColoredBox(
                                    color: Color(0xFFEFE6D9),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _rust,
                                      ),
                                    ),
                                  ),
                            errorBuilder: (_, error, trace) => const ColoredBox(
                              color: Color(0xFFEFE6D9),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: _rust,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          if (imageCount > 1)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.collections_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$imageCount photos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (story.audioPath?.isNotEmpty == true)
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.headphones,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Voice story',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip(Icons.grass_outlined, story.category),
                    const SizedBox(height: 8),
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 21,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF625347),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _chip(Icons.language_outlined, story.language),
                    _chip(Icons.schedule, '${story.readingMinutes} min read'),
                    if (story.location?.isNotEmpty == true)
                      _chip(Icons.location_on_outlined, story.location!),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFECE4DA)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: _action(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        _liked ? 'Liked' : 'Like',
                        () => setState(() => _liked = !_liked),
                        active: _liked,
                      ),
                    ),
                    Expanded(
                      child: _action(
                        Icons.chat_bubble_outline_rounded,
                        'Comment',
                        widget.onComment ?? widget.onTap,
                      ),
                    ),
                    Expanded(
                      child: _action(Icons.ios_share_outlined, 'Share', _share),
                    ),
                    if (widget.onBookmark != null)
                      IconButton(
                        tooltip: widget.isBookmarked
                            ? 'Remove bookmark'
                            : 'Save story',
                        onPressed: widget.onBookmark,
                        icon: Icon(
                          widget.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border_rounded,
                          color: _rust,
                          size: 21,
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

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF3ECE2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _rust),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _ink),
          ),
        ),
      ],
    ),
  );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: active ? _rust : const Color(0xFF75675B),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
