import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/dashboard/pages/dashboard_page.dart';
import 'package:soundstatus/providers/auth_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/screens/settings/ui/setting_page.dart';

const _purpleLight = Color(0xFFEEEDFE);
const _dark = Color(0xFF1A1A1A);
const _teal = Color(0xFF0F6E56);
const _amber = Color(0xFFBA7517);
const _red = Color(0xFFA32D2D);
const _redLight = Color(0xFFFCEBEB);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // ── Purple hero header ──────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primaryColor,
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        _initials(profile?.name ?? 'U'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ref.watch(userEmailProvider),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      _StatBox(label: 'Tier', value: profile?.tier ?? 'Bronze'),
                      _StatBox(
                        label: 'Rank',
                        value: '#${profile?.leaderboardRank ?? '-'}',
                      ),
                      _StatBox(
                        label: 'Streak',
                        value: '${profile?.streakCount ?? 0}d',
                      ),
                      _StatBox(
                        label: 'Coins',
                        value: '${profile?.coinBalance ?? 0}',
                        valueColor: Colors.amber[300]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Badges
                const Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Badge(
                      icon: Icons.bolt_rounded,
                      label: 'Viral Creator',
                      iconColor: AppColors.primaryColor,
                      bg: _purpleLight,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.star_rounded,
                      label: 'Top Upload',
                      iconColor: _amber,
                      bg: const Color(0xFFFAEEDA),
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak King',
                      iconColor: _teal,
                      bg: const Color(0xFFE1F5EE),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats grid
                const Text(
                  'Stats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _StatGridCard(
                      label: 'Sounds uploaded',
                      value: '${profile?.uploadCount ?? 0}',
                      color: AppColors.primaryColor,
                    ),
                    // _StatGridCard(
                    //   label: 'Total shares',
                    //   value: _formatCount(profile?.totalShares ?? 0),
                    //   color: _teal,
                    // ),
                    // _StatGridCard(
                    //   label: 'Followers',
                    //   value: _formatCount(profile?.followers ?? 0),
                    //   color: _amber,
                    // ),
                    // _StatGridCard(
                    //   label: 'Score today',
                    //   value: '${profile?.scoreToday ?? 0}',
                    //   color: _dark,
                    // ),
                  ],
                ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardPage(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmSignOut(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _redLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF09595)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: _red, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Sign out',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
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
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign out', style: TextStyle(color: _red)),
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

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor, bg;
  const _Badge({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _StatGridCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatGridCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEFEFEF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    ),
  );
}
