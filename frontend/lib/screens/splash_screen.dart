import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showArtwork = false;

  @override
  void initState() {
    super.initState();
    // Let Android receive Flutter's first frame before decoding the large
    // splash illustration. This avoids holding the launch window while the
    // image decoder and first raster frame are warming up on slower devices.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showArtwork = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF8F1E4)),
        if (_showArtwork)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 450),
            child: Image.asset(
              'assets/images/onboarding/connection.png',
              fit: BoxFit.cover,
              cacheWidth: 480,
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F1E4).withValues(alpha: 0.5),
                const Color(0xFFF8F1E4).withValues(alpha: 0.2),
                const Color(0xFF2F1A10).withValues(alpha: 0.72),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 24),
              Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF3).withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF9D3D20),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'YATHRA',
                    style: TextStyle(
                      color: Color(0xFF542717),
                      fontFamily: 'Serif',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const Text(
                    'CULTURE • CONNECTION • CONTINUITY',
                    style: TextStyle(
                      color: Color(0xFF70452D),
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 46),
                child: Column(
                  children: [
                    Text(
                      'Preserving our roots',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Serif',
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Connecting generations through living culture',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
