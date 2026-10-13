import 'package:flutter/material.dart';
import '../../screens/login_screen.dart';
import '../../services/auth_service.dart';

import '../../models/story.dart';
import '../../services/story_service.dart';
import 'elder_knowledge_discovery_page.dart';
import 'share_story_page.dart';
import 'elder_edit_profile_sheet.dart';
import '../culture_connect_pages.dart';
import '../../services/published_content_signal.dart';

class ElderProfilePage extends StatefulWidget {
  const ElderProfilePage({
    super.key,
    this.onHome,
    this.onProfileSaved,
    this.userName = 'Kamala Devi',
    this.handle = '@kamaladevi',
  });

  final VoidCallback? onHome;
  final ValueChanged<Map<String, dynamic>>? onProfileSaved;
  final String userName;
  final String handle;

  @override
  State<ElderProfilePage> createState() => _ElderProfilePageState();
}

class _ElderProfilePageState extends State<ElderProfilePage> {
  static const Color _bgColor = Color(0xFFF9F5EC);
  static const Color _primaryBrown = Color(0xFF4A2C1A);
  static const Color _accentBrown = Color(0xFF6B4226);
  static const Color _cardBg = Color(0xFFFFFDF8);
  static const Color _btnBg = Color(0xFFF5EBE1);
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  String? _profileError;
  Future<void> _loadProfile() async {
    try {
      final values = await Future.wait([
        _authService.getElderProfile(),
        _authService.getProfileStats(),
      ]);
      if (mounted)
        setState(() {
          _profile = values[0];
          _stats = values[1];
          _profileError = null;
        });
    } catch (error) {
      if (mounted) setState(() => _profileError = error.toString());
    }
  }

