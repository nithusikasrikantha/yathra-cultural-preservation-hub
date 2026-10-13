import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/story.dart';
import '../../config/api_config.dart';

class StoryDetailsPage extends StatefulWidget {
  const StoryDetailsPage({super.key, this.story, this.storyData});

  final Story? story;
  final Map<String, dynamic>? storyData;

  @override
  State<StoryDetailsPage> createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends State<StoryDetailsPage> {
  static const Color _bgColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);

  int _coverIndex = 0;
  bool _isSaved = false;
  bool _isLiked = false;
  int _likeCount = 24;

  final List<String> _comments = [
    'Amma, this brings back so many childhood memories from our village.',
    'Thank you for preserving this traditional wisdom for us!',
  ];

  final TextEditingController _commentController = TextEditingController();

  String? _getString(String key) {
    final value = widget.storyData?[key];
    if (value == null) return null;
    return value.toString();
  }

  String get _title =>
      widget.story?.title ?? _getString('title') ?? 'Cultural Story';

  String get _category =>
      widget.story?.category ?? _getString('category') ?? 'Traditional Story';

  String get _language =>
      widget.story?.language ?? _getString('language') ?? 'Tamil';

  String get _content =>
      widget.story?.storyText ?? _getString('storyText') ?? '';

  String? get _audioPath => widget.story?.audioPath ?? _getString('audioPath');

  String? get _location => widget.story?.location ?? _getString('location');
  String? get _timePeriod =>
      widget.story?.timePeriod ?? _getString('timePeriod');
  String? get _community => widget.story?.community ?? _getString('community');
  String? get _imageUrl =>
      widget.story?.bannerImage ??
      _getString('bannerImage') ??
      _getString('imageUrl');
  List<String> get _gallery =>
      widget.story?.additionalImages ??
      List<String>.from(widget.storyData?['additionalImages'] ?? []);
  List<String> get _allImages => [
    if (_imageUrl != null && _imageUrl!.isNotEmpty) _imageUrl!,
    ..._gallery,
  ];
  String _resolveImage(String value) =>
      value.startsWith('/') ? '${ApiConfig.baseUrl}$value' : value;
  String? get _aiSummary => _getString('aiSummary');

  List<String> get _tags {
    if (widget.story != null) {
      return widget.story!.tags;
    }
    final dataTags = widget.storyData?['tags'];
    if (dataTags is List) {
      return dataTags.map((tag) => tag.toString()).toList();
    }
    return const [];
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(text);
      _commentController.clear();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: _buildComposer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAudioPlayerCard(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story Title
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                        fontFamily: 'Serif',
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Author and metadata
                    _buildAuthorHeader(),
                    const SizedBox(height: 16),
                    _buildMetadataRow(),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE0D7CB)),

                    const SizedBox(height: 18),

                    // AI Summary
                    if (_aiSummary != null && _aiSummary!.isNotEmpty) ...[
                      _buildAiSummaryCard(),
                      const SizedBox(height: 18),
                    ],

                    // Full Story Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: _bgColor),
                      child: Text(
                        _content.isNotEmpty
                            ? _content
                            : 'Preserved cultural story passed down through generations.',
                        style: const TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 21,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tags
                    if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _accentBrown.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _accentBrown,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_gallery.isNotEmpty) ...[
                      _buildGallery(),
                      const SizedBox(height: 20),
                    ],
                    // Action Bar
                    _buildActionBar(),

                    const SizedBox(height: 24),

