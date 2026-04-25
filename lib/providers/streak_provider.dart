import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';

class StreakNotifier extends Notifier<int> {
  @override
  int build() {
    return ref.watch(profileProvider).valueOrNull?.streakCount ?? 0;
  }

  Future<void> recordActivity() async {
    final uid = currentUserId;
    if (uid == null) return;

    final today = DateTime.now().toIso8601String().split('T').first;
    final profile = ref.read(profileProvider).valueOrNull;
    final lastActive = profile?.lastActiveDate;

    if (lastActive == today) return; // already active today

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    final newStreak = lastActive == yesterday
        ? (profile?.streakCount ?? 0) + 1
        : 1; // streak broken

    await supabase
        .from('profiles')
        .update({'streak_count': newStreak, 'last_active_date': today})
        .eq('id', uid);

    // Award bonus coins on milestone streaks
    if (newStreak % 7 == 0) {
      await ref
          .read(walletProvider.notifier)
          .addCoins(
            amount: AppConstants.streakBonusCoins * newStreak ~/ 7,
            source: 'streak_bonus',
            note: '${newStreak}-day streak bonus',
          );
    }

    await ref.read(profileProvider.notifier).refresh();
    state = newStreak;
  }
}

final streakProvider = NotifierProvider<StreakNotifier, int>(
  StreakNotifier.new,
);
