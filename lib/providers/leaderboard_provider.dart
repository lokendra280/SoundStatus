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
    required this.ptsToNextRank,
  });
}

// Leaderboard list provider
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, period) async {
      final res = await supabase.rpc(
        'get_leaderboard',
        params: {'p_period': period},
      );

      final list = (res as List).cast<Map<String, dynamic>>();

      return [
        for (var i = 0; i < list.length; i++)
          LeaderboardEntry(
            userId: list[i]['user_id'] as String,
            name: list[i]['name'] as String? ?? 'User',
            tier: list[i]['tier'] as String? ?? 'bronze',
            rank: (list[i]['rank'] as num).toInt(),
            score: (list[i]['score'] as num?)?.toInt() ?? 0,
            // pts to overtake the person directly above
            ptsToNextRank: i == 0
                ? 0
                : ((list[i - 1]['score'] as num).toInt() -
                      (list[i]['score'] as num).toInt() +
                      1),
          ),
      ];
    });

// My rank provider — derives from the same list, correct for every period,
// and costs zero extra queries.
final myRankProvider = FutureProvider.family<LeaderboardEntry?, String>((
  ref,
  period,
) async {
  final uid = currentUserId;
  if (uid == null) return null;

  final list = await ref.watch(leaderboardProvider(period).future);
  for (final e in list) {
    if (e.userId == uid) return e;
  }
  return null; // not in top 50 (or no score yet this period)
});
