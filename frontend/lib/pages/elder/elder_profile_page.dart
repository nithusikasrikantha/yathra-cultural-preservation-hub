import 'package:flutter/material.dart';

class ElderProfilePage extends StatefulWidget {
  const ElderProfilePage({
    super.key,
    this.userName = 'Kamala Devi',
    this.handle = '@kamaladevi',
  });

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
            if (Navigator.of(context).canPop()) {
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
            icon: const Icon(Icons.more_vert, color: _primaryBrown, size: 24),
            onPressed: () {},
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

              const SizedBox(height: 18),

              // Contribution Overview
              _buildContributionOverview(),

              const SizedBox(height: 18),

              // My Contributions
              _buildMyContributionsSection(),

              const SizedBox(height: 18),

              // Insights
              _buildInsightsSection(),

              const SizedBox(height: 18),

              // Connections
              _buildConnectionsSection(),

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
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=250&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                size: 56,
                color: _accentBrown,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          widget.userName,
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
          widget.handle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 8),

        // Bio Quote
        const Text(
          '“Sharing our traditions with the next generation.”',
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
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            const Text(
              'Jaffna',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Colors.black54),
            const SizedBox(width: 4),
            const Text(
              'Tamil • Sinhala',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stats Row (Contributions, Followers, Following)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('24', 'Contributions'),
            Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
            _buildStatItem('156', 'Followers'),
            Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
            _buildStatItem('12', 'Following'),
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
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: _accentBrown, size: 18),
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
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionOverview() {
    return _buildCardContainer(
      title: 'CONTRIBUTION OVERVIEW',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewMetric(
                icon: Icons.article_outlined,
                value: '24',
                label: 'Contributions',
              ),
              Container(height: 36, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
              _buildOverviewMetric(
                icon: Icons.visibility_outlined,
                value: '1.2K',
                label: 'Views',
              ),
              Container(height: 36, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
              _buildOverviewMetric(
                icon: Icons.chat_bubble_outline_rounded,
                value: '86',
                label: 'Responses',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: _accentBrown, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryBrown,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyContributionsSection() {
    return _buildCardContainer(
      title: 'MY CONTRIBUTIONS',
      showChevron: true,
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.article_outlined,
            title: 'Published Stories',
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.edit_document,
            title: 'Drafts',
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.delete_outline_rounded,
            title: 'Recently Deleted',
          ),
          const SizedBox(height: 14),
          _buildPillButton(
            icon: Icons.menu_book_outlined,
            label: 'View Post Library',
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
          // Banner Highlight
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

          // Stat Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightMetric(Icons.visibility_outlined, '1.2K', 'Views'),
              _buildInsightMetric(Icons.favorite_border_rounded, '328', 'Likes'),
              _buildInsightMetric(Icons.chat_bubble_outline_rounded, '86', 'Comments'),
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
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline_rounded, color: _accentBrown, size: 22),
              SizedBox(width: 12),
              Text(
                '12 Learners connected',
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
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required Widget child,
    bool showChevron = false,
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
          Row(
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildListItem({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _accentBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.black38,
            size: 18,
          ),
        ],
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
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillButton({required IconData icon, required String label}) {
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
        onPressed: () {},
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
