import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/screens/home/home_screen.dart';
import 'package:soundstatus/screens/settings/ui/setting_page.dart';
import 'package:soundstatus/screens/sounds/sound_library_screen.dart';
import 'package:soundstatus/screens/sounds/widgets/sound_page.dart';
import 'package:soundstatus/wallet/wallet_screen.dart';
import 'package:soundstatus/widgets/button.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

// NOTE: These names shadow Material's own NavigationDestination/NavigationBar.
// It works because Dart resolves to the local declarations, but consider
// renaming (e.g. AppNavigationBar) to avoid confusion and import clashes.
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
      // Surface color from the theme: white in light mode, dark panel in dark.
      backgroundColor: c.surface,
      elevation: elevation,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: c.textMuted,
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
        false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Selected tab icon = brand color, unselected = muted theme color —
  /// matches selectedItemColor/unselectedItemColor on the bar so icons
  /// and labels always agree.
  Color _iconColor(BuildContext context, int index) =>
      _selectedIndex == index ? AppColors.primaryColor : context.c.textMuted;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        // No backgroundColor — scaffoldBackgroundColor (c.bg) comes from the
        // theme. The old AppColors.cardColors forced a dark grey in light mode.
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
                color: _iconColor(context, 0),
              ),
              label: "Sound",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.wallet,
                color: _iconColor(context, 1),
              ),
              label: "Wallet",
            ),
            NavigationDestination(
              icon: CommonSvgWidget(
                svgName: Assets.setting,
                color: _iconColor(context, 2),
              ),
              label: "Setting",
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            const SoundLibraryScreen(),
            const WalletScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}
