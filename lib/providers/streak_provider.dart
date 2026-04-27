import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';

class StreakNotifier extends Notifier<int> {
  @override
  int build() {
    return ref.watch(profileProvider).valueOrNull?.streakCount ?? 0;
  }

  // ── Called on every app open / screen visit ───────────
  Future<void> recordActivity() async {
    final uid = currentUserId;
    if (uid == null) return;

    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;

    final today = _dateString(DateTime.now());
    final lastActive = profile.lastActiveDate;

    // Already recorded activity today — skip
    if (lastActive == today) {
      debugPrint('Streak: already active today, skip');
      return;
    }

    final yesterday = _dateString(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Continue streak if active yesterday, else reset to 1
    final newStreak = lastActive == yesterday ? (profile.streakCount) + 1 : 1;

    debugPrint(
      'Streak: lastActive=$lastActive today=$today '
      'newStreak=$newStreak',
    );

    try {
      // Update streak in profiles table
      await supabase
          .from('profiles')
          .update({'streak_count': newStreak, 'last_active_date': today})
          .eq('id', uid);

      debugPrint('Streak: profile updated');

      // Award bonus coins on every 7-day milestone
      if (newStreak % 7 == 0) {
        final bonusCoins = AppConstants.streakBonusCoins * (newStreak ~/ 7);

        debugPrint(
          'Streak: milestone! newStreak=$newStreak '
          'bonusCoins=$bonusCoins',
        );

        await ref
            .read(walletProvider.notifier)
            .earn(
              amount: bonusCoins,
              source: TxSource.streakBonus,
              note: '$newStreak-day streak bonus',
            );

        debugPrint('Streak: bonus coins granted: $bonusCoins');
      }

      // Sync profile with updated streak + balance
      await ref.read(profileProvider.notifier).refresh();

      // Update local state
      state = newStreak;
      debugPrint('Streak: done, state=$newStreak');
    } catch (e) {
      debugPrint('Streak: recordActivity error: $e');
    }
  }

  // ── Helper ────────────────────────────────────────────
  String _dateString(DateTime dt) => dt.toIso8601String().split('T').first;
}

final streakProvider = NotifierProvider<StreakNotifier, int>(
  StreakNotifier.new,
);
