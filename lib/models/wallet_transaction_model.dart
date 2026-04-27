enum TxType { earn, spend }

enum TxSource {
  adReward,
  uploadReward,
  systemBonus,
  streakBonus,
  spendUnlock,
  shareSound, // new — deduct 3 coins on share
  shareRefund, // new — refund when share fails
}

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

        amount: (j['amount'] as num).toInt().abs(), // always positive
        source: _sourceFromString(j['source']),
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );

  static TxSource _sourceFromString(String? s) => switch (s) {
    'ad_reward' => TxSource.adReward,
    'upload_reward' => TxSource.uploadReward,
    'streak_bonus' => TxSource.streakBonus,
    'spend_unlock' => TxSource.spendUnlock,
    'share_sound' => TxSource.shareSound,
    'share_refund' => TxSource.shareRefund,
    _ => TxSource.systemBonus,
  };

  // Source string for passing to Supabase RPC
  static String sourceToString(TxSource source) => switch (source) {
    TxSource.adReward => 'ad_reward',
    TxSource.uploadReward => 'upload_reward',
    TxSource.systemBonus => 'system_bonus',
    TxSource.streakBonus => 'streak_bonus',
    TxSource.spendUnlock => 'spend_unlock',
    TxSource.shareSound => 'share_sound',
    TxSource.shareRefund => 'share_refund',
  };

  String get sourceLabel => switch (source) {
    TxSource.adReward => 'Watched Ad',
    TxSource.uploadReward => 'Sound Approved',
    TxSource.systemBonus => 'System Bonus',
    TxSource.streakBonus => 'Streak Bonus',
    TxSource.spendUnlock => 'Spent on Unlock',
    TxSource.shareSound => 'Sound Shared',
    TxSource.shareRefund => 'Share Refund',
  };

  String get icon => switch (source) {
    TxSource.adReward => '📺',
    TxSource.uploadReward => '🎵',
    TxSource.systemBonus => '🎁',
    TxSource.streakBonus => '🔥',
    TxSource.spendUnlock => '🔓',
    TxSource.shareSound => '📤',
    TxSource.shareRefund => '↩️',
  };
}
