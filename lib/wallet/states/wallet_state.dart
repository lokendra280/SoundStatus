import 'package:soundstatus/models/wallet_transaction_model.dart';

class WalletState {
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final bool adReady;
  final bool watchingAd;
  final String? error;

  const WalletState({
    this.transactions = const [],
    this.isLoading = false,
    this.adReady = false,
    this.watchingAd = false,
    this.error,
  });

  // Computed from real transactions — no separate provider needed
  int get adsWatchedToday {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return transactions
        .where(
          (t) =>
              t.source == 'ad_reward' && t.createdAt.toLocal().isAfter(start),
        )
        .length;
  }

  int get adsRemaining => (10 - adsWatchedToday).clamp(0, 10);
  bool get adLimitReached => adsRemaining == 0;

  int get coinsEarnedThisWeek {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return transactions
        .where(
          (t) =>
              t.type == TxType.earn && t.createdAt.toLocal().isAfter(weekStart),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  int get streakDays {
    if (transactions.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days =
        transactions
            .map((t) {
              final d = t.createdAt.toLocal();
              return DateTime(d.year, d.month, d.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime expected = today;
    for (final day in days) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  WalletState copyWith({
    List<WalletTransaction>? transactions,
    bool? isLoading,
    bool? adReady,
    bool? watchingAd,
    String? error,
    bool clearError = false,
  }) => WalletState(
    transactions: transactions ?? this.transactions,
    isLoading: isLoading ?? this.isLoading,
    adReady: adReady ?? this.adReady,
    watchingAd: watchingAd ?? this.watchingAd,
    error: clearError ? null : (error ?? this.error),
  );
}
