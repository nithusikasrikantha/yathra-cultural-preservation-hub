import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _cream = Color(0xFFF8F1E4);
  bool _showArtwork = false;

  @override
  void initState() {
    super.initState();
    // Show the logo on the first frame; decode the larger illustration after
    // Android has started rendering to avoid a blank or stalled launch.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _showArtwork = true);
    });
    // Keep the brand screen visible long enough to register before onboarding.
    Future<void>.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _cream),
        if (_showArtwork)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            child: Image.asset(
              'assets/images/onboarding/yathra_splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 480,
              errorBuilder: (_, _, _) => const ColoredBox(color: _cream),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _cream.withValues(alpha: 0.12),
                Colors.transparent,
                const Color(0xFF2F1A10).withValues(alpha: 0.45),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.055),
              const Column(
                children: [
                  Icon(Icons.spa_rounded, color: Color(0xFF9D3D20), size: 56),
                  SizedBox(height: 5),
                  Text(
                    'YATHRA',
                    style: TextStyle(
                      color: Color(0xFF542717),
                      fontFamily: 'Serif',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Preserving Our Roots',
                    style: TextStyle(
                      color: Color(0xFF3D261B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Connecting Generations',
                    style: TextStyle(
                      color: Color(0xFF3D261B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
