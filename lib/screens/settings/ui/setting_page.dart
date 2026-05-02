import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/providers/auth_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/setting_provider.dart';
import 'package:soundstatus/providers/theme_provider.dart';
import 'package:soundstatus/screens/leaderboard/ui/leaderboard_screen.dart';
import 'package:soundstatus/screens/settings/ui/help_faq_page.dart';
import 'package:soundstatus/screens/settings/ui/profile_screen.dart';
import 'package:soundstatus/screens/sounds/sound_upload_screen.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;

  String _quality = 'High';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final email = ref.watch(userEmailProvider);
    final themeMode = ref.watch(themeProvider);

    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.darks,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darks,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFEFEFEF)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile card ──────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purpleLight,
                      ),
                      child: Center(
                        child: Text(
                          _initials(profile?.name ?? 'U'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darks,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile?.tier ?? 'Bronze'} tier · #${profile?.leaderboardRank ?? '-'} rank',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {}, // navigate to edit profile
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Account section ───────────────────────────
            _SectionLabel('Account'),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: Assets.leaderboard,
                  iconBg: AppColors.purpleLight,
                  iconColor: AppColors.primaryColor,
                  label: 'LeaderBoard',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Assets.uploadMusic,
                  iconBg: AppColors.purpleLight,
                  iconColor: AppColors.primaryColor,
                  label: 'Sound Upload',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SoundUploadScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Assets.notification,
                  iconBg: AppColors.purpleLight,
                  iconColor: AppColors.primaryColor,
                  label: 'Notifications',
                  onTap: () async {
                    final result = await ref
                        .read(settingsProvider.notifier)
                        .toggleNotifications();
                    if (!context.mounted) return;
                    switch (result) {
                      case NotifResult.permissionDenied:
                        _snack(
                          'Enable notifications in device settings',
                          error: true,
                        );
                      case NotifResult.error:
                        _snack('Failed to update notifications', error: true);
                      default:
                        break;
                    }
                  },
                  trailing: Switch(
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                    activeColor: AppColors.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Preferences section ───────────────────────
            _SectionLabel('Preferences'),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: Assets.about,
                  iconBg: AppColors.purpleLight,
                  iconColor: AppColors.primaryColor,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (v) {
                      ref
                          .read(themeProvider.notifier)
                          .setMode(v ? ThemeMode.dark : ThemeMode.light);
                    },
                    activeColor: AppColors.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  // ),
                  //     // _SettingsItem(
                  //     //   icon: Icons.music_note_rounded,
                  //     //   iconBg: const Color(0xFFE1F5EE),
                  //     //   iconColor: const Color(0xFF0F6E56),
                  //     //   label: 'Sound Quality',

                  //     //   value: _quality,
                  //     //   onTap: () => _showQualityPicker(),
                  //     // ),
                  //     // _SettingsItem(
                  //     //   icon: Icons.language_rounded,
                  //     //   iconBg: const Color(0xFFE6F1FB),
                  //     //   iconColor: const Color(0xFF185FA5),
                  //     //   label: 'Language',
                  //     //   value: 'English',
                  //     //   onTap: () {},
                ),
              ],
            ),
            // const SizedBox(height: 16),

            // ── Support section ───────────────────────────
            _SectionLabel('Support'),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: Assets.help,
                  iconBg: const Color(0xFFE6F1FB),
                  iconColor: const Color(0xFF185FA5),
                  label: 'Help & FAQ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Assets.rating,
                  iconBg: const Color(0xFFE6F1FB),
                  iconColor: const Color(0xFF185FA5),
                  label: 'Rate the App',
                  onTap: () async {
                    final result = await ref
                        .read(settingsProvider.notifier)
                        .rateApp();
                    if (!context.mounted) return;
                    if (result == RateResult.error) {
                      _snack('Could not open store', error: true);
                    }
                  },
                ),
                _SettingsItem(
                  icon: Assets.about,
                  iconBg: const Color(0xFFE6F1FB),
                  iconColor: const Color(0xFF185FA5),
                  label: 'About',
                  value: 'v2.0.0',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Sign out ──────────────────────────────────
            GestureDetector(
              onTap: () => _confirmSignOut(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF09595)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.red,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Version
            Center(
              child: Text(
                'StatusHub Sound · v2.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sound Quality',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darks,
              ),
            ),
            const SizedBox(height: 12),
            ...['Low', 'Medium', 'High'].map(
              (q) => GestureDetector(
                onTap: () {
                  setState(() => _quality = q);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _quality == q ? AppColors.purpleLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _quality == q
                          ? AppColors.primaryColor
                          : const Color(0xFFEFEFEF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          q,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _quality == q
                                ? AppColors.primaryColor
                                : AppColors.darks,
                          ),
                        ),
                      ),
                      if (_quality == q)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You will be returned to the login screen.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(settingsProvider.notifier)
                  .signOut();
              if (!context.mounted) return;
              if (result == SignOutResult.error) {
                _snack('Sign out failed', error: true);
              }
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _snack(String message, {bool error = false}) {
    final snack = SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.red : AppColors.primaryColor,
      behavior: SnackBarBehavior.floating,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(snack);
  }
}

// ── Shared widgets ────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEFEFEF)),
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Column(
          children: [
            e.value,
            if (!isLast)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 52,
                color: Color(0xFFEFEFEF),
              ),
          ],
        );
      }).toList(),
    ),
  );
}

class _SettingsItem extends StatelessWidget {
  final String icon;
  final Color iconBg, iconColor;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: CommonSvgWidget(
              svgName: icon,
              color: iconColor,
              height: 10,
              width: 10,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.darks),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
            ),
          if (trailing != null)
            trailing!
          else if (onTap != null && value == null)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.darkGrey,
            ),
          if (onTap != null && value != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.darkGrey,
              ),
            ),
        ],
      ),
    ),
  );
}
