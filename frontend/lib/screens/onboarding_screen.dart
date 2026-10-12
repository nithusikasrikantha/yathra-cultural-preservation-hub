import 'package:flutter/material.dart';

import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <_OnboardingContent>[
    _OnboardingContent(
      title: 'Real stories, lasting generations',
      description:
          'Listen to elders, share local knowledge and keep family stories alive.',
      assetPath: 'assets/images/onboarding/stories.png',
      label: 'LISTEN & PRESERVE',
    ),
    _OnboardingContent(
      title: 'Explore our rich culture',
      description:
          'Discover recipes, traditions, music and the history behind them.',
      assetPath: 'assets/images/onboarding/heritage.png',
      label: 'DISCOVER & LEARN',
    ),
    _OnboardingContent(
      title: 'Connect, learn and co-create',
      description:
          'Build meaningful connections across generations and create together.',
      assetPath: 'assets/images/onboarding/connection.png',
      label: 'GROW TOGETHER',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLogin() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  void _continue() {
    if (_currentPage == _pages.length - 1) {
      _openLogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3E9),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 18, 8),
            child: Row(
              children: [
                const Icon(Icons.spa_rounded, color: Color(0xFF9D3D20)),
                const SizedBox(width: 8),
                const Text(
                  'YATHRA',
                  style: TextStyle(
                    color: Color(0xFF542717),
                    fontFamily: 'Serif',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentPage + 1}/${_pages.length}',
                  style: const TextStyle(
                    color: Color(0xFF805F49),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: _openLogin, child: const Text('Skip')),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) => _OnboardingPage(
                content: _pages[index],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentPage ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? const Color(0xFF9D3D20)
                            : const Color(0xFFD9C7B2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F351C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.label,
  });

  final String title;
  final String description;
  final String assetPath;
  final String label;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.content});
  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    child: Column(
      children: [
        Expanded(
          flex: 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  content.assetPath,
                  fit: BoxFit.cover,
                  cacheWidth: 560,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      content.label,
                      style: const TextStyle(
                        color: Color(0xFF7A341E),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x55FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3E2519),
                    fontFamily: 'Serif',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF745F50),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
