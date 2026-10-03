import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'elder/elder_home_page.dart';
import 'elder/elder_profile_page.dart';
import 'explore_page.dart';
import 'map/cultural_map_page.dart';
import 'youth_home_page.dart';
import 'youth_profile_page.dart';

class YouthHubShell extends StatefulWidget {
  const YouthHubShell({super.key, this.userRole = 'youth', this.userName = ''});

  final String userRole;
  final String userName;

  @override
  State<YouthHubShell> createState() => _YouthHubShellState();
}

class _YouthHubShellState extends State<YouthHubShell> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool? _profileComplete;
  String _role = 'youth';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _role = widget.userRole;
    _name = widget.userName;
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    try {
      if (_role == 'elder') {
        final profile = await _authService.getElderProfile();
        if (mounted && profile['name'] != null) {
          setState(() {
            _name = profile['name'];
          });
        }
      } else {
        final profile = await _authService.getYouthProfile();
        if (mounted) {
          setState(() {
            _profileComplete = profile['profileComplete'] == true;
            if (profile['name'] != null) _name = profile['name'];
          });
        }
      }
    } catch (_) {
      // Supplementary profile load
    }
  }

  void _selectTab(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isElder = _role == 'elder';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          isElder
              ? ElderHomePage(userName: _name)
              : YouthHomePage(
                  userName: _name,
                  profileComplete: _profileComplete,
                  onExplore: () => _selectTab(1),
                  onProfile: () => _selectTab(3),
                ),
          const ExplorePage(),
          CulturalMapPage(userRole: _role),
          isElder
              ? ElderProfilePage(userName: _name)
              : YouthProfilePage(
                  onProfileSaved: (profile) {
                    setState(() {
                      _profileComplete = profile['profileComplete'] == true;
                      if (profile['name'] is String) {
                        _name = profile['name'] as String;
                      }
                    });
                  },
                ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
