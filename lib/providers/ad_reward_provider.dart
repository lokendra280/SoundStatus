import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';

class AdRewardNotifier extends Notifier<bool> {
  RewardedAd? _ad;
  bool _isLoading = false;

  @override
  bool build() {
    _loadAd();
    return false; // isReady
  }

  // ── Ad unit id ────────────────────────────────────────
  String get _adUnitId => Platform.isAndroid
      ? AppConstants.rewardedAdUnitAndroid
      : AppConstants.rewardedAdUnitIOS;

  // ── Load ad ───────────────────────────────────────────
  Future<void> _loadAd() async {
    if (_isLoading) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          state = true;
          debugPrint('AdReward: ad loaded successfully');
        },
        onAdFailedToLoad: (err) {
          debugPrint('AdReward: failed to load: $err');
          _isLoading = false;
          state = false;
        },
      ),
    );
  }

  // ── Check daily limit ─────────────────────────────────
  Future<bool> canWatchAd() async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final today = DateTime.now().toUtc();
      final start = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final end = DateTime(
        today.year,
        today.month,
        today.day + 1,
      ).toIso8601String();

      final watches = await supabase
          .from('ad_watches')
          .select('id')
          .eq('user_id', uid)
          .gte('watched_at', start)
          .lt('watched_at', end);

      final watchCount = watches is List ? watches.length : 0;
      debugPrint(
        'AdReward: watched today=$watchCount max=${AppConstants.maxDailyAdWatches}',
      );
      return watchCount < AppConstants.maxDailyAdWatches;
    } catch (e) {
      debugPrint('AdReward: canWatchAd error: $e');
      return false;
    }
  }

  // ── Show ad ───────────────────────────────────────────
  Future<bool> showAd() async {
    if (_ad == null) {
      debugPrint('AdReward: no ad loaded, reloading');
      await _loadAd();
      return false;
    }

    bool rewarded = false;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdReward: ad dismissed');
        ad.dispose();
        _ad = null;
        state = false;
        _loadAd(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('AdReward: failed to show: $err');
        ad.dispose();
        _ad = null;
        state = false;
        _loadAd();
      },
    );

    await _ad!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint('AdReward: user earned reward');
        rewarded = true;
        await _grantAdReward();
      },
    );

    return rewarded;
  }

  // ── Grant reward ──────────────────────────────────────
  Future<void> _grantAdReward() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      // Record the ad watch in ad_watches table
      await supabase.from('ad_watches').insert({
        'user_id': uid,
        'coins_earned': AppConstants.adRewardCoins,
      });
      debugPrint('AdReward: ad_watches record inserted');

      // Add coins using TxSource enum — no raw strings
      await ref
          .read(walletProvider.notifier)
          .earn(
            amount: AppConstants.adRewardCoins,
            source: TxSource.adReward,
            note: 'Watched rewarded ad',
          );
      debugPrint('AdReward: coins granted: ${AppConstants.adRewardCoins}');

      // Refresh profile to sync coin balance in UI
      await ref.read(profileProvider.notifier).refresh();
      debugPrint('AdReward: profile refreshed');
    } catch (e) {
      debugPrint('AdReward: _grantAdReward error: $e');
    }
  }

  // ── Reload ────────────────────────────────────────────
  Future<void> reload() => _loadAd();
}

final adRewardProvider = NotifierProvider<AdRewardNotifier, bool>(
  AdRewardNotifier.new,
);
