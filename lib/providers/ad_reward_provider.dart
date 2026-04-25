import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdRewardNotifier extends Notifier<bool> {
  RewardedAd? _ad;
  bool _isLoading = false;

  @override
  bool build() {
    _loadAd();
    return false; // isReady
  }

  String get _adUnitId => Platform.isAndroid
      ? AppConstants.rewardedAdUnitAndroid
      : AppConstants.rewardedAdUnitIOS;

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
        },
        onAdFailedToLoad: (err) {
          debugPrint('Ad failed to load: $err');
          _isLoading = false;
          state = false;
        },
      ),
    );
  }

  Future<bool> canWatchAd() async {
    final uid = currentUserId;
    if (uid == null) return false;

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
        // .select('id', FetchOptions(count: CountOption.exact))
        .eq('user_id', uid)
        .gte('watched_at', start)
        .lt('watched_at', end);
    final watchCount = watches is List ? watches.length : 0;
    return watchCount < AppConstants.maxDailyAdWatches;
  }

  Future<bool> showAd() async {
    if (_ad == null) {
      await _loadAd();
      return false;
    }

    bool rewarded = false;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        state = false;
        _loadAd(); // pre-load next
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _ad = null;
        state = false;
        _loadAd();
      },
    );

    _ad!.show(
      onUserEarnedReward: (ad, reward) async {
        rewarded = true;
        await _grantAdReward();
      },
    );

    return rewarded;
  }

  Future<void> _grantAdReward() async {
    final uid = currentUserId;
    if (uid == null) return;

    // Record the ad watch
    await supabase.from('ad_watches').insert({
      'user_id': uid,
      'coins_earned': AppConstants.adRewardCoins,
    });

    // Add coins via RPC
    await ref
        .read(walletProvider.notifier)
        .addCoins(
          amount: AppConstants.adRewardCoins,
          source: 'ad_reward',
          note: 'Watched rewarded ad',
        );

    // Refresh profile for updated coin balance
    await ref.read(profileProvider.notifier).refresh();
  }

  Future<void> reload() => _loadAd();
}

final adRewardProvider = NotifierProvider<AdRewardNotifier, bool>(
  AdRewardNotifier.new,
);
