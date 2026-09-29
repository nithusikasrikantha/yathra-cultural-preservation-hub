import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'youth_feed_page.dart';
import 'youth_heritage_map_page.dart';
import 'youth_home_page.dart';
import 'youth_profile_page.dart';

class YouthHubShell extends StatefulWidget {
  const YouthHubShell({super.key});

  @override
  State<YouthHubShell> createState() => _YouthHubShellState();
}

class _YouthHubShellState extends State<YouthHubShell> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool? _profileComplete;

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    try {
      final profile = await _authService.getYouthProfile();
      if (mounted) {
        setState(() => _profileComplete = profile['profileComplete'] == true);
      }
    } catch (_) {
      // Profile status is supplementary; the Youth Hub remains available.
    }
  }

  void _selectTab(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          YouthHomePage(
            profileComplete: _profileComplete,
            onExplore: () => _selectTab(1),
            onProfile: () => _selectTab(3),
          ),
          const YouthFeedPage(),
          const YouthHeritageMapPage(),
          YouthProfilePage(
            onProfileSaved: (profile) {
              setState(
                () => _profileComplete = profile['profileComplete'] == true,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
