import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/ad_reward_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';
import 'package:soundstatus/wallet/states/wallet_state.dart';

final walletPresenterProvider = NotifierProvider<WalletPresenter, WalletState>(
  WalletPresenter.new,
);

// ── Spend catalog ─────────────────────────────────────
// One source of truth for what can be bought. The `key` must match the
// p_item values handled inside the spend_coins RPC.
enum SpendItem {
  // boostSound(cost: 100, label: 'Boost sound visibility', key: 'boost_sound'),
  // premiumTemplate(
  //   cost: 200,
  //   label: 'Unlock premium template',
  //   key: 'premium_template',
  // ),
  extraShares(cost: 50, label: 'Extra daily shares (+5)', key: 'extra_shares'),
  removeAds1Day(cost: 30, label: 'Remove ads (1 day)', key: 'remove_ads_1_day');

  const SpendItem({required this.cost, required this.label, required this.key});
  final int cost;
  final String label;
  final String key;
}

// ── Result enums ──────────────────────────────────────
enum WatchAdResult { rewarded, dismissed, limitReached, notReady, error }

enum SpendResult { success, insufficient, error }

enum SpinResult { won, alreadySpun, error }

class SpinOutcome {
  final SpinResult result;
  final int prize;
  const SpinOutcome(this.result, [this.prize = 0]);
}

// ── Presenter ─────────────────────────────────────────
class WalletPresenter extends Notifier<WalletState> {
  @override
  WalletState build() {
    final adReady = ref.watch(adRewardProvider);

    final txnsAsync = ref.watch(walletProvider);
    final transactions = txnsAsync.valueOrNull ?? [];

    ref.listen<AsyncValue<List<WalletTransaction>>>(walletProvider, (
      prev,
      next,
    ) {
      next.whenData((list) {
        state = state.copyWith(transactions: list);
      });
    });

    return WalletState(adReady: adReady, transactions: transactions);
  }

  // ── Refresh all ──────────────────────────────────────
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.wait([
        ref.read(walletProvider.notifier).refresh(),
        ref.read(profileProvider.notifier).refresh(),
        ref.read(adRewardProvider.notifier).reload(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Watch rewarded ad ────────────────────────────────
  Future<WatchAdResult> watchAd() async {
    if (state.adLimitReached) {
      return WatchAdResult.limitReached;
    }

    if (!state.adReady) {
      await ref.read(adRewardProvider.notifier).reload();
      return WatchAdResult.notReady;
    }

    state = state.copyWith(watchingAd: true);
    try {
      final canWatch = await ref.read(adRewardProvider.notifier).canWatchAd();
      if (!canWatch) return WatchAdResult.limitReached;

      final rewarded = await ref.read(adRewardProvider.notifier).showAd();
      if (rewarded) {
        await ref.read(walletProvider.notifier).refresh();
        await ref.read(profileProvider.notifier).refresh();
        return WatchAdResult.rewarded;
      }
      return WatchAdResult.dismissed;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return WatchAdResult.error;
    } finally {
      state = state.copyWith(watchingAd: false);
    }
  }

  // ── Spend coins ──────────────────────────────────────
  // The spend_coins RPC deducts the coins, logs the transaction AND grants
  // the entitlement (ad_free_until / extra_shares / ...) atomically in one
  // DB transaction — the user can never be charged without receiving the
  // benefit, and two rapid taps can't double-spend.
  Future<SpendResult> spendCoins(SpendItem item) async {
    // Fast local pre-check for instant feedback; the RPC re-checks
    // authoritatively with a row lock.
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return SpendResult.error;
    if (profile.coinBalance < item.cost) return SpendResult.insufficient;

    try {
      final ok = await supabase.rpc(
        'spend_coins',
        params: {
          'p_amount': item.cost,
          'p_item': item.key,
          'p_note': item.label,
        },
      );

      if (ok != true) return SpendResult.insufficient;

      await ref.read(profileProvider.notifier).refresh();
      await ref.read(walletProvider.notifier).refresh();
      return SpendResult.success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return SpendResult.error;
    }
  }

  // ── Daily spin ───────────────────────────────────────
  // The server decides the prize and enforces one spin per UTC day.
  // The wheel UI just animates to whatever prize comes back.
  Future<SpinOutcome> claimDailySpin() async {
    try {
      final res = await supabase.rpc('claim_daily_spin');
      final map = Map<String, dynamic>.from(res as Map);
      switch (map['status']) {
        case 'ok':
          // Refresh balance + transaction history to show the new coins
          await ref.read(profileProvider.notifier).refresh();
          await ref.read(walletProvider.notifier).refresh();
          return SpinOutcome(SpinResult.won, (map['prize'] as num).toInt());
        case 'already_spun':
          return const SpinOutcome(SpinResult.alreadySpun);
        default:
          return const SpinOutcome(SpinResult.error);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return const SpinOutcome(SpinResult.error);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
