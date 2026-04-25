// lib/models/badge_model.dart

import 'package:flutter/material.dart';

enum BadgeTier { bronze, silver, gold, platinum }

class CoinBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final BadgeTier tier;
  final int coinsRequired; // total coins earned to unlock
  final int? uploadsRequired; // optional: needs X approved uploads
  final int? streakRequired; // optional: needs X day streak
  final int? sharesRequired; // optional: needs X total shares
  final Color color;

  const CoinBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.tier,
    required this.coinsRequired,
    this.uploadsRequired,
    this.streakRequired,
    this.sharesRequired,
    required this.color,
  });

  String get tierLabel => switch (tier) {
    BadgeTier.bronze => 'Bronze',
    BadgeTier.silver => 'Silver',
    BadgeTier.gold => 'Gold',
    BadgeTier.platinum => 'Platinum',
  };

  Color get tierColor => switch (tier) {
    BadgeTier.bronze => const Color(0xFFCD7F32),
    BadgeTier.silver => const Color(0xFF9E9E9E),
    BadgeTier.gold => const Color(0xFFFFD700),
    BadgeTier.platinum => const Color(0xFF00BCD4),
  };
}

// ── All badges in the app ────────────────────────────────────────────
const List<CoinBadge> kAllBadges = [
  // ── Coin milestones ──
  CoinBadge(
    id: 'first_coin',
    emoji: '🪙',
    title: 'First Coin',
    description: 'Earn your very first coin',
    tier: BadgeTier.bronze,
    coinsRequired: 1,
    color: Color(0xFFFFF8E1),
  ),
  CoinBadge(
    id: 'coin_50',
    emoji: '💰',
    title: 'Pocket Change',
    description: 'Earn 50 coins total',
    tier: BadgeTier.bronze,
    coinsRequired: 50,
    color: Color(0xFFFFF8E1),
  ),
  CoinBadge(
    id: 'coin_100',
    emoji: '💵',
    title: 'Century Club',
    description: 'Earn 100 coins total',
    tier: BadgeTier.silver,
    coinsRequired: 100,
    color: Color(0xFFE3F2FD),
  ),
  CoinBadge(
    id: 'coin_250',
    emoji: '💎',
    title: 'High Roller',
    description: 'Earn 250 coins total',
    tier: BadgeTier.silver,
    coinsRequired: 250,
    color: Color(0xFFE3F2FD),
  ),
  CoinBadge(
    id: 'coin_500',
    emoji: '🏦',
    title: 'Bank Account',
    description: 'Earn 500 coins total',
    tier: BadgeTier.gold,
    coinsRequired: 500,
    color: Color(0xFFFFF9C4),
  ),
  CoinBadge(
    id: 'coin_1000',
    emoji: '👑',
    title: 'Coin King',
    description: 'Earn 1000 coins total',
    tier: BadgeTier.gold,
    coinsRequired: 1000,
    color: Color(0xFFFFF9C4),
  ),
  CoinBadge(
    id: 'coin_5000',
    emoji: '🌟',
    title: 'Legend',
    description: 'Earn 5000 coins total',
    tier: BadgeTier.platinum,
    coinsRequired: 5000,
    color: Color(0xFFE0F7FA),
  ),

  // ── Upload badges ──
  CoinBadge(
    id: 'first_upload',
    emoji: '🎵',
    title: 'Sound Maker',
    description: 'Get your first sound approved',
    tier: BadgeTier.bronze,
    coinsRequired: 0,
    uploadsRequired: 1,
    color: Color(0xFFF3E5F5),
  ),
  CoinBadge(
    id: 'upload_5',
    emoji: '🎶',
    title: 'Sound Producer',
    description: 'Get 5 sounds approved',
    tier: BadgeTier.silver,
    coinsRequired: 0,
    uploadsRequired: 5,
    color: Color(0xFFF3E5F5),
  ),
  CoinBadge(
    id: 'upload_20',
    emoji: '🎤',
    title: 'Studio Artist',
    description: 'Get 20 sounds approved',
    tier: BadgeTier.gold,
    coinsRequired: 0,
    uploadsRequired: 20,
    color: Color(0xFFF3E5F5),
  ),

  // ── Streak badges ──
  CoinBadge(
    id: 'streak_7',
    emoji: '🔥',
    title: 'On Fire',
    description: 'Keep a 7-day streak',
    tier: BadgeTier.bronze,
    coinsRequired: 0,
    streakRequired: 7,
    color: Color(0xFFFBE9E7),
  ),
  CoinBadge(
    id: 'streak_30',
    emoji: '🌋',
    title: 'Unstoppable',
    description: 'Keep a 30-day streak',
    tier: BadgeTier.gold,
    coinsRequired: 0,
    streakRequired: 30,
    color: Color(0xFFFBE9E7),
  ),
  CoinBadge(
    id: 'streak_100',
    emoji: '⚡',
    title: 'Lightning',
    description: 'Keep a 100-day streak',
    tier: BadgeTier.platinum,
    coinsRequired: 0,
    streakRequired: 100,
    color: Color(0xFFFBE9E7),
  ),

  // ── Share badges ──
  CoinBadge(
    id: 'share_10',
    emoji: '📤',
    title: 'Sharing is Caring',
    description: 'Share 10 statuses',
    tier: BadgeTier.bronze,
    coinsRequired: 0,
    sharesRequired: 10,
    color: Color(0xFFE8F5E9),
  ),
  CoinBadge(
    id: 'share_50',
    emoji: '📣',
    title: 'Broadcaster',
    description: 'Share 50 statuses',
    tier: BadgeTier.silver,
    coinsRequired: 0,
    sharesRequired: 50,
    color: Color(0xFFE8F5E9),
  ),
  CoinBadge(
    id: 'share_200',
    emoji: '🌍',
    title: 'Viral',
    description: 'Share 200 statuses',
    tier: BadgeTier.platinum,
    coinsRequired: 0,
    sharesRequired: 200,
    color: Color(0xFFE8F5E9),
  ),
];
