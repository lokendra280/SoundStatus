import 'package:soundstatus/core/constants.dart';

class ProfileModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int coinBalance;
  final int uploadCount;
  final int shareCountToday;
  final String shareResetDate;
  final int streakCount;
  final String? lastActiveDate;
  final int shareCount;
  final int followers;
  final int scoreToday;
  final int leaderboardRank;
  final String tier;
  final bool notificationsEnabled;
  final String soundQuality;

  const ProfileModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.coinBalance = 0,
    this.uploadCount = 0,
    this.shareCountToday = 0,
    this.shareResetDate = '',
    this.streakCount = 0,
    this.lastActiveDate,
    this.shareCount = 0,
    this.followers = 0,
    this.scoreToday = 0,
    this.leaderboardRank = 0,
    this.tier = 'Bronze',
    this.notificationsEnabled = true,
    this.soundQuality = 'High',
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
    id: j['id'],
    name: j['name'] ?? 'Anonymous',
    avatarUrl: j['avatar_url'],
    coinBalance: j['coin_balance'] ?? 0,
    uploadCount: j['upload_count'] ?? 0,
    shareCountToday: j['share_count_today'] ?? 0,
    shareResetDate: j['share_reset_date'] ?? '',
    streakCount: j['streak_count'] ?? 0,
    lastActiveDate: j['last_active_date'],
    shareCount: (j['share_count'] as num?)?.toInt() ?? 0,
    followers: (j['followers'] as num?)?.toInt() ?? 0,
    scoreToday: (j['score_today'] as num?)?.toInt() ?? 0,
    leaderboardRank: (j['leaderboard_rank'] as num?)?.toInt() ?? 0,
    tier: j['tier'] as String? ?? 'Bronze',
    notificationsEnabled: j['notifications_enabled'] as bool? ?? true,
    soundQuality: j['sound_quality'] as String? ?? 'High',
  );

  ProfileModel copyWith({
    int? coinBalance,
    int? shareCountToday,
    int? streakCount,
    int? uploadCount,
    int? shareCount,
    int? followers,
    int? scoreToday,
    int? leaderboardRank,
    String? tier,
    bool? notificationsEnabled,
    String? soundQuality,
  }) => ProfileModel(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    coinBalance: coinBalance ?? this.coinBalance,
    shareCountToday: shareCountToday ?? this.shareCountToday,
    streakCount: streakCount ?? this.streakCount,
    uploadCount: uploadCount ?? this.uploadCount,
    shareResetDate: shareResetDate,
    lastActiveDate: lastActiveDate,
    shareCount: shareCount ?? this.shareCount,
    followers: followers ?? this.followers,
    scoreToday: scoreToday ?? this.scoreToday,
    leaderboardRank: leaderboardRank ?? this.leaderboardRank,
    tier: tier ?? this.tier,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    soundQuality: soundQuality ?? this.soundQuality,
  );
  String get initials {
    final n = name ?? 'U';
    final parts = n.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : n.substring(0, n.length.clamp(0, 2)).toUpperCase();
  }

  String get tierEmoji => switch (tier) {
    'Silver' => '🥈',
    'Gold' => '🥇',
    'Platinum' => '💎',
    _ => '🥉',
  };

  int get sharesRemaining => (5 - shareCountToday).clamp(0, 5);
  bool get canShare => sharesRemaining > 0;

  String formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  bool get canShareFree => shareCountToday < AppConstants.freeDailyShares;
}
