import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/providers/leaderboard_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';

const _purple = Color(0xFF534AB7);
const _purpleLight = Color(0xFFEEEDFE);
const _purpleMid = Color(0xFFAFA9EC);
const _dark = Color(0xFF1A1A1A);
const _amber = Color(0xFFBA7517);
const _amberLight = Color(0xFFFAEEDA);

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardState();
}

class _LeaderboardState extends ConsumerState<LeaderboardScreen> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    final leaderboard = ref.watch(leaderboardProvider(_period));
    final myProfile = ref.watch(profileProvider).valueOrNull;
    final myRank = ref.watch(myRankProvider(_period));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        actions: [
          // Period toggle
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
            child: Row(
              children: ['daily', 'weekly', 'creator'].map((p) {
                final active = _period == p;
                return GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? _purple : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p[0].toUpperCase() + p.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFEFEFEF)),
        ),
      ),
      body: RefreshIndicator(
        color: _purple,
        onRefresh: () => ref.refresh(leaderboardProvider(_period).future),
        child: CustomScrollView(
          slivers: [
            // ── Podium (top 3) ───────────────────────────
            SliverToBoxAdapter(
              child: leaderboard.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: _purple),
                  ),
                ),
                error: (e, _) => const SizedBox(),
                data: (list) => list.length >= 3
                    ? _Podium(entries: list.take(3).toList())
                    : const SizedBox(),
              ),
            ),

            // ── My rank card ──────────────────────────────
            SliverToBoxAdapter(
              child: myRank.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (rank) => rank != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

            // ── Rankings list ─────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Rankings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
            ),

            leaderboard.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Failed to load',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final e = list[i];
                    final isMe = e.userId == myProfile?.id;
                    final isTop3 = i < 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RankRow(
                        rank: i + 1,
                        entry: e,
                        isMe: isMe,
                        isTop3: isTop3,
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

// ── Podium ────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _periodLabel,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PodiumSlot(entry: second, rank: 2, height: 60),
              _PodiumSlot(entry: first, rank: 1, height: 80, crown: true),
              _PodiumSlot(entry: third, rank: 3, height: 48),
            ],
          ),
        ],
      ),
    );
  }

  String get _periodLabel => 'Daily Hustle · Resets every 24h';
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final bool crown;
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.height,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = crown ? 52.0 : 40.0;
    return Column(
      children: [
        if (crown) const Text('👑', style: TextStyle(fontSize: 16)),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: crown ? Colors.white : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _initials(entry.name),
              style: TextStyle(
                fontSize: crown ? 18 : 14,
                fontWeight: FontWeight.w600,
                color: crown ? _purple : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '@${entry.name}',
          style: const TextStyle(fontSize: 9, color: Colors.white70),
        ),
        Text(
          '#$rank',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.amber[300],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(crown ? 0.2 : 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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

// ── My rank card ──────────────────────────────────────
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _purpleLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _purpleMid),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Text(
              'Your rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C3489),
              ),
            ),
            const Spacer(),
            Text(
              '#${rank.rank}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _purple,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· $score pts',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / (score + ptsToNext)).clamp(0.0, 1.0),
            backgroundColor: _purpleMid.withOpacity(0.3),
            color: _purple,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$ptsToNext pts to reach next rank',
            style: const TextStyle(fontSize: 10, color: Color(0xFF7F77DD)),
          ),
        ),
      ],
    ),
  );
}

// ── Rank row ──────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe, isTop3;
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isMe ? _purpleLight : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isMe ? _purpleMid : const Color(0xFFEFEFEF)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isTop3 ? _amber : Colors.grey[500],
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? _purple : _purpleLight,
          ),
          child: Center(
            child: Text(
              _initials(entry.name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : _purple,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? 'You · @${entry.name}' : '@${entry.name}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? _purple : _dark,
                ),
              ),
              Text(
                entry.tier,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Text(
          '${entry.score}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isMe ? _purple : _dark,
          ),
        ),
      ],
    ),
  );

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