  Future<void> _editProfile() async {
    if (_profile == null) {
      await _loadProfile();
    }
    if (!mounted || _profile == null) return;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _bgColor,
      builder: (_) => ElderEditProfileSheet(profile: _profile!),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
      widget.onProfileSaved?.call(updated);
    }
  }

  Future<void> _openProjects() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const WorkspacePage(isElder: true),
      ),
    );
    if (mounted) {
      _loadProfile();
      _loadRecentPosts();
    }
  }

  Future<void> _openConnections() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MyConnectionsPage(isElder: true),
      ),
    );
    if (mounted) _loadProfile();
  }

  void _refreshPublished() {
    _loadProfile();
    _loadRecentPosts();
  }

  @override
  void dispose() {
    PublishedContentSignal.revision.removeListener(_refreshPublished);
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign in again to continue your work.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  final StoryService _storyService = const StoryService();
  final List<Story> _recentPosts = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentPosts();
    _loadProfile();
    PublishedContentSignal.revision.addListener(_refreshPublished);
  }

  Future<void> _loadRecentPosts() async {
    try {
      final page = await _storyService.fetchStories(
        page: 1,
        limit: 2,
        mine: true,
      );
      if (mounted) {
        setState(() {
          _recentPosts.clear();
          _recentPosts.addAll(page.items);
          _isLoadingRecent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  void _openPostLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ElderKnowledgeDiscoveryPage(),
      ),
    );
    _loadRecentPosts();
  }

  void _openEditStory(Story story) async {
    final storyMap = {
      '_id': story.id,
      'title': story.title,
      'category': story.category,
      'language': story.language,
      'storyText': story.storyText,
      'audioPath': story.audioPath,
      'bannerImage': story.bannerImage,
      'additionalImages': story.additionalImages,
      'location': story.location,
      'timePeriod': story.timePeriod,
      'community': story.community,
      'communityId': story.communityId,
      'aiSummary': story.aiSummary,
      'summaryStatus': story.summaryStatus,
    };

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ShareStoryPage(storyToEdit: storyMap),
      ),
    );

    if (result == true || mounted) {
      _loadRecentPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBrown, size: 24),
          onPressed: () {
            if (widget.onHome != null) {
              widget.onHome!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _accentBrown.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_florist,
                color: _accentBrown,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'YATHRA',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: _primaryBrown,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(
              Icons.logout_rounded,
              color: _primaryBrown,
              size: 24,
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              // Profile Header Info
              _buildProfileHeader(),
              if (_profileError != null)
                TextButton(
                  onPressed: _loadProfile,
                  child: const Text('Could not load profile. Retry'),
                ),

              const SizedBox(height: 20),

              // MY POSTS Section (Replaces My Contributions & Contribution Overview)
              _buildMyPostsSection(),

              const SizedBox(height: 18),

              // Insights
              _buildInsightsSection(),

              const SizedBox(height: 18),

              _buildCardContainer(
                title: 'MY PROJECTS',
                showChevron: true,
                onHeaderTap: _openProjects,
                child: _buildPillButton(
                  icon: Icons.workspaces_outline,
                  label: 'My Projects',
                  onPressed: _openProjects,
                ),
              ),
              const SizedBox(height: 18),
              // Connections
              _buildConnectionsSection(),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF8A9A5B).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              _profile?['avatar']?.toString() ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person, size: 56, color: _accentBrown),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          _profile?['name']?.toString() ?? widget.userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
            fontFamily: 'Serif',
          ),
        ),

        const SizedBox(height: 2),

        // Handle
        Text(
          'Elder Contributor',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),

        const SizedBox(height: 8),

        // Bio Quote
        Text(
          _profile?['bio']?.toString() ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 10),

        // Location & Languages Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              _profile?['location']?.toString() ?? '',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              _profile?['preferredLanguage']?.toString() ?? '',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stats Row (Contributions, Followers, Following)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              _stats?['contributions']?.toString() ?? '—',
              'Contributions',
            ),
            _buildStatItem(
              _stats?['connections']?.toString() ?? '—',
              'Connections',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _btnBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: _editProfile,
            icon: const Icon(
              Icons.edit_outlined,
              color: _accentBrown,
              size: 18,
            ),
            label: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _accentBrown,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildMyPostsSection() {
    return _buildCardContainer(
      title: 'MY POSTS',
      showChevron: true,
      onHeaderTap: _openPostLibrary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Posts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),

          // Render 1 or 2 Recent Posts
          if (_isLoadingRecent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: _accentBrown),
              ),
            )
          else if (_recentPosts.isNotEmpty) ...[
            for (final story in _recentPosts) ...[
              _buildRecentPostPreview(story),
              const SizedBox(height: 10),
            ],
          ] else ...[
            _buildSampleRecentPostPreview(
              'The story of our village harvest, when the whole community came together...',
              'Tamil • Traditional Story',
            ),
            const SizedBox(height: 10),
            _buildSampleRecentPostPreview(
              'A traditional palmyra syrup sweet recipe passed down from my grandmother...',
              'Tamil • Recipe',
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 6),

          // View Post Library Button
          _buildPillButton(
            icon: Icons.menu_book_outlined,
            label: 'View Post Library',
            onPressed: _openPostLibrary,
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),

          // Options below View Post Library: Drafts & Recently Deleted
          _buildListItem(
            icon: Icons.edit_document,
            title: 'Drafts',
            onTap: _openPostLibrary,
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.delete_outline_rounded,
            title: 'Recently Deleted',
            onTap: _openPostLibrary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostPreview(Story story) {
    return InkWell(
      onTap: () => _openEditStory(story),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _accentBrown.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentBrown.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentBrown.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                color: _accentBrown,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: _primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${story.language} • ${story.category}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: _accentBrown),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleRecentPostPreview(String title, String meta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentBrown.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentBrown.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentBrown.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              color: _accentBrown,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return _buildCardContainer(
      title: 'INSIGHTS',
      showChevron: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentBrown.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: _accentBrown, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your stories are reaching more learners this month.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _primaryBrown,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightMetric(Icons.visibility_outlined, '1.2K', 'Views'),
              _buildInsightMetric(
                Icons.favorite_border_rounded,
                '328',
                'Likes',
              ),
              _buildInsightMetric(
                Icons.chat_bubble_outline_rounded,
                '86',
                'Comments',
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildPillButton(
            icon: Icons.bar_chart_rounded,
            label: 'View Insights',
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsSection() {
    return _buildCardContainer(
      title: 'CONNECTIONS',
      showChevron: true,
      onHeaderTap: _openConnections,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.people_outline_rounded, color: _accentBrown, size: 22),
              SizedBox(width: 12),
              Text(
                '${_stats?['connections'] ?? '—'} people connected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _primaryBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPillButton(
            icon: Icons.people_outline_rounded,
            label: 'Manage Connections',
            onPressed: _openConnections,
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required Widget child,
    bool showChevron = false,
    VoidCallback? onHeaderTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onHeaderTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: _primaryBrown,
                  ),
                ),
                if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black45,
                    size: 20,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: _accentBrown, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14.5, color: Colors.black87),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _btnBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
        ),
        onPressed: onPressed ?? () {},
        icon: Icon(icon, color: _accentBrown, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _accentBrown,
          ),
        ),
      ),
    );
  }
}
