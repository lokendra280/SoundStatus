// lib/providers/badge_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/models/bage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'profile_provider.dart';

class BadgeState {
  final List<CoinBadge> unlocked;
  final List<CoinBadge> locked;
  final int totalCoinsEarned; // lifetime total, not balance

  const BadgeState({
    required this.unlocked,
    required this.locked,
    required this.totalCoinsEarned,
  });

  double get progress =>
      unlocked.isEmpty ? 0 : unlocked.length / kAllBadges.length;
}

class BadgeNotifier extends AsyncNotifier<BadgeState> {
  @override
  Future<BadgeState> build() async {
    // Watch profile so badges refresh when profile changes
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) {
      return const BadgeState(
        unlocked: [],
        locked: kAllBadges,
        totalCoinsEarned: 0,
      );
    }
    return _compute(profile);
  }

  Future<BadgeState> _compute(ProfileModel profile) async {
    // Fetch lifetime coins earned (not current balance — balance can decrease)
    final uid = Supabase.instance.client.auth.currentUser?.id;
    int totalEarned = profile.coinBalance; // fallback

    if (uid != null) {
      try {
        final res = await Supabase.instance.client
            .from('wallet_transactions')
            .select('amount')
            .eq('user_id', uid)
            .eq('type', 'earn');

        totalEarned = (res as List).fold(
          0,
          (sum, row) => sum + (row['amount'] as int),
        );
      } catch (_) {}
    }

    // Also fetch total share count from statuses
    int totalShares = 0;
    if (uid != null) {
      try {
        final res = await Supabase.instance.client
            .from('statuses')
            .select('id')
            .eq('user_id', uid);
        totalShares = res.length ?? 0;
      } catch (_) {}
    }

    final unlocked = <CoinBadge>[];
    final locked = <CoinBadge>[];

    for (final badge in kAllBadges) {
      final coinOk = totalEarned >= badge.coinsRequired;
      final uploadOk =
          badge.uploadsRequired == null ||
          profile.uploadCount >= badge.uploadsRequired!;
      final streakOk =
          badge.streakRequired == null ||
          profile.streakCount >= badge.streakRequired!;
      final shareOk =
          badge.sharesRequired == null || totalShares >= badge.sharesRequired!;

      if (coinOk && uploadOk && streakOk && shareOk) {
        unlocked.add(badge);
      } else {
        locked.add(badge);
      }
    }

    return BadgeState(
      unlocked: unlocked,
      locked: locked,
      totalCoinsEarned: totalEarned,
    );
  }
}

final badgeProvider = AsyncNotifierProvider<BadgeNotifier, BadgeState>(
  BadgeNotifier.new,
);
