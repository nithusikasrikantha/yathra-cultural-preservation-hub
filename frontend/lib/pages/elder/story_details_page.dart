import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/story.dart';
import '../../widgets/author_avatar.dart';
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

  bool _isSaved = false;
  bool _isLiked = false;
  int _likeCount = 24;

  final List<Map<String, dynamic>> _storyComments = [];
  bool _storyCommentsLoading = false;
  bool _posting = false;
  String? _storyCommentsError;
  final AudioPlayer _reader = AudioPlayer();
  StreamSubscription? _readerSubscription;
  bool _reading = false;
  int _readingRequest = 0;
  String? get _storyId => widget.story?.id ?? _getString('_id');
  bool get _realStory => RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(_storyId ?? '');
  @override
  void initState() {
    super.initState();
    _loadComments();
    _readerSubscription = _reader.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _reading = false);
    });
  }

  Future<void> _loadComments() async {
    if (!_realStory) return;
    setState(() => _storyCommentsLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/stories/$_storyId/comments'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200)
        throw Exception('Comments could not be loaded.');
      final data = jsonDecode(response.body);
      if (mounted)
        setState(() {
          _storyComments.clear();
          _storyComments.addAll(
            List<Map<String, dynamic>>.from(data['comments']),
          );
          _storyCommentsError = null;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _storyCommentsError =
              'Comments could not be loaded. Tap to retry.',
        );
    } finally {
      if (mounted) setState(() => _storyCommentsLoading = false);
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _listen() async {
    if (_reading) {
      _readingRequest++;
      await _reader.stop();
      if (mounted) setState(() => _reading = false);
      return;
    }
    if (_content.trim().isEmpty) {
      _message('This story has no written text to read.');
      return;
    }
    final request = ++_readingRequest;
    setState(() => _reading = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/story-speech'),
            headers: await AuthService.authenticatedHeaders(),
            body: jsonEncode({'text': _content, 'language': _language}),
          )
          .timeout(const Duration(seconds: 120));
      if (!mounted || request != _readingRequest) return;
      if (response.statusCode != 200)
        throw Exception(
          jsonDecode(response.body)['message'] ??
              'Story reading is unavailable.',
        );
      await _reader.play(
        BytesSource(response.bodyBytes, mimeType: 'audio/wav'),
      );
    } catch (error) {
      if (mounted && request == _readingRequest) {
        setState(() => _reading = false);
        _message(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

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
  String? get _aiSummary =>
      (widget.story?.summaryStatus ?? _getString('summaryStatus')) == 'approved'
      ? widget.story?.aiSummary ?? _getString('aiSummary')
      : null;

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

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _posting) return;
    if (!_realStory) {
      _message('Comments are available on published stories.');
      return;
    }
    setState(() => _posting = true);
    try {
      final result = await ApiService(baseUrl: ApiConfig.baseUrl).post(
        '/api/stories/$_storyId/comments',
        headers: await AuthService.authenticatedHeaders(),
        body: {'text': text},
        timeout: const Duration(seconds: 15),
      );
      if (mounted)
        setState(() {
          _storyComments.insert(
            0,
            Map<String, dynamic>.from(result['comment']),
          );
          if (_commentController.text.trim() == text)
            _commentController.clear();
        });
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _readingRequest++;
    _readerSubscription?.cancel();
    _reader.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _primaryBrown,
        centerTitle: true,
        title: const Text(
          'YATHRA',
          style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Save story',
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => setState(() => _isSaved = !_isSaved),
          ),
        ],
      ),
      bottomNavigationBar: _buildComposer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _buildMetadataRow(),
                    const SizedBox(height: 14),
                    // Story Title
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                        fontFamily: 'Serif',
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Author and metadata
                    _buildAuthorHeader(),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFE0D7CB)),

                    const SizedBox(height: 18),

                    // AI Summary
                    if (_aiSummary != null && _aiSummary!.isNotEmpty) ...[
                      _buildAiSummaryCard(),
                      const SizedBox(height: 18),
                    ],

                    _buildAudioPlayerCard(),
                    const SizedBox(height: 20),
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
                          fontSize: 19,
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
                    TextButton.icon(
                      onPressed: _copyStory,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text(
                        'Share story',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),

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
        AuthorAvatar(
          name: widget.story?.authorName ?? _getString('authorName') ?? 'Elder',
          image:
              widget.story?.authorAvatar ??
              _getString('authorAvatar') ??
              (widget.storyData?['publishedBy'] is Map
                  ? widget.storyData?['publishedBy']['profileInfo']?['avatar']
                        ?.toString()
                  : null),
          radius: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.story?.authorName ??
                    _getString('authorName') ??
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
  Widget _buildAudioPlayerCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF1EADF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.headphones, color: _primaryBrown, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Read aloud',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBrown,
              minimumSize: const Size(0, 48),
            ),
            onPressed: _listen,
            icon: Icon(_reading ? Icons.stop : Icons.play_arrow),
            label: Text(
              _reading ? 'Stop reading' : 'Listen to Story',
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _copyStory() async {
    await Clipboard.setData(ClipboardData(text: '$_title\n\n$_content'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story copied. Paste it into a message to share.'),
      ),
    );
  }

  Widget _buildCover() => AspectRatio(
    aspectRatio: 16 / 9,
    child: _imageUrl != null && _imageUrl!.isNotEmpty
        ? GestureDetector(
            onTap: () => _openGallery(0),
            child: _storyImage(_imageUrl!),
          )
        : Container(
            color: const Color(0xFFEFE5D9),
            child: const Center(
              child: Icon(Icons.auto_stories, size: 48, color: _accentBrown),
            ),
          ),
  );

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
        'Story photos (${_gallery.length})',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _primaryBrown,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Swipe sideways. Tap a photo to view it.',
        style: TextStyle(fontSize: 15, color: Colors.black54),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _gallery.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _openGallery(
                  i + (_imageUrl != null && _imageUrl!.isNotEmpty ? 1 : 0),
                ),
                child: _storyImage(_gallery[i]),
              ),
            ),
          ),
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
              '${_storyComments.length} Comments',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  // COMMENTS SECTION
  Widget _buildCommentsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Conversation (${_storyComments.length})',
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: _primaryBrown,
          fontFamily: 'Serif',
        ),
      ),
      const SizedBox(height: 16),
      if (_storyCommentsLoading) const LinearProgressIndicator(),
      if (_storyCommentsError != null)
        TextButton(onPressed: _loadComments, child: Text(_storyCommentsError!)),
      if (!_storyCommentsLoading &&
          _storyCommentsError == null &&
          _storyComments.isEmpty)
        const Text(
          'No comments yet. Share a memory or ask a question.',
          style: TextStyle(fontSize: 17, color: Colors.black54),
        ),
      for (final comment in _storyComments)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDCC6AF),
                child: Icon(Icons.person, color: _primaryBrown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['authorName']?.toString() ?? 'Community member',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment['text']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
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
