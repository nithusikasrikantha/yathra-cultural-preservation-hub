import 'package:flutter/material.dart';

import '../models/story.dart';
import '../services/story_comment_service.dart';

class YouthStoryCommentsSheet extends StatefulWidget {
  const YouthStoryCommentsSheet({
    super.key,
    required this.story,
    required this.service,
  });

  final Story story;
  final StoryCommentService service;

  @override
  State<YouthStoryCommentsSheet> createState() =>
      _YouthStoryCommentsSheetState();
}

class _YouthStoryCommentsSheetState extends State<YouthStoryCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<StoryComment> _comments = const [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final comments = await widget.service.fetchComments(widget.story.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Comments could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _postComment() async {
    final text = _controller.text.trim();
    if (_isPosting) return;
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Write a comment before posting.');
      return;
    }
    if (text.length > 2000) {
      setState(
        () => _errorMessage = 'Comments must be 2,000 characters or fewer.',
      );
      return;
    }

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });
    try {
      final comment = await widget.service.addComment(
        storyId: widget.story.id,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _isPosting = false;
      });
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPosting = false;
        _errorMessage = 'Comment could not be posted. Please try again.';
      });
    }
  }

  String _timestamp(DateTime? value) {
    if (value == null) return 'Just now';
    final age = DateTime.now().difference(value.toLocal());
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    if (age.inDays < 7) return '${age.inDays}d ago';
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          14,
          18,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comments for ${widget.story.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4A2C1A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close comments',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildCommentList()),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFF9B2C2C)),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isPosting,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: 'Add a comment',
                        hintText: 'Share a thought about this story',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isPosting ? null : _postComment,
                    tooltip: 'Post comment',
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentList() {
    if (_isLoading) {
      return Center(
        child: Semantics(
          label: 'Loading comments',
          liveRegion: true,
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorMessage != null && _comments.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadComments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry loading comments'),
        ),
      );
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'No comments yet. Be the first to share a thought.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Semantics(
          container: true,
          label:
              '${comment.authorName}, ${_timestamp(comment.createdAt)}. ${comment.text}',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: comment.authorAvatar == null
                    ? null
                    : NetworkImage(comment.authorAvatar!),
                child: comment.authorAvatar == null
                    ? const Icon(Icons.person_outline_rounded)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A2C1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _timestamp(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(comment.text),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
