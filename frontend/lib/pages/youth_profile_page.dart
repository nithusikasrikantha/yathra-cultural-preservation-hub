import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

const _languages = ['Tamil', 'Sinhala', 'English'];
const _interests = [
  'Folklore',
  'Traditional Food',
  'Music',
  'Dance',
  'Festivals',
  'Language',
  'History',
  'Crafts',
];
const _bgColor = Color(0xFFF9F5EC);
const _primaryBrown = Color(0xFF4A2C1A);
const _accentBrown = Color(0xFF6B4226);
const _cardBg = Color(0xFFFFFDF8);
const _buttonBg = Color(0xFFF5EBE1);

/// Temporary Youth-only presentation data until social and learning metrics
/// have dedicated backend support. These values are never persisted.
abstract final class _YouthPreviewMetrics {
  static const followers = 18;
  static const following = 7;
  static const savedStories = 12;
  static const storiesViewed = 24;
  static const categoriesExplored = 8;
  static const elderConnections = 5;
}

class YouthProfilePage extends StatefulWidget {
  const YouthProfilePage({super.key, this.onProfileSaved});

  final ValueChanged<Map<String, dynamic>>? onProfileSaved;

  @override
  State<YouthProfilePage> createState() => _YouthProfilePageState();
}

class _YouthProfilePageState extends State<YouthProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final profile = await _authService.getYouthProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditProfile({
    YouthEditSection section = YouthEditSection.details,
  }) async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _YouthEditProfileSheet(
        profile: profile,
        initialSection: section,
        authService: _authService,
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _profile = updated);
    widget.onProfileSaved?.call(updated);
    _showSnackBar('Youth profile saved successfully.');
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to access your Youth Hub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _primaryBrown),
      );
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
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _primaryBrown, size: 24),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentBrown),
      );
    }
    if (_loadError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: _accentBrown,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load youth profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryBrown,
                  fontFamily: 'Serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _pillButton(Icons.refresh, 'Retry', _loadProfile),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final complete = profile['profileComplete'] == true;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _profileHeader(profile),
              if (!complete) ...[const SizedBox(height: 18), _completionCard()],
              const SizedBox(height: 18),
              _learningOverview(profile),
              const SizedBox(height: 18),
              _myLearningCard(),
              const SizedBox(height: 18),
              _insightsCard(),
              const SizedBox(height: 18),
              _connectionsCard(),
              const SizedBox(height: 18),
              _accountCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(Map<String, dynamic> profile) {
    final avatar = _stringValue(profile['avatar']);
    final name = _stringValue(profile['name']);
    final location = _stringValue(profile['location']);
    final language = _stringValue(profile['preferredLanguage']);
    final interests = _profileInterests(profile);
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF8A9A5B).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? 'Your Profile' : name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _primaryBrown,
            fontFamily: 'Serif',
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Youth Explorer',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        const Text(
          '“Discovering and learning from our cultural heritage.”',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            if (location.isNotEmpty)
              _identityDetail(Icons.location_on_outlined, location),
            if (language.isNotEmpty)
              _identityDetail(Icons.chat_bubble_outline_rounded, language),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('${interests.length}', 'Interests'),
            _statDivider(24),
            _stat('${_YouthPreviewMetrics.followers}', 'Followers'),
            _statDivider(24),
            _stat('${_YouthPreviewMetrics.following}', 'Following'),
          ],
        ),
        const SizedBox(height: 16),
        _pillButton(
          Icons.edit_outlined,
          'Edit Profile',
          () => _openEditProfile(),
        ),
      ],
    );
  }

  Widget _learningOverview(Map<String, dynamic> profile) {
    final interests = _profileInterests(profile);
    final language = _stringValue(profile['preferredLanguage']);
    return _card(
      'LEARNING OVERVIEW',
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _overviewMetric(
            Icons.interests_outlined,
            '${interests.length}',
            'Interests',
          ),
          _statDivider(36),
          _overviewMetric(
            Icons.bookmarks_outlined,
            '${_YouthPreviewMetrics.savedStories}',
            'Saved',
          ),
          _statDivider(36),
          _overviewMetric(
            Icons.translate_rounded,
            language.isEmpty ? '—' : language,
            'Language',
          ),
        ],
      ),
    );
  }

  Widget _myLearningCard() => _card(
    'MY LEARNING',
    Column(
      children: [
        _actionRow(
          Icons.bookmarks_outlined,
          'Saved Stories',
          () => Navigator.of(context).pushNamed('/youth-saved'),
        ),
        const Divider(height: 1),
        _actionRow(
          Icons.interests_outlined,
          'Cultural Interests',
          () => _openEditProfile(section: YouthEditSection.interests),
        ),
        const Divider(height: 1),
        _actionRow(
          Icons.translate_rounded,
          'Language Preference',
          () => _openEditProfile(section: YouthEditSection.language),
        ),
        const Divider(height: 1),
        _actionRow(
          Icons.explore_outlined,
          'Explore Culture',
          () => Navigator.of(context).pushNamed('/explore'),
        ),
      ],
    ),
    showChevron: true,
  );

  Widget _insightsCard() => _card(
    'INSIGHTS',
    Column(
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
                  'You explored more cultural stories this month.',
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
            _insightMetric(
              Icons.menu_book_outlined,
              '${_YouthPreviewMetrics.storiesViewed}',
              'Stories Viewed',
            ),
            _insightMetric(
              Icons.bookmark_outline,
              '${_YouthPreviewMetrics.savedStories}',
              'Saved',
            ),
            _insightMetric(
              Icons.category_outlined,
              '${_YouthPreviewMetrics.categoriesExplored}',
              'Categories',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _pillButton(
          Icons.bar_chart_rounded,
          'View Learning Insights',
          () => _showComingSoon(
            'Learning Insights',
            'Detailed learning insights will be available here.',
          ),
        ),
      ],
    ),
    showChevron: true,
  );

  Widget _connectionsCard() => _card(
    'CONNECTIONS',
    Column(
      children: [
        const Row(
          children: [
            Icon(Icons.people_outline_rounded, color: _accentBrown, size: 22),
            SizedBox(width: 12),
            Text(
              '${_YouthPreviewMetrics.elderConnections} Elders connected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _pillButton(
          Icons.people_outline_rounded,
          'Manage Connections',
          () => _showComingSoon(
            'Connections',
            'Connection management will be available here.',
          ),
        ),
      ],
    ),
    showChevron: true,
  );

  Future<void> _showComingSoon(String title, String message) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: _cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_florist, color: _accentBrown, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryBrown,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 18),
                _pillButton(
                  Icons.check_rounded,
                  'Got it',
                  () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _accountCard() => _card(
    'ACCOUNT',
    _actionRow(
      Icons.logout_rounded,
      'Logout',
      _logout,
      color: Colors.redAccent,
    ),
  );

  Widget _completionCard() => _card(
    'COMPLETE YOUR PROFILE',
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _accentBrown, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete your details and preferences for a more personal cultural discovery experience.',
              style: TextStyle(
                fontSize: 13,
                color: _primaryBrown,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _avatarPlaceholder() => const ColoredBox(
    color: Color(0xFFE2E5D1),
    child: Icon(Icons.person, size: 56, color: _accentBrown),
  );

  Widget _identityDetail(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.black54),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontSize: 13, color: Colors.black54)),
    ],
  );

  Widget _stat(String value, String label) => Flexible(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    ),
  );

  Widget _overviewMetric(IconData icon, String value, String label) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _accentBrown, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _insightMetric(IconData icon, String value, String label) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
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
                maxLines: 2,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statDivider(double height) => Container(
    height: height,
    width: 1,
    color: Colors.grey.withValues(alpha: 0.2),
  );

  Widget _actionRow(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = _accentBrown,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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

  Widget _card(String title, Widget child, {bool showChevron = false}) =>
      Container(
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

  Widget _pillButton(IconData icon, String label, VoidCallback onPressed) =>
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, color: _accentBrown, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _accentBrown,
            ),
          ),
        ),
      );

  String _stringValue(dynamic value) => value is String ? value.trim() : '';

  List<String> _profileInterests(Map<String, dynamic> profile) {
    final value = profile['interests'];
    return value is List
        ? value.whereType<String>().where(_interests.contains).toList()
        : const [];
  }
}

