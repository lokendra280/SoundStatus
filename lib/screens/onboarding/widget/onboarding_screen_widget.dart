import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/storages/hive_storages.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/screens/auth/login_screen.dart';
import 'package:soundstatus/screens/onboarding/widget/onboarding_page_widget.dart';
import 'package:soundstatus/screens/onboarding/widget/smooth_indicator.dart';
import 'package:soundstatus/widgets/button.dart';

class OnBoardScreenWidget extends StatefulWidget {
  const OnBoardScreenWidget({super.key});

  @override
  State<OnBoardScreenWidget> createState() => _OnBoardScreenWidgetState();
}

class _OnBoardScreenWidgetState extends State<OnBoardScreenWidget> {
  late final PageController controller;
  int currentPage = 0;

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
    setState(() {
      currentPage = index;
    });
  }

  Future<void> finishOnboarding() async {
    await HiveStorage().markOnboardingCompleted();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == 2;

    final screenheight = MediaQuery.of(context).size.height;
    final screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller,
          onPageChanged: onPageChanged,
          children: [
            OnboardPageWidget(
              color: Colors.white,
              urlImage: Assets.onBoardOne,
              title: AppConstants.title1,
              subtitle: AppConstants.subTitle1,
            ),
            OnboardPageWidget(
              color: Colors.white,
              urlImage: Assets.onBoardTwo,
              title: AppConstants.title2,
              subtitle: AppConstants.subTitle2,
            ),
            OnboardPageWidget(
              color: Colors.white,
              urlImage: Assets.onBoardThree,
              title: AppConstants.title3,
              subtitle: AppConstants.subTitle3,
            ),
          ],
        ),
      ),

      /// ─────────────────────────────
      /// Bottom Section
      /// ─────────────────────────────
      bottomSheet: isLastPage
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: Container(
                height: screenheight * 0.060,
                width: screenwidth * 0.60,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: PrimaryButton(
                  onPressed: finishOnboarding,
                  title: "Explore",
                ),
              ),
            )
          : Container(
              color: Colors.white,
              height: screenheight * 0.099,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Skip
                  TextButton(
                    onPressed: finishOnboarding,
                    child: Text(
                      "Skip",
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ),

                  /// Indicator
                  SmoothPageIndicator(controller: controller, pageCount: 3),

                  /// Next
                  SizedBox(
                    height: 50,
                    width: 120,
                    child: PrimaryButton(
                      title: "Next",
                      radius: 20,
                      onPressed: () {
                        if (controller.hasClients) {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