                    // Comments
                    _buildCommentsSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AUTHOR HEADER
  Widget _buildAuthorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _accentBrown.withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: _primaryBrown, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elder Knowledge Keeper',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Preserving heritage • $_language',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // METADATA
  Widget _buildMetadataRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaChip(Icons.category_outlined, _category),
        _buildMetaChip(Icons.language_outlined, _language),
        if (_location != null && _location!.isNotEmpty)
          _buildMetaChip(Icons.location_on_outlined, '📍 $_location'),
        if (_timePeriod != null && _timePeriod!.isNotEmpty)
          _buildMetaChip(Icons.history_outlined, '⏳ $_timePeriod'),
        if (_community != null && _community!.isNotEmpty)
          _buildMetaChip(Icons.people_outline, '👥 $_community'),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _accentBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentBrown),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _accentBrown,
            ),
          ),
        ],
      ),
    );
  }

  // AUDIO PLAYER
  Widget _buildAudioPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EADF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _primaryBrown.withValues(alpha: .13),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: 'Listen to story',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF984A2B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _audioPath == null || _audioPath!.isEmpty
                      ? 'This story has no voice recording yet.'
                      : 'Voice playback is not available yet.',
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 30),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listen to Story',
                  style: TextStyle(fontSize: 14, color: _primaryBrown),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 20,
                        child: CustomPaint(painter: _WaveformPainter()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '00:00',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyStory() async {
    await Clipboard.setData(ClipboardData(text: '$_title\n\n$_content'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story copied. Paste it into a message to share.'),
      ),
    );
  }

  Widget _buildCover() {
    final fallback = Image.asset(
      'assets/images/story_landscape.jpg',
      fit: BoxFit.cover,
    );
    return SizedBox(
      height: 265,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_allImages.isNotEmpty)
            PageView.builder(
              itemCount: _allImages.length,
              onPageChanged: (index) => setState(() => _coverIndex = index),
              itemBuilder: (_, index) => GestureDetector(
                onTap: () => _openGallery(index),
                child: _storyImage(_allImages[index]),
              ),
            )
          else
            fallback,
          if (_allImages.length > 1)
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _allImages.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _coverIndex ? Colors.white : Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 10,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                if (_allImages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_coverIndex + 1} / ${_allImages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                IconButton(
                  tooltip: _isSaved ? 'Unsave story' : 'Save story',
                  onPressed: () => setState(() => _isSaved = !_isSaved),
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Share story',
                  onPressed: _copyStory,
                  icon: const Icon(
                    Icons.ios_share_outlined,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onSelected: (_) => _copyStory(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy story text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storyImage(String image) => Image.network(
    _resolveImage(image),
    fit: BoxFit.cover,
    errorBuilder: (_, error, trace) => const ColoredBox(
      color: Color(0xFFE8DDCD),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: _accentBrown),
      ),
    ),
  );

  Widget _buildGallery() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Archival Gallery (${_gallery.length})',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _primaryBrown,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            for (var i = 0; i < _gallery.length && i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              SizedBox(
                width: (constraints.maxWidth - 24) / 4,
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: GestureDetector(
                    onTap: () => _openGallery(
                      i + (_imageUrl != null && _imageUrl!.isNotEmpty ? 1 : 0),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _storyImage(_gallery[i]),
                        if (i == 3 && _gallery.length > 4)
                          ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+${_gallery.length - 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Tap to expand',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
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
            ],
          ],
        ),
      ),
    ],
  );

  void _openGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StoryGallery(
          images: _allImages.map(_resolveImage).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildComposer() => Container(
    decoration: const BoxDecoration(
      color: _bgColor,
      border: Border(top: BorderSide(color: Color(0xFFE5DCCF))),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Share a memory...',
                  filled: true,
                  fillColor: _bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: _accentBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFFB48E77)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 46),
                backgroundColor: const Color(0xFF984A2B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: _addComment,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    ),
  );

  // AI SUMMARY
  Widget _buildAiSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8A9A5B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8A9A5B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF4A5D23),
              ),
              const SizedBox(width: 8),
              Text(
                'Suggested by YATHRA AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _aiSummary!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // LIKE / COMMENT ACTION BAR
  Widget _buildActionBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _isLiked = !_isLiked;
              _isLiked ? _likeCount++ : _likeCount--;
            });
          },
          child: Row(
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                color: _isLiked ? Colors.red : Colors.black54,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                '$_likeCount Likes',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 22,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              '${_comments.length} Comments',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  // COMMENTS SECTION
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memories & Responses (${_comments.length})',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 12),

        // Comment List
        for (final comment in _comments)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE5D9),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDCC6AF),
                  child: Icon(
                    Icons.person_outline,
                    color: _accentBrown,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _comments.indexOf(comment) < 2
                            ? 'Community member'
                            : 'You',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const heights = [
      5,
      10,
      8,
      16,
      12,
      20,
      7,
      13,
      18,
      10,
      6,
      16,
      20,
      11,
      15,
      8,
      19,
      13,
      6,
      10,
      17,
      8,
      14,
      20,
      9,
      15,
      7,
      12,
      18,
      6,
      13,
      10,
    ];
    final paint = Paint()
      ..color = const Color(0xFFAF9580)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < heights.length; i++) {
      final x = (i + .5) * size.width / heights.length;
      canvas.drawLine(
        Offset(x, (size.height - heights[i]) / 2),
        Offset(x, (size.height + heights[i]) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => false;
}

class _StoryGallery extends StatefulWidget {
  const _StoryGallery({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;
  @override
  State<_StoryGallery> createState() => _StoryGalleryState();
}

class _StoryGalleryState extends State<_StoryGallery> {
  late final PageController _controller;
  late int _index;
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('${_index + 1} / ${widget.images.length}'),
    ),
    body: PageView.builder(
      controller: _controller,
      itemCount: widget.images.length,
      onPageChanged: (index) => setState(() => _index = index),
      itemBuilder: (_, index) => InteractiveViewer(
        child: Center(
          child: Image.network(
            widget.images[index],
            fit: BoxFit.contain,
            errorBuilder: (_, error, trace) => const Text(
              'Unable to load photo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}
