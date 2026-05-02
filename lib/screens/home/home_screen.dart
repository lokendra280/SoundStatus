import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/streak_provider.dart';
import 'package:soundstatus/screens/sounds/sound_upload_screen.dart';
import 'package:soundstatus/status/create_status_screen.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final streak = ref.watch(streakProvider);
    final remaining = 5 - (profile?.shareCountToday ?? 0);
    return Scaffold(
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
          // _NotifBell(),
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
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Hey ${profile?.name ?? ''}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                CommonSvgWidget(svgName: Assets.hey, height: 22),
              ],
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
                  icon: Assets.strike,
                  iconColor: AppColors.amber,
                  bg: const Color(0xFFFFF7ED),
                  value: '$streak',
                  label: 'Day streak',
                  valueColor: const Color(0xFF633806),
                  labelColor: const Color(0xFF854F0B),
                ),
                const SizedBox(width: 8),
                _StatCard(
                  icon: Assets.uploadMusic,
                  iconColor: AppColors.primaryColor,
                  bg: const Color(0xFFEEF2FF),
                  value: '${profile?.uploadCount ?? 0}',
                  label: 'Uploads',
                  valueColor: const Color(0xFF3C3489),
                  labelColor: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  icon: Assets.share,
                  iconColor: AppColors.teal,
                  bg: const Color(0xFFF0FDF4),
                  value: '${profile?.shareCountToday ?? 0}/5',
                  label: 'Shares today',
                  valueColor: const Color(0xFF27500A),
                  labelColor: const Color(0xFF3B6D11),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions
            const _SectionTitle('Quick actions'),
            const SizedBox(height: 10),
            Row(
              children: [
                _QuickAction(
                  icon: Assets.add,
                  label: 'Create Status',
                  iconBg: AppColors.primaryColor,
                  cardBg: AppColors.purpleLight,
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
                  icon: Assets.upload,
                  label: 'Upload Sound',
                  iconBg: AppColors.teal,
                  cardBg: AppColors.tealLight,
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
              progress: streak,
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
      color: AppColors.amberLight,
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
          color: AppColors.purpleLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: CommonSvgWidget(
          svgName: Assets.notification,
          color: AppColors.primaryColor,
          height: 10,
          width: 10,
        ),
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
  final String icon;
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
          // Icon(icon, color: iconColor, size: 20),
          CommonSvgWidget(
            svgName: icon,
            color: iconColor,
            height: 20,
            width: 20,
          ),
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
  final String icon;
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
              child: CommonSvgWidget(
                svgName: icon,
                color: AppColors.white,
                // height: 18,
                // width: 20,
              ),
              // child: Icon(icon, color: Colors.white, size: 20),
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
                        color: AppColors.primaryColor,
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
              backgroundColor: AppColors.purpleLight,
              color: AppColors.primaryColor,
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
        const Icon(Icons.warning_rounded, color: AppColors.amber, size: 20),
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
              color: AppColors.amber,
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
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
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
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.purpleLight,
              color: AppColors.primaryColor,
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
