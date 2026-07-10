import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';

class LeaderboardEntry {
  final String userId, name, tier;
  final int rank, score, ptsToNextRank;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.tier,
    required this.rank,
    required this.score,
    this.ptsToNextRank = 0,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m, {int pts = 0}) =>
      LeaderboardEntry(
        userId: m['user_id'] as String,
        name: m['name'] as String? ?? 'User',
        tier: m['tier'] as String? ?? 'bronze',
        rank: (m['rank'] as num).toInt(),
        score: (m['score'] as num?)?.toInt() ?? 0,
        ptsToNextRank: pts,
      );
}

int _score(Map<String, dynamic> m) => (m['score'] as num?)?.toInt() ?? 0;

/// Points needed to beat the nearest strictly-higher score above index [i].
int _ptsToNext(List<Map<String, dynamic>> list, int i) {
  for (var j = i - 1; j >= 0; j--) {
    if (_score(list[j]) > _score(list[i])) {
      return _score(list[j]) - _score(list[i]) + 1;
    }
  }
  return 0;
}

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, period) async {
      final res = await supabase.rpc(
        'get_leaderboard',
        params: {'p_period_type': period},
      );
      final list = (res as List).cast<Map<String, dynamic>>();

      return [
        for (var i = 0; i < list.length; i++)
          LeaderboardEntry.fromMap(list[i], pts: _ptsToNext(list, i)),
      ];
    });

final myRankProvider = FutureProvider.family<LeaderboardEntry?, String>((
  ref,
  period,
) async {
  final uid = currentUserId;
  if (uid == null) return null;

  // Cheap path: already on the fetched page.
  final list = await ref.watch(leaderboardProvider(period).future);
  for (final e in list) {
    if (e.userId == uid) return e;
  }

  // Fallback: below the page cutoff.
  final res =
      await supabase.rpc('get_my_rank', params: {'p_period_type': period})
          as Map<String, dynamic>;
  if (res['rank'] == null) return null; // no score this period yet

  return LeaderboardEntry(
    userId: uid,
    name: 'You',
    tier: 'bronze',
    rank: (res['rank'] as num).toInt(),
    score: (res['score'] as num).toInt(),
  );
});
