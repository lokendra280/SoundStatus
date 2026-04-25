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
  );

  ProfileModel copyWith({
    int? coinBalance,
    int? shareCountToday,
    int? streakCount,
    int? uploadCount,
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
  );

  bool get canShareFree => shareCountToday < AppConstants.freeDailyShares;
}
