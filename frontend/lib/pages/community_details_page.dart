import 'package:flutter/material.dart';

import '../models/community_theme.dart';
import '../theme/app_theme.dart';

/// Reusable Community Details Page (Page 4 in the required flow)
class CommunityDetailsPage extends StatefulWidget {
  final CulturalTheme theme;

  const CommunityDetailsPage({super.key, required this.theme});

  @override
  State<CommunityDetailsPage> createState() => _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends State<CommunityDetailsPage> {
  static const Color _backgroundColor = Color(0xFFF8F3EA);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _lightTan = Color(0xFFEADCC9);

  late bool _isJoined;
  int _selectedTabIndex = 1; // Default to 'Discussions' or 'About'

  final List<String> _tabs = const ['About', 'Discussions', 'Elders', 'Photos'];

  @override
  void initState() {
    super.initState();
    _isJoined = widget.theme.isJoined;
  }

  void _toggleJoinCommunity() {
    setState(() {
      _isJoined = !_isJoined;
      widget.theme.isJoined = _isJoined;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isJoined
              ? 'You joined "${widget.theme.title}"!'
              : 'You left "${widget.theme.title}".',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _accentBrown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBrown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined, color: _primaryBrown),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share "${widget.theme.title}" link copied!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: _accentBrown,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Area / Community Header
              _buildCommunityHeader(),

              const SizedBox(height: 20),

              // Navigation Tabs (About, Discussions, Elders, Photos)
              _buildTabsRow(),

              const SizedBox(height: 24),

              // Knowledge Shared by Elders Section Header
              Text(
                'Knowledge Shared by Elders',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),

              const SizedBox(height: 14),

              // Scrollable Elder Posts List
              if (widget.theme.knowledgePosts.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.theme.knowledgePosts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = widget.theme.knowledgePosts[index];
                    return _ElderKnowledgeCard(post: post);
                  },
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Community Title
        Text(
          widget.theme.title,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        // Member/Elder Count Information
        Text(
          '${widget.theme.membersCount}  •  ${widget.theme.activeEldersCount}',
          style: TextStyle(
            color: _primaryBrown.withValues(alpha: 0.75),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 16),

        // Join Community Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _toggleJoinCommunity,
            icon: Icon(
              _isJoined ? Icons.check : Icons.person_add_outlined,
              color: _isJoined ? _primaryBrown : Colors.white,
              size: 20,
            ),
            label: Text(
              _isJoined ? 'Joined' : 'Join Community',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _isJoined ? _primaryBrown : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isJoined ? _lightTan : _primaryBrown,
              elevation: _isJoined ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _isJoined
                    ? const BorderSide(color: _accentBrown, width: 1.2)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2D6C5), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? _primaryBrown : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? _primaryBrown
                      : _primaryBrown.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No elder knowledge shared yet in this community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _primaryBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card component representing individual Elder-shared knowledge content
class _ElderKnowledgeCard extends StatefulWidget {
  final ElderKnowledgePost post;

  const _ElderKnowledgeCard({required this.post});

  @override
  State<_ElderKnowledgeCard> createState() => _ElderKnowledgeCardState();
}

class _ElderKnowledgeCardState extends State<_ElderKnowledgeCard> {
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);

  late bool _isConnected;
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isConnected = widget.post.isConnected;
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
  }

  void _toggleConnect() {
    setState(() {
      _isConnected = !_isConnected;
      widget.post.isConnected = _isConnected;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isConnected
              ? 'Connected with ${widget.post.elderName}'
              : 'Disconnected from ${widget.post.elderName}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _accentBrown,
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount--;
      }
      widget.post.isLiked = _isLiked;
      widget.post.likesCount = _likesCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Role & Time, Connect Button, Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  widget.post.avatarUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      color: AppTheme.accentColor,
                      child: const Icon(
                        Icons.person,
                        color: _primaryBrown,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Elder Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.elderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.post.elderRole,
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryBrown.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Connect Button
              OutlinedButton.icon(
                onPressed: _toggleConnect,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: _isConnected ? Colors.grey.shade400 : _primaryBrown,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: _isConnected
                      ? Colors.grey.shade100
                      : Colors.transparent,
                ),
                icon: Icon(
                  _isConnected ? Icons.check : Icons.person_add_alt_1,
                  size: 14,
                  color: _isConnected ? Colors.grey.shade700 : _primaryBrown,
                ),
                label: Text(
                  _isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.grey.shade700 : _primaryBrown,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // More options
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_vert,
                  color: _primaryBrown.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Knowledge Title
          Text(
            widget.post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryBrown,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          // Content Layout (Image + Text)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.post.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.post.imageUrl!,
                    width: 90,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 70,
                        color: const Color(0xFFEADCC9),
                        child: const Icon(
                          Icons.image_outlined,
                          color: _primaryBrown,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.post.snippet,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _primaryBrown.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Social Stats Bar (Likes & Comments)
          Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _isLiked
                          ? Colors.red.shade700
                          : Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_likesCount Likes',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _primaryBrown.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: _primaryBrown.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.post.commentsCount} Comments',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _primaryBrown.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
