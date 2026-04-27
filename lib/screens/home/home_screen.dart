import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/streak_provider.dart';
import 'package:soundstatus/screens/sounds/sound_upload_screen.dart';
import 'package:soundstatus/status/create_status_screen.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

const _purple = Color(0xFF534AB7);
const _purpleLight = Color(0xFFEEEDFE);
const _amber = Color(0xFFBA7517);
const _amberLight = Color(0xFFFAEEDA);
const _teal = Color(0xFF0F6E56);
const _tealLight = Color(0xFFE1F5EE);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final streak = ref.watch(streakProvider);
    final remaining = 5 - (profile?.shareCountToday ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StatusHub',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Sound · Share · Earn',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          _CoinBadge(coins: profile?.coinBalance ?? 0),
          const SizedBox(width: 8),
          _NotifBell(),
          const SizedBox(width: 14),
        ],
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
            // Greeting
            Text(
              'Hey ${profile?.name ?? ''} 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Ready to make some noise?',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // Stat cards
            Row(
              children: [
                _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: _amber,
                  bg: const Color(0xFFFFF7ED),
                  value: '$streak',
                  label: 'Day streak',
                  valueColor: const Color(0xFF633806),
                  labelColor: const Color(0xFF854F0B),
                ),
                const SizedBox(width: 8),
                _StatCard(
                  icon: Icons.music_note_rounded,
                  iconColor: _purple,
                  bg: const Color(0xFFEEF2FF),
                  value: '${profile?.uploadCount ?? 0}',
                  label: 'Uploads',
                  valueColor: const Color(0xFF3C3489),
                  labelColor: _purple,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  icon: Icons.upload_rounded,
                  iconColor: _teal,
                  bg: const Color(0xFFF0FDF4),
                  value: '${profile?.shareCountToday ?? 0}/5',
                  label: 'Shares today',
                  valueColor: const Color(0xFF27500A),
                  labelColor: const Color(0xFF3B6D11),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions
            const _SectionTitle('Quick actions'),
            const SizedBox(height: 10),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_rounded,
                  label: 'Create Status',
                  iconBg: _purple,
                  cardBg: _purpleLight,
                  cardBorder: const Color(0xFFAFA9EC),
                  labelColor: const Color(0xFF3C3489),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateStatusScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload Sound',
                  iconBg: _teal,
                  cardBg: _tealLight,
                  cardBorder: const Color(0xFF5DCAA5),
                  labelColor: const Color(0xFF085041),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SoundUploadScreen(),
                    ),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 20),

            // XP progress
            // const _SectionTitle('Your XP progress'),
            // const SizedBox(height: 10),
            // _XPCard(
            //   level: profile?.coinBalance ?? 1,
            //   xp: profile?.coinBalance ?? 0,
            //   nextLevelXp: 5000,
            // ),
            const SizedBox(height: 16),

            // Share limit warning
            if (profile != null && profile.shareCountToday >= 4)
              _ShareLimitBanner(remaining: remaining),
            if (profile != null && profile.shareCountToday >= 4)
              const SizedBox(height: 16),

            // Weekly challenge
            const _SectionTitle('Weekly challenge'),
            const SizedBox(height: 10),
            _WeeklyChallengeCard(
              title: 'Upload 3 sounds this week',
              progress: 2,
              total: 3,
              xpReward: 150,
              deadline: 'Ends Sun',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Badge ────────────────────────────────────────
class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _amberLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // const Text('🪙', style: TextStyle(fontSize: 13)),
        CommonSvgWidget(svgName: Assets.bank, height: 16),
        const SizedBox(width: 4),
        Text(
          '$coins',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF633806),
          ),
        ),
      ],
    ),
  );
}

// ── Notification Bell ─────────────────────────────────
class _NotifBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CommonSvgWidget(
          svgName: Assets.notification,
          color: AppColors.primaryColor,
          height: 10,
          width: 10,
        ),
        // child: const Icon(
        //   Icons.notifications_outlined,
        //   color: _purple,
        //   size: 18,
        // ),
      ),
      Positioned(
        right: 6,
        top: 6,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFE24B4A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

// ── Stat Card ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bg, valueColor, labelColor;
  final String value, label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
        ],
      ),
    ),
  );
}

// ── Quick Action ──────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg, cardBg, cardBorder, labelColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.cardBg,
    required this.cardBorder,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── XP Card ───────────────────────────────────────────
class _XPCard extends StatelessWidget {
  final int level, xp, nextLevelXp;
  const _XPCard({
    required this.level,
    required this.xp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (xp / nextLevelXp).clamp(0.0, 1.0);
    final remaining = nextLevelXp - xp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Level $level',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple,
                      ),
                    ),
                    TextSpan(
                      text: ' · Creator',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Text(
                '$xp / $nextLevelXp XP',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _purpleLight,
              color: _purple,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$remaining XP to Level ${level + 1}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share Limit Banner ────────────────────────────────
class _ShareLimitBanner extends StatelessWidget {
  final int remaining;
  const _ShareLimitBanner({required this.remaining});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEF9F27)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_rounded, color: _amber, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                remaining == 0
                    ? 'Daily share limit reached'
                    : 'Only $remaining free share${remaining == 1 ? '' : 's'} left today',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF633806),
                ),
              ),
              const Text(
                'Watch an ad to earn more',
                style: TextStyle(fontSize: 11, color: Color(0xFF854F0B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {}, // trigger rewarded ad
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Watch ad',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Weekly Challenge Card ─────────────────────────────
class _WeeklyChallengeCard extends StatelessWidget {
  final String title, deadline;
  final int progress, total, xpReward;

  const _WeeklyChallengeCard({
    required this.title,
    required this.progress,
    required this.total,
    required this.xpReward,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    final pct = progress / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '$progress of $total done · $deadline',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Text(
                '+$xpReward XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _purpleLight,
              color: _purple,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A),
    ),
  );
}
