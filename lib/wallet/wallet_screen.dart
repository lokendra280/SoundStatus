import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/theme/theme.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';
import 'package:soundstatus/widgets/ad_reward_button.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final txns = ref.watch(walletProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileProvider.notifier).refresh();
          await ref.read(walletProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Balance card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 10),
                        Text(
                          '${profile?.coinBalance ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          ' coins',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AdRewardButton(
                      style: AdButtonStyle.outlined,
                      onRewarded: () {
                        ref.read(profileProvider.notifier).refresh();
                        ref.read(walletProvider.notifier).refresh();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Earn options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to earn coins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EarnCard(
                      icon: Assets.tv,
                      title: 'Watch a rewarded ad',
                      subtitle: 'Up to 10 times per day',
                      reward: '+10 coins',
                      color: Colors.blue.shade50,
                    ),
                    const SizedBox(height: 8),
                    _EarnCard(
                      icon: Assets.upload,
                      title: 'Upload a sound',
                      subtitle: 'When admin approves it',
                      reward: '+20 coins',
                      color: Colors.purple.shade50,
                    ),
                    const SizedBox(height: 8),
                    _EarnCard(
                      icon: Assets.strike,
                      title: '7-day streak',
                      subtitle: 'Stay active daily',
                      reward: '+5 coins/week',
                      color: Colors.orange.shade50,
                      iconColor: kAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Transaction list
            txns.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (list) => list.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TxCard(tx: list[i]),
                        childCount: list.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnCard extends StatelessWidget {
  final String icon, title, subtitle, reward;
  final Color? iconColor;
  final Color color;
  const _EarnCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        CommonSvgWidget(svgName: icon, height: 30, width: 30, color: iconColor),
        // Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          reward,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.amber,
          ),
        ),
      ],
    ),
  );
}

class _TxCard extends StatelessWidget {
  final WalletTransaction tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(tx.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.sourceLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (tx.note != null)
                  Text(
                    tx.note!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Text(
                  DateFormat('dd MMM • hh:mm a').format(tx.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${tx.type == TxType.earn ? '+' : '-'}${tx.amount}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: tx.type == TxType.earn ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    ),
  );
}
