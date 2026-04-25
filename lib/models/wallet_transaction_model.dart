enum TxType { earn, spend }

enum TxSource { adReward, uploadReward, systemBonus, streakBonus, spendUnlock }

class WalletTransaction {
  final String id;
  final String userId;
  final TxType type;
  final int amount;
  final TxSource source;
  final String? note;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.source,
    this.note,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        id: j['id'],
        userId: j['user_id'],
        type: j['type'] == 'earn' ? TxType.earn : TxType.spend,
        amount: j['amount'],
        source: _sourceFromString(j['source']),
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );

  static TxSource _sourceFromString(String? s) => switch (s) {
    'ad_reward' => TxSource.adReward,
    'upload_reward' => TxSource.uploadReward,
    'streak_bonus' => TxSource.streakBonus,
    'spend_unlock' => TxSource.spendUnlock,
    _ => TxSource.systemBonus,
  };

  String get sourceLabel => switch (source) {
    TxSource.adReward => 'Watched Ad',
    TxSource.uploadReward => 'Sound Approved',
    TxSource.systemBonus => 'System Bonus',
    TxSource.streakBonus => 'Streak Bonus',
    TxSource.spendUnlock => 'Spent on Unlock',
  };

  String get icon => switch (source) {
    TxSource.adReward => '📺',
    TxSource.uploadReward => '🎵',
    TxSource.systemBonus => '🎁',
    TxSource.streakBonus => '🔥',
    TxSource.spendUnlock => '🔓',
  };
}