enum YouthEditSection { details, language, interests }

class _YouthEditProfileSheet extends StatefulWidget {
  const _YouthEditProfileSheet({
    required this.profile,
    required this.initialSection,
    required this.authService,
  });

  final Map<String, dynamic> profile;
  final YouthEditSection initialSection;
  final AuthService authService;

  @override
  State<_YouthEditProfileSheet> createState() => _YouthEditProfileSheetState();
}

class _YouthEditProfileSheetState extends State<_YouthEditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _languageKey = GlobalKey();
  final _interestsKey = GlobalKey();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _locationController;
  late final TextEditingController _avatarController;
  late final Set<String> _selectedInterests;
  String? _selectedLanguage;
  String? _saveError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    String value(String key) =>
        widget.profile[key] is String ? widget.profile[key] as String : '';
    _nameController = TextEditingController(text: value('name'));
    _ageController = TextEditingController(text: value('ageGroup'));
    _locationController = TextEditingController(text: value('location'));
    _avatarController = TextEditingController(text: value('avatar'));
    final language = value('preferredLanguage');
    _selectedLanguage = _languages.contains(language) ? language : null;
    final interests = widget.profile['interests'];
    _selectedInterests = interests is List
        ? interests.whereType<String>().where(_interests.contains).toSet()
        : {};
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToInitialSection(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _scrollToInitialSection() {
    final key = switch (widget.initialSection) {
      YouthEditSection.details => null,
      YouthEditSection.language => _languageKey,
      YouthEditSection.interests => _interestsKey,
    };
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        alignment: 0.15,
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (_selectedInterests.isEmpty) {
      setState(() => _saveError = 'Select at least one cultural interest.');
      return;
    }
    if (!valid || _selectedLanguage == null) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final avatar = _avatarController.text.trim();
      final profile = await widget.authService.updateYouthProfile(
        name: _nameController.text.trim(),
        ageGroup: _ageController.text.trim(),
        preferredLanguage: _selectedLanguage!,
        location: _locationController.text.trim(),
        interests: _selectedInterests.toList(growable: false),
        avatar: avatar.isEmpty ? null : avatar,
      );
      if (mounted) Navigator.of(context).pop(profile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryBrown,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: _primaryBrown),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _editCard('PERSONAL INFORMATION', [
                      _field(
                        _nameController,
                        'Name',
                        'Enter your name',
                        Icons.person_outline,
                        100,
                        (v) => _required(v, 'Name', 100),
                      ),
                      _field(
                        _ageController,
                        'Age or age group',
                        'Example: 16 or 13-18',
                        Icons.cake_outlined,
                        30,
                        (v) => _required(v, 'Age or age group', 30),
                      ),
                      _field(
                        _locationController,
                        'Location or region',
                        'Enter your city, district, or region',
                        Icons.location_on_outlined,
                        100,
                        (v) => _required(v, 'Location', 100),
                      ),
                      _field(
                        _avatarController,
                        'Avatar image URL (optional)',
                        'https://example.com/avatar.jpg',
                        Icons.image_outlined,
                        null,
                        _avatarValidator,
                        keyboardType: TextInputType.url,
                      ),
                    ]),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _languageKey,
                      child: _editCard('LANGUAGE PREFERENCE', [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          decoration: _inputDecoration(
                            'Preferred language',
                            'Select a language',
                            Icons.translate_rounded,
                          ),
                          items: _languages
                              .map(
                                (language) => DropdownMenuItem(
                                  value: language,
                                  child: Text(language),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) =>
                                    setState(() => _selectedLanguage = value),
                          validator: (value) => value == null
                              ? 'Preferred language is required.'
                              : null,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _interestsKey,
                      child: _editCard('CULTURAL INTERESTS', [
                        const Text(
                          'Select one or more topics you want to discover.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((interest) {
                            final selected = _selectedInterests.contains(
                              interest,
                            );
                            return FilterChip(
                              label: Text(interest),
                              selected: selected,
                              checkmarkColor: Colors.white,
                              selectedColor: _accentBrown,
                              backgroundColor: _buttonBg,
                              side: BorderSide(
                                color: selected
                                    ? _accentBrown
                                    : _accentBrown.withValues(alpha: 0.16),
                              ),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : _primaryBrown,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: _isSaving
                                  ? null
                                  : (value) => setState(
                                      () => value
                                          ? _selectedInterests.add(interest)
                                          : _selectedInterests.remove(interest),
                                    ),
                            );
                          }).toList(),
                        ),
                      ]),
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _saveError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Profile',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editCard(String title, List<Widget> children) => Container(
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: _primaryBrown,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 14),
        ],
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    int? maxLength,
    String? Function(String?) validator, {
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    enabled: !_isSaving,
    maxLength: maxLength,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    validator: validator,
    decoration: _inputDecoration(label, hint, icon),
  );

  String? _required(String? value, String field, int maxLength) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required.';
    if (text.length > maxLength) {
      return '$field cannot exceed $maxLength characters.';
    }
    return null;
  }

  String? _avatarValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      return 'Enter a valid HTTP or HTTPS URL.';
    }
    return null;
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _accentBrown, size: 20),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentBrown, width: 1.5),
        ),
      );
}
