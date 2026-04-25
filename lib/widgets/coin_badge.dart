// lib/screens/badges/coin_badges_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/models/bage_model.dart';
import 'package:soundstatus/providers/bage_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';

class CoinBadgesScreen extends ConsumerStatefulWidget {
  const CoinBadgesScreen({super.key});

  @override
  ConsumerState<CoinBadgesScreen> createState() => _CoinBadgesScreenState();
}

class _CoinBadgesScreenState extends ConsumerState<CoinBadgesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  BadgeTier? _tierFilter;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeState = ref.watch(badgeProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: badgeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => _buildBody(state, profile),
      ),
    );
  }

  Widget _buildBody(BadgeState state, dynamic profile) {
    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [_buildSliverHeader(state, profile)],
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆 Unlocked'),
                    const SizedBox(width: 6),
                    _CountPill(state.unlocked.length, Colors.green),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒 Locked'),
                    const SizedBox(width: 6),
                    _CountPill(state.locked.length, Colors.grey),
                  ],
                ),
              ),
            ],
          ),

          // Tier filter chips
          _TierFilterRow(
            selected: _tierFilter,
            onSelect: (t) =>
                setState(() => _tierFilter = _tierFilter == t ? null : t),
          ),

          // Badge grids
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BadgeGrid(
                  badges: _filtered(state.unlocked),
                  isUnlocked: true,
                  state: state,
                ),
                _BadgeGrid(
                  badges: _filtered(state.locked),
                  isUnlocked: false,
                  state: state,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CoinBadge> _filtered(List<CoinBadge> list) {
    if (_tierFilter == null) return list;
    return list.where((b) => b.tier == _tierFilter).toList();
  }

  Widget _buildSliverHeader(
    BadgeState state,
    dynamic profile,
  ) => SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Badges & Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  //  if (profile != null) CoinBadge(coins: profile.coinBalance),
                ],
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _HeaderStat(
                    value: '${state.unlocked.length}/${kAllBadges.length}',
                    label: 'Badges earned',
                    icon: '🏆',
                  ),
                  const SizedBox(width: 16),
                  _HeaderStat(
                    value: '${state.totalCoinsEarned}',
                    label: 'Lifetime coins',
                    icon: '🪙',
                  ),
                  const SizedBox(width: 16),
                  _HeaderStat(
                    value: '${(state.progress * 100).toInt()}%',
                    label: 'Complete',
                    icon: '📊',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Collection progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${state.unlocked.length} of ${kAllBadges.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Next badge hint
              if (state.locked.isNotEmpty)
                _NextBadgeHint(
                  badge: state.locked.first,
                  state: state,
                  profile: profile,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Badge grid ───────────────────────────────────────────────────────
class _BadgeGrid extends ConsumerWidget {
  final List<CoinBadge> badges;
  final bool isUnlocked;
  final BadgeState state;

  const _BadgeGrid({
    required this.badges,
    required this.isUnlocked,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;

    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isUnlocked ? '🔐' : '🎉',
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 12),
            Text(
              isUnlocked ? 'No badges yet' : 'All badges unlocked!',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              isUnlocked
                  ? 'Keep earning coins to unlock badges'
                  : 'You\'ve collected everything — legend!',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _BadgeCard(
        badge: badges[i],
        isUnlocked: isUnlocked,
        state: state,
        profile: profile,
        onTap: () =>
            _showBadgeDetail(ctx, badges[i], isUnlocked, state, profile),
      ),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    CoinBadge badge,
    bool unlocked,
    BadgeState state,
    dynamic profile,
  ) {
    showDialog(
      context: context,
      builder: (_) => _BadgeDetailDialog(
        badge: badge,
        isUnlocked: unlocked,
        state: state,
        profile: profile,
      ),
    );
  }
}

// ── Badge card ───────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final CoinBadge badge;
  final bool isUnlocked;
  final BadgeState state;
  final dynamic profile;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.state,
    required this.profile,
    required this.onTap,
  });

  // How close is the user to unlocking (0.0 - 1.0)
  double _progressToward() {
    if (isUnlocked) return 1.0;
    if (profile == null) return 0.0;

    double prog = 1.0;

    if (badge.coinsRequired > 0) {
      prog = (state.totalCoinsEarned / badge.coinsRequired).clamp(0.0, 1.0);
    }
    if (badge.uploadsRequired != null) {
      prog = ((profile.uploadCount / badge.uploadsRequired!)).clamp(0.0, 1.0);
    }
    if (badge.streakRequired != null) {
      prog = ((profile.streakCount / badge.streakRequired!)).clamp(0.0, 1.0);
    }
    return prog;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressToward();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked ? badge.color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? badge.tierColor.withOpacity(0.5)
                : Colors.grey.shade200,
            width: isUnlocked ? 1.5 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: badge.tierColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji with lock overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 34,
                      color: isUnlocked ? null : Colors.black,
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade100.withOpacity(0.7),
                      child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                badge.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? Colors.black87 : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? badge.tierColor.withOpacity(0.15)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.tierLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? badge.tierColor : Colors.grey.shade400,
                  ),
                ),
              ),

              // Progress bar for locked badges
              if (!isUnlocked && progress > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      badge.tierColor.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge detail dialog ──────────────────────────────────────────────
class _BadgeDetailDialog extends StatelessWidget {
  final CoinBadge badge;
  final bool isUnlocked;
  final BadgeState state;
  final dynamic profile;

  const _BadgeDetailDialog({
    required this.badge,
    required this.isUnlocked,
    required this.state,
    required this.profile,
  });

  String _requirementText() {
    final parts = <String>[];
    if (badge.coinsRequired > 0)
      parts.add('Earn ${badge.coinsRequired} coins lifetime');
    if (badge.uploadsRequired != null)
      parts.add('Get ${badge.uploadsRequired} sounds approved');
    if (badge.streakRequired != null)
      parts.add('Reach a ${badge.streakRequired}-day streak');
    if (badge.sharesRequired != null)
      parts.add('Share ${badge.sharesRequired} statuses');
    return parts.join('\n');
  }

  String _progressText() {
    if (isUnlocked) return 'Unlocked ✅';
    if (profile == null) return '';
    final parts = <String>[];
    if (badge.coinsRequired > 0)
      parts.add('${state.totalCoinsEarned} / ${badge.coinsRequired} coins');
    if (badge.uploadsRequired != null)
      parts.add('${profile.uploadCount} / ${badge.uploadsRequired} uploads');
    if (badge.streakRequired != null)
      parts.add('${profile.streakCount} / ${badge.streakRequired} days');
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    contentPadding: const EdgeInsets.all(24),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big emoji
        Text(
          isUnlocked ? badge.emoji : '🔒',
          style: const TextStyle(fontSize: 60),
        ),
        const SizedBox(height: 12),

        // Tier label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badge.tierColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badge.tierColor.withOpacity(0.4)),
          ),
          child: Text(
            badge.tierLabel,
            style: TextStyle(
              color: badge.tierColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          badge.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          badge.description,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Requirements
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Requirements',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(_requirementText(), style: const TextStyle(fontSize: 13)),
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                const Text(
                  'Your progress',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _progressText(),
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      ],
    ),
  );
}

// ── Supporting widgets ───────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String value, label, icon;
  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _NextBadgeHint extends StatelessWidget {
  final CoinBadge badge;
  final BadgeState state;
  final dynamic profile;

  const _NextBadgeHint({
    required this.badge,
    required this.state,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(badge.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next badge',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                badge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                badge.description,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge.tierLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TierFilterRow extends StatelessWidget {
  final BadgeTier? selected;
  final ValueChanged<BadgeTier?> onSelect;
  const _TierFilterRow({required this.selected, required this.onSelect});

  static const _tiers = [
    (BadgeTier.bronze, '🥉 Bronze', Color(0xFFCD7F32)),
    (BadgeTier.silver, '🥈 Silver', Color(0xFF9E9E9E)),
    (BadgeTier.gold, '🥇 Gold', Color(0xFFFFD700)),
    (BadgeTier.platinum, '💎 Platinum', Color(0xFF00BCD4)),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // 'All' chip
        _TierChip(
          label: 'All',
          color: Colors.grey,
          isActive: selected == null,
          onTap: () => onSelect(null),
        ),
        ..._tiers.map(
          (t) => _TierChip(
            label: t.$2,
            color: t.$3,
            isActive: selected == t.$1,
            onTap: () => onSelect(t.$1),
          ),
        ),
      ],
    ),
  );
}

class _TierChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _TierChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 6),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? color : Colors.grey,
          ),
        ),
      ),
    ),
  );
}

class _CountPill extends StatelessWidget {
  final int count;
  final Color color;
  const _CountPill(this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$count',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}
