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

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j, int rank) =>
      LeaderboardEntry(
        userId: j['user_id'] as String,
        name: j['name'] as String? ?? 'User',
        tier: j['tier'] as String? ?? 'bronze',
        rank: rank,
        score: (j['score'] as num?)?.toInt() ?? 0,
        ptsToNextRank: (j['pts_to_next'] as num?)?.toInt() ?? 0,
      );
}

// Leaderboard list provider
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((
  ref,
  period,
) async {
  final today = DateTime.now().toUtc();
  final periodKey = switch (period) {
    'weekly' => '${today.year}-W${_weekNumber(today)}',
    'creator' => '${today.year}-${today.month.toString().padLeft(2, '0')}',
    _ =>
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
  };

  final res = await supabase
      .from('leaderboard_scores')
      .select('user_id, score, tier, profiles(name)')
      .eq('period_type', period == 'creator' ? 'creator' : 'daily')
      .eq('period_key', periodKey)
      .order('score', ascending: false)
      .limit(50);

  return (res as List).asMap().entries.map((e) {
    final json = Map<String, dynamic>.from(e.value as Map);
    json['name'] = (json['profiles'] as Map?)?['name'] ?? 'User';
    return LeaderboardEntry.fromJson(json, e.key + 1);
  }).toList();
});

// My rank provider
final myRankProvider = FutureProvider.family<LeaderboardEntry?, String>((
  ref,
  period,
) async {
  final uid = currentUserId;
  if (uid == null) return null;

  final today = DateTime.now().toUtc();
  final periodKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final res = await supabase
      .from('leaderboard_scores')
      .select('user_id, score, tier')
      .eq('user_id', uid)
      .eq('period_type', 'daily')
      .eq('period_key', periodKey)
      .maybeSingle();

  if (res == null) return null;

  // Get rank by counting users with higher score
  final higher = await supabase
      .from('leaderboard_scores')
      .select('id')
      .eq('period_type', 'daily')
      .eq('period_key', periodKey)
      .gt('score', res['score'] as int);

  final rank = (higher as List).length + 1;
  final score = (res['score'] as num).toInt();
  final ptsToNext = rank > 1 ? 50 : 0; // simplified

  return LeaderboardEntry(
    userId: uid,
    name: 'You',
    tier: res['tier'] as String? ?? 'bronze',
    rank: rank,
    score: score,
    ptsToNextRank: ptsToNext,
  );
});

int _weekNumber(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  final diff = date.difference(startOfYear).inDays;
  return (diff / 7).ceil();
}
