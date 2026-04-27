import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/ad_reward_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';
import 'package:soundstatus/wallet/states/wallet_state.dart';

final walletPresenterProvider = NotifierProvider<WalletPresenter, WalletState>(
  WalletPresenter.new,
);

class WalletPresenter extends Notifier<WalletState> {
  @override
  WalletState build() {
    // Watch ad provider and sync adReady into our state
    final adReady = ref.watch(adRewardProvider);
    // Watch transactions and sync into state
    final txnsAsync = ref.watch(walletProvider);

    txnsAsync.whenData((list) {
      if (state.transactions != list) {
        state = state.copyWith(transactions: list);
      }
    });

    return WalletState(
      adReady: adReady,
      transactions: ref.read(walletProvider).valueOrNull ?? [],
    );
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
    // Check daily limit
    if (state.adLimitReached) {
      return WatchAdResult.limitReached;
    }

    // Check ad ready
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
        // Sync updated data
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
  Future<SpendResult> spendCoins(int amount, String label) async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return SpendResult.error;
    if ((profile.coinBalance) < amount) return SpendResult.insufficient;

    try {
      await ref
          .read(walletProvider.notifier)
          .addCoins(amount: -amount, source: TxSource.shareSound, note: label);
      await ref.read(profileProvider.notifier).refresh();
      await ref.read(walletProvider.notifier).refresh();
      return SpendResult.success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return SpendResult.error;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Result enums ──────────────────────────────────────
enum WatchAdResult { rewarded, dismissed, limitReached, notReady, error }

enum SpendResult { success, insufficient, error }
