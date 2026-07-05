import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/storages/hive_storages.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/screens/auth/login_screen.dart';
import 'package:soundstatus/screens/onboarding/widget/onboarding_page_widget.dart';
import 'package:soundstatus/screens/onboarding/widget/smooth_indicator.dart';

class OnBoardScreenWidget extends StatefulWidget {
  const OnBoardScreenWidget({super.key});

  @override
  State<OnBoardScreenWidget> createState() => _OnBoardScreenWidgetState();
}

// Per-page content: image + copy + accent color + emoji pair.
class _OnboardPageData {
  final String image, title, subtitle, emojiTop, emojiBottom;
  final Color accent;
  const _OnboardPageData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.emojiTop,
    required this.emojiBottom,
  });
}

class _OnBoardScreenWidgetState extends State<OnBoardScreenWidget> {
  late final PageController controller;
  int currentPage = 0;

  static const _pages = [
    _OnboardPageData(
      image: Assets.onBoardOne,
      title: AppConstants.title1,
      subtitle: AppConstants.subTitle1,
      accent: AppColors.primaryColor,
      emojiTop: '🎵',
      emojiBottom: '😂',
    ),
    _OnboardPageData(
      image: Assets.onBoardTwo,
      title: AppConstants.title2,
      subtitle: AppConstants.subTitle2,
      accent: kAccent,
      emojiTop: '🔥',
      emojiBottom: '💸',
    ),
    _OnboardPageData(
      image: Assets.onBoardThree,
      title: AppConstants.title3,
      subtitle: AppConstants.subTitle3,
      accent: AppColors.secondaryColor,
      emojiTop: '🚀',
      emojiBottom: '✨',
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = PageController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    if (!mounted) return;
    setState(() => currentPage = index);
  }

  Future<void> finishOnboarding() async {
    await HiveStorage().markOnboardingCompleted();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (currentPage == _pages.length - 1) {
      finishOnboarding();
    } else if (controller.hasClients) {
      controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLastPage = currentPage == _pages.length - 1;
    final accent = _pages[currentPage].accent;

    return Scaffold(
      // Background comes from the theme (c.bg) — works in dark mode too.
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip (fades out on the last page) ─────────
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLastPage ? 0 : 1,
                child: IgnorePointer(
                  ignoring: isLastPage,
                  child: TextButton(
                    onPressed: finishOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textSub,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ─────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return OnboardPageWidget(
                    accent: p.accent,
                    urlImage: p.image,
                    title: p.title,
                    subtitle: p.subtitle,
                    emojiTop: p.emojiTop,
                    emojiBottom: p.emojiBottom,
                  );
                },
              ),
            ),

            // ── Indicator + CTA ───────────────────────────
            SmoothPageIndicator(
              controller: controller,
              pageCount: _pages.length,
              activeColor: accent,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isLastPage ? accent : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isLastPage ? accent : AppColors.primaryColor)
                            .withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isLastPage ? "Let's go 🚀" : 'Next',
                        key: ValueKey(isLastPage),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
