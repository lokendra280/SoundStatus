import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/screens/home/home_screen.dart';
import 'package:soundstatus/screens/sounds/sound_library_screen.dart';
import 'package:soundstatus/screens/sounds/sound_upload_screen.dart';
import 'package:soundstatus/wallet/wallet_screen.dart';
import 'package:soundstatus/widgets/button.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class NavigationDestination {
  final Widget icon;
  final String label;

  const NavigationDestination({required this.icon, required this.label});
}

class NavigationBar extends StatelessWidget {
  final double height;
  final double elevation;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const NavigationBar({
    super.key,
    required this.height,
    required this.elevation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,

      elevation: elevation,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.darkGrey,
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      items: destinations.map((destination) {
        return BottomNavigationBarItem(
          icon: destination.icon,
          label: destination.label,
        );
      }).toList(),
    );
  }
}

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({Key? key}) : super(key: key);

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  Future<bool> showExitPopup() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            alignment: Alignment.center,
            title: const Text('Exit App'),
            content: const Text('Do you want to exit an App?'),
            actions: [
              PrimaryButton(
                width: 85,
                onPressed: () => Navigator.of(context).pop(false),
                //return false when click on "NO"
                title: "No",
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                width: 85,
                onPressed: () => Navigator.of(context).pop(true),
                title: "Yes",
              ),
            ],
          ),
        ) ??
        false; //if showDialouge had returned null, then return false
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use

    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          height: 80,
          elevation: 0,

          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
            );
          },
          destinations: [
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.home,
                color: _selectedIndex == 0
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Home",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.upload,
                color: _selectedIndex == 1
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Sounds",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.upload,
                color: _selectedIndex == 2
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Upload",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.wallet,
                color: _selectedIndex == 3
                    ? AppColors.primaryColor
                    : AppColors.darkGrey,
              ),
              label: "Wallet",
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            const HomeScreen(),
            const SoundLibraryScreen(),
            const SoundUploadScreen(),
            const WalletScreen(),
          ],
        ),
      ),
    );
  }
}
