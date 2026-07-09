import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soundstatus/core/storages/hive_storages.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/dashboard/pages/dashboard_page.dart';
import 'package:soundstatus/screens/auth/login_screen.dart';
import 'package:soundstatus/screens/onboarding/pages/onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  late final Animation<double> _fade;

  // Rotating funny loading lines
  static const _loadingLines = [
    "MemeSound is loading your vibe...",
    "Warming up the vine boom...",
    "Downloading maximum bruh energy...",
    "Certified funny moments incoming...",
  ];
  late final String _loadingText;

  @override
  void initState() {
    super.initState();

    _loadingText = _loadingLines[Random().nextInt(_loadingLines.length)];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Logo drops in with an elastic bounce
    _bounce = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    // Text fades in after the bounce starts
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
    _playMemeSound();
    _initializeApp();
  }

  Future<void> _playMemeSound() async {
    try {
      await _player.play(AssetSource('sounds/splash_meme.mp3'), volume: 0.7);
    } catch (e) {
      // Never let a missing/failed sound break the splash
      debugPrint('Splash sound failed: $e');
    }
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    if (!mounted) return;

    final hive = HiveStorage();

    final onboardCompleted = await hive.checkOnboardingCompleted();
    if (!onboardCompleted) {
      _navigate(const OnboardingPage());
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      _navigate(const DashboardPage());
    } else {
      _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      bottomNavigationBar: const SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Version Name v.1.0.12",
              style: TextStyle(fontSize: 18, color: AppColors.white),
            ),
            SizedBox(height: 4),
            Text(
              "App Update Date 2025-9-12",
              style: TextStyle(fontSize: 16, color: AppColors.secondaryColor),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouncing logo/emoji
            ScaleTransition(
              scale: _bounce,
              child: const Text("🔊😂", style: TextStyle(fontSize: 72)),
              // If you have a logo asset, swap the Text for:
              // Image.asset(ConstantAssets.logo, width: 120),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fade,
              child: Text(
                _loadingText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            const CupertinoActivityIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
