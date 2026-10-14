import 'elder/story_details_page.dart';
import 'package:flutter/material.dart';
import '../models/community_theme.dart';
import '../models/story.dart';
import '../services/community_service.dart';
import '../services/culture_connect_service.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';
import '../services/published_content_signal.dart';
import '../widgets/social_story_card.dart';
import 'elder/share_story_page.dart';
import 'youth_story_detail_page.dart';
import 'culture_connect_pages.dart';

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

  late bool _isFollowing;
  int _selectedTabIndex = 1; // Default to 'Discussions' or 'About'

  final List<String> _tabs = const ['About', 'Discussions', 'Photos'];

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.theme.isFollowing;
    _load();
  }

  bool _busy = false;
  String? _error;
  String? _members;
  String? _role;
  List<Story> _stories = [];

  Future<void> _load() async {
    try {
      final communities = await CommunityService().list();
      final community = communities.firstWhere((c) => c.id == widget.theme.id);
      final role = await AuthService.currentRole();
      final page = await const StoryService().fetchStories(
        page: 1,
        limit: 50,
        communityId: community.id,
      );
      if (!mounted) return;
      setState(() {
        _members = community.membersCount;
        _isFollowing = community.isFollowing;
        _role = role;
        _stories = page.items;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not load this community. Tap to retry.');
    }
  }

  Future<void> _toggleFollowCommunity() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isFollowing
              ? 'Unfollow ${widget.theme.title}?'
              : 'Follow ${widget.theme.title}?',
        ),
        content: Text(
          '${widget.theme.description}\n\n${_isFollowing ? 'Its posts will leave your Following feed.' : 'Its published stories will appear in your Following feed. Elders can share knowledge here; youth can contribute through collaboration.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await CommunityService().follow(
        widget.theme.id,
        !_isFollowing,
      );
      if (!mounted) return;
      setState(() {
        _isFollowing = result['isFollowing'];
        widget.theme.isFollowing = _isFollowing;
        _members = '${result['membersCount']} members';
      });
      PublishedContentSignal.notify();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update following. Please retry.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addStory() async {
    if (_role == 'elder') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShareStoryPage(
            communityId: widget.theme.id,
            communityName: widget.theme.title,
          ),
        ),
      );
      await _load();
    } else {
      await _findElder();
    }
  }

  Future<void> _findElder() async {
    try {
      final service = CultureConnectService();
      final elders = await service.getElders();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Choose an elder to collaborate with'),
              ),
              if (elders.isEmpty)
                const ListTile(title: Text('No elders available yet.')),
              for (final elder in elders)
                ListTile(
                  title: Text(elder.name),
                  trailing: const Icon(Icons.person_add_outlined),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      final connection = await service.request(
                        elder.id,
                        widget.theme.id,
                        widget.theme.title,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            connection.communityId.isNotEmpty &&
                                    connection.communityId != widget.theme.id
                                ? 'Your existing connection belongs to ${connection.communityName}. Its workspace destination remains unchanged.'
                                : 'Connection request saved. Continue in My Connections after acceptance.',
                          ),
                        ),
                      );
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MyConnectionsPage(isElder: false),
                        ),
                      );
                    } catch (_) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not request this connection. Please retry.',
                            ),
                          ),
                        );
                    }
                  },
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load elders. Please retry.')),
        );
    }
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
      floatingActionButton: _isFollowing && _role != null
          ? FloatingActionButton.extended(
              onPressed: _addStory,
              backgroundColor: _accentBrown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(_role == 'elder' ? 'Add Story' : 'Collaborate'),
            )
          : null,
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

              // Navigation Tabs (About, Discussions, Photos)
              _buildTabsRow(),

              const SizedBox(height: 24),

              ...[
                Text(
                  _selectedTabIndex == 0
                      ? 'About this Community'
                      : _selectedTabIndex == 2
                      ? 'Community Photos'
                      : 'Knowledge Shared by Elders',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
                const SizedBox(height: 14),
                if (_selectedTabIndex == 0)
                  Text(
                    widget.theme.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  )
                else if (_selectedTabIndex == 2)
                  _buildEmptyState()
                else if (_error != null)
                  TextButton(onPressed: _load, child: Text(_error!))
                else if (_stories.isEmpty)
                  _buildEmptyState()
                else
                  ..._stories.map(
                    (story) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SocialStoryCard(
                        story: story,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _role == 'elder'
                                ? StoryDetailsPage(story: story)
                                : YouthStoryDetailPage(
                                    storyId: story.id,
                                    userRole: _role ?? 'youth',
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

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
          _members ?? 'Loading members...',
          style: TextStyle(
            color: _primaryBrown.withValues(alpha: 0.75),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 16),

        // Follow Community Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _toggleFollowCommunity,
            icon: Icon(
              _isFollowing ? Icons.check : Icons.person_add_outlined,
              color: _isFollowing ? _primaryBrown : Colors.white,
              size: 20,
            ),
            label: Text(
              _isFollowing ? 'Followed' : 'Follow',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _isFollowing ? _primaryBrown : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? _lightTan : _primaryBrown,
              elevation: _isFollowing ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _isFollowing
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
