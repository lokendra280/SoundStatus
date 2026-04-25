import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    if (!mounted) return;

    final hive = HiveStorage();

    // final languageSelected = await hive.checkLanguageSelected();
    // if (!languageSelected) {
    //   _navigate(const LanguageSelectionScreen());
    //   return;
    // }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      bottomNavigationBar: const SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Version Name v.0.53.34",
              style: TextStyle(fontSize: 18, color: AppColors.white),
            ),
            SizedBox(height: 4),
            Text(
              "App Update Date 2025-03-11",
              style: TextStyle(fontSize: 16, color: AppColors.secondaryColor),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(Assets.applogo, height: 100, width: 100),
            const SizedBox(height: 24),
            const Text(
              "Status",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
