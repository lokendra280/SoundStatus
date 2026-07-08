import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/providers/leaderboard_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardState();
}

class _LeaderboardState extends ConsumerState<LeaderboardScreen> {
  String _period = 'daily';

  static const _periodMeta = {
    'daily': ('⚡', 'Daily Hustle', 'Resets every 24h'),
    'weekly': ('🏆', 'Weekly Grind', 'Resets every Monday'),
    'creator': ('🎵', 'Top Creators', 'All-time best uploaders'),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final leaderboard = ref.watch(leaderboardProvider(_period));
    final myProfile = ref.watch(profileProvider).valueOrNull;
    final myRank = ref.watch(myRankProvider(_period));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: context.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: c.border),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () => ref.refresh(leaderboardProvider(_period).future),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Period selector ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _PeriodSelector(
                  period: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
              ),
            ),

            // ── Hero podium ──────────────────────────────
            SliverToBoxAdapter(
              child: leaderboard.when(
                loading: () => const _PodiumSkeleton(),
                error: (e, _) => const SizedBox(height: 12),
                data: (list) => list.length >= 3
                    ? _Podium(
                        entries: list.take(3).toList(),
                        meta: _periodMeta[_period]!,
                      )
                    : const SizedBox(height: 12),
              ),
            ),

            // ── My rank card ──────────────────────────────
            SliverToBoxAdapter(
              child: myRank.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (rank) => rank != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        child: _MyRankCard(
                          rank: rank,
                          name: myProfile?.name ?? 'You',
                          score: rank.score,
                          ptsToNext: rank.ptsToNextRank,
                        ),
                      )
                    : const SizedBox(),
              ),
            ),

            // ── Rankings header ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Row(
                  children: [
                    Text(
                      'RANKINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 0.5, color: c.border)),
                  ],
                ),
              ),
            ),

            // ── Rankings list ─────────────────────────────
            leaderboard.when(
              loading: () => const SliverToBoxAdapter(child: _ListSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Failed to load',
                      style: TextStyle(color: c.textSub),
                    ),
                  ),
                ),
              ),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final e = list[i];
                    return _AnimatedEntry(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RankRow(
                          rank: i + 1,
                          entry: e,
                          isMe: e.userId == myProfile?.id,
                        ),
                      ),
                    );
                  }, childCount: list.length),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staggered fade/slide-in for list rows ─────────────────────────────────
class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index.clamp(0, 10) * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ── Period selector (segmented pill) ──────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.period, required this.onChanged});

  static const _items = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('creator', 'Creators'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: _items.map((item) {
          final active = period == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), AppColors.primaryColor],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : c.textSub,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Hero podium ────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final (String, String, String) meta;
  const _Podium({required this.entries, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2A6E), Color(0xFF534AB7), Color(0xFF6C63FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative glow orbs
            Positioned(
              top: -40,
              right: -30,
              child: _glowOrb(120, Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: _glowOrb(140, const Color(0xFF38BDF8).withOpacity(0.12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(meta.$1, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        meta.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta.$3,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PodiumSlot(entry: entries[1], rank: 2, barHeight: 56),
                      _PodiumSlot(
                        entry: entries[0],
                        rank: 1,
                        barHeight: 84,
                        crown: true,
                      ),
                      _PodiumSlot(entry: entries[2], rank: 3, barHeight: 42),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double barHeight;
  final bool crown;
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.barHeight,
    this.crown = false,
  });

  Color get _medalColor => switch (rank) {
    1 => const Color(0xFFFFD54F),
    2 => const Color(0xFFCFD8DC),
    _ => const Color(0xFFDFA878),
  };

  @override
  Widget build(BuildContext context) {
    final avatarSize = crown ? 58.0 : 44.0;

    return Column(
      children: [
        if (crown)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('👑', style: TextStyle(fontSize: 20)),
          ),
        // Avatar with medal ring
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_medalColor, _medalColor.withOpacity(0.4)],
            ),
            boxShadow: crown
                ? [
                    BoxShadow(
                      color: _medalColor.withOpacity(0.5),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: crown ? Colors.white : Colors.white.withOpacity(0.18),
            ),
            child: Center(
              child: Text(
                _initials(entry.name),
                style: TextStyle(
                  fontSize: crown ? 19 : 14,
                  fontWeight: FontWeight.w700,
                  color: crown ? AppColors.primaryColor : Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: 82,
          child: Text(
            '@${entry.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
        Text(
          '${entry.score} pts',
          style: TextStyle(fontSize: 9.5, color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(height: 7),
        // Podium bar
        Container(
          width: 58,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(crown ? 0.28 : 0.16),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.25), width: 1),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: crown ? 26 : 20,
                fontWeight: FontWeight.w800,
                color: _medalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

// ── My rank card (glass style) ─────────────────────────────────────────────
class _MyRankCard extends StatelessWidget {
  final LeaderboardEntry rank;
  final String name;
  final int score;
  final int ptsToNext;
  const _MyRankCard({
    required this.rank,
    required this.name,
    required this.score,
    required this.ptsToNext,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = context.isDark;
    final progress = (score / (score + ptsToNext)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(isDark ? 0.45 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(isDark ? 0.18 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), AppColors.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${rank.rank}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your rank',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: c.textMuted,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(fontSize: 9.5, color: c.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gradient progress bar
          Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (_, box) => AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 7,
                  width: box.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF6C63FF)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 12,
                color: AppColors.secondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$ptsToNext pts to next rank',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: c.textSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rank row ───────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  const _RankRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = context.isDark;
    final isTop3 = rank <= 3;

    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primaryColor.withOpacity(isDark ? 0.16 : 0.07)
            : c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primaryColor.withOpacity(isDark ? 0.5 : 0.35)
              : c.border,
          width: isMe ? 1.2 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank / medal
          SizedBox(
            width: 30,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 17))
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
          ),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF6C63FF), AppColors.primaryColor],
                    )
                  : null,
              color: isMe
                  ? null
                  : (isDark
                        ? c.cardElevated
                        : AppColors.primaryColor.withOpacity(0.08)),
            ),
            child: Center(
              child: Text(
                _initials(entry.name),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isMe
                      ? Colors.white
                      : (isDark ? AppColors.purpleMid : AppColors.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You · @${entry.name}' : '@${entry.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isMe
                        ? (isDark
                              ? AppColors.purpleMid
                              : AppColors.primaryColor)
                        : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _TierBadge(tier: entry.tier),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isTop3
                      ? AppColors.amber
                      : (isMe ? AppColors.primaryColor : context.textPrimary),
                ),
              ),
              Text('pts', style: TextStyle(fontSize: 9, color: c.textMuted)),
            ],
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
}

// ── Tier badge ─────────────────────────────────────────────────────────────
class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  (Color, Color) _colors(bool isDark) => switch (tier.toLowerCase()) {
    'platinum' => (const Color(0xFF7DE3F3), const Color(0xFF7DE3F3)),
    'gold' => (const Color(0xFFFFD54F), const Color(0xFFB8860B)),
    'silver' => (const Color(0xFFB0BEC5), const Color(0xFF78909C)),
    _ => (const Color(0xFFDFA878), const Color(0xFFA0693C)),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final (light, dark) = _colors(isDark);
    final color = isDark ? light : dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

// ── Skeleton loaders ───────────────────────────────────────────────────────
class _PodiumSkeleton extends StatelessWidget {
  const _PodiumSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 230,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: 62,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
          ),
        ),
      ),
    );
  }
}
