import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/wallet/states/wallet_presenter.dart';
import 'package:soundstatus/wallet/states/wallet_state.dart';
import 'package:soundstatus/widgets/balance_card.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletPresenterProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    // Show error snackbar reactively
    ref.listen(walletPresenterProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(walletPresenterProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: _WalletAppBar(state: state),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () => ref.read(walletPresenterProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BalanceCard(
                  coins: profile?.coinBalance ?? 0,
                  onEarn: () => _onWatchAd(context, ref),
                  onSpend: () => _showSpendSheet(context, ref, state),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _StatsRow(state: state),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _SectionTitle('How to earn coins'),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    _AdEarnCard(
                      state: state,
                      onWatch: () => _onWatchAd(context, ref),
                    ),
                    const SizedBox(height: 8),
                    const _EarnCard(
                      icon: Assets.uploadMusic,
                      title: 'Upload a sound',
                      subtitle: 'When admin approves it',
                      reward: '+20',
                      bg: AppColors.purpleLight,
                      iconBg: Color(0xFFCECBF6),
                      iconColor: Color(0xFF26215C),
                      titleColor: Color(0xFF3C3489),
                      subtitleColor: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const _EarnCard(
                      icon: Assets.strike,
                      title: '7-day streak bonus',
                      subtitle: 'Stay active every day',
                      reward: '+5/wk',
                      bg: AppColors.amberLight,
                      iconBg: Color(0xFFFAC775),
                      iconColor: Color(0xFF412402),
                      titleColor: Color(0xFF633806),
                      subtitleColor: Color(0xFF854F0B),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _SectionTitle('Transaction history'),
              ),
            ),

            _TransactionList(transactions: state.transactions),
          ],
        ),
      ),
    );
  }

  // ── Presenter calls (only place logic touches UI) ────
  Future<void> _onWatchAd(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(walletPresenterProvider.notifier).watchAd();
    if (!context.mounted) return;
    switch (result) {
      case WatchAdResult.rewarded:
        _showRewardDialog(context);
      case WatchAdResult.limitReached:
        _snack(
          context,
          'Daily ad limit reached. Come back tomorrow!',
          error: true,
        );
      case WatchAdResult.notReady:
        _snack(context, 'Ad is loading, please wait a moment...');
      case WatchAdResult.dismissed:
        break;
      case WatchAdResult.error:
        _snack(context, 'Something went wrong. Try again.', error: true);
    }
  }

  void _showSpendSheet(BuildContext context, WidgetRef ref, WalletState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SpendSheet(
        coins: ref.read(profileProvider).valueOrNull?.coinBalance ?? 0,
        onSpend: (amount, label) async {
          Navigator.pop(context);
          final result = await ref
              .read(walletPresenterProvider.notifier)
              .spendCoins(amount, label);
          if (!context.mounted) return;
          switch (result) {
            case SpendResult.success:
              _snack(context, '$label unlocked!');
            case SpendResult.insufficient:
              _snack(context, 'Not enough coins', error: true);
            case SpendResult.error:
              _snack(context, 'Something went wrong', error: true);
          }
        },
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RewardDialog(coins: 10),
    );
  }

  void _snack(BuildContext context, String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? AppColors.red : AppColors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
}

// ══════════════════════════════════════════════════════
//  APP BAR
// ══════════════════════════════════════════════════════
class _WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  final WalletState state;
  const _WalletAppBar({required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  Widget build(BuildContext context) => AppBar(
    elevation: 0,
    titleSpacing: 16,
    title: const Text(
      'My Wallet',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: state.adReady ? AppColors.tealLight : AppColors.amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: state.adReady
                        ? AppColors.teal
                        : AppColors.amberLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  state.adReady ? 'Ad ready' : 'Loading ad',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: state.adReady ? AppColors.teal : AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: const Color(0xFFEFEFEF)),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  BALANCE CARD
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
//  STATS ROW
// ══════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final WalletState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _MiniStat(
        label: 'Ads today',
        value: '${state.adsWatchedToday}x',
        color: AppColors.blue,
      ),
      const SizedBox(width: 8),
      _MiniStat(
        label: 'This week',
        value: '+${state.coinsEarnedThisWeek}',
        color: AppColors.teal,
      ),
      const SizedBox(width: 8),
      _MiniStat(
        label: 'Streak',
        value: '${state.streakDays}d',
        color: AppColors.amber,
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.darkGrey),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  AD EARN CARD
// ══════════════════════════════════════════════════════
class _AdEarnCard extends StatelessWidget {
  final WalletState state;
  final VoidCallback onWatch;
  const _AdEarnCard({required this.state, required this.onWatch});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.blueLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF85B7EB)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFB5D4F4),
                borderRadius: BorderRadius.circular(10),
              ),

              child: CommonSvgWidget(
                svgName: Assets.play,
                height: 10,
                width: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Watch a rewarded ad',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C447C),
                    ),
                  ),
                  Text(
                    state.adLimitReached
                        ? 'Daily limit reached'
                        : '${state.adsRemaining} of 10 left today',
                    style: const TextStyle(fontSize: 11, color: AppColors.blue),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.adLimitReached
                    ? AppColors.redLight
                    : const Color(0xFFB5D4F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.adLimitReached ? 'Done' : '+10',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: state.adLimitReached
                      ? AppColors.red
                      : const Color(0xFF0C447C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: state.adsWatchedToday / 10,
            backgroundColor: const Color(0xFFB5D4F4).withOpacity(0.4),
            color: state.adLimitReached ? AppColors.red : AppColors.blue,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: (state.adLimitReached || state.watchingAd) ? null : onWatch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: state.adLimitReached
                  ? Colors.grey[200]
                  : state.adReady
                  ? AppColors.primaryColor
                  : AppColors.purpleMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: state.watchingAd
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      state.adLimitReached
                          ? 'Come back tomorrow'
                          : state.adReady
                          ? 'Watch now  (${state.adsRemaining} left)'
                          : 'Loading ad...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: state.adLimitReached
                            ? AppColors.darkGrey
                            : AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  GENERIC EARN CARD
// ══════════════════════════════════════════════════════
class _EarnCard extends StatelessWidget {
  final String icon;
  final String title, subtitle, reward;
  final Color bg, iconBg, iconColor, titleColor, subtitleColor;
  const _EarnCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.bg,
    required this.iconBg,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: iconColor.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CommonSvgWidget(svgName: icon, color: iconColor),
          // child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            reward,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  TRANSACTION LIST
// ══════════════════════════════════════════════════════
class _TransactionList extends StatelessWidget {
  final List<WalletTransaction> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.purpleLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darks,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch an ad to earn your first coins',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TxCard(tx: transactions[i]),
          ),
          childCount: transactions.length,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TRANSACTION CARD
// ══════════════════════════════════════════════════════
class _TxCard extends StatelessWidget {
  final WalletTransaction tx;
  const _TxCard({required this.tx});

  IconData get _icon => switch (tx.source) {
    'ad_reward' => Icons.play_circle_rounded,
    'upload_bonus' => Icons.upload_rounded,
    'streak_bonus' => Icons.local_fire_department_rounded,
    'spend' => Icons.shopping_bag_rounded,
    _ => Icons.monetization_on_rounded,
  };

  Color get _iconBg =>
      tx.type == TxType.earn ? AppColors.tealLight : AppColors.redLight;
  Color get _iconColor =>
      tx.type == TxType.earn ? AppColors.teal : AppColors.red;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEFEFEF)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle),
          child: Icon(_icon, color: _iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.sourceLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darks,
                ),
              ),
              if (tx.note != null && tx.note!.isNotEmpty)
                Text(
                  tx.note!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              Text(
                DateFormat('dd MMM · hh:mm a').format(tx.createdAt.toLocal()),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${tx.type == TxType.earn ? '+' : '-'}${tx.amount}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _iconColor,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  REWARD DIALOG
// ══════════════════════════════════════════════════════
class _RewardDialog extends StatelessWidget {
  final int coins;
  const _RewardDialog({required this.coins});

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🪙', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Coins earned!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darks,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+$coins coins added to your wallet',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  SPEND SHEET
// ══════════════════════════════════════════════════════
class _SpendSheet extends StatelessWidget {
  final int coins;
  final void Function(int amount, String label) onSpend;
  const _SpendSheet({required this.coins, required this.onSpend});

  static const _items = [
    (
      label: 'Boost sound visibility',
      cost: 100,
      icon: Icons.rocket_launch_rounded,
    ),
    (label: 'Unlock premium template', cost: 200, icon: Icons.star_rounded),
    (label: 'Extra daily shares', cost: 50, icon: Icons.share_rounded),
    (label: 'Remove ads (1 day)', cost: 150, icon: Icons.block_rounded),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spend coins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darks,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._items.map((item) {
          final canAfford = coins >= item.cost;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: canAfford ? () => onSpend(item.cost, item.label) : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.white : const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: canAfford
                        ? const Color(0xFFEFEFEF)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppColors.purpleLight
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: canAfford
                            ? AppColors.primaryColor
                            : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: canAfford ? AppColors.darks : Colors.grey[400],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppColors.purpleLight
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🪙 ${item.cost}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canAfford
                              ? AppColors.primaryColor
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  SECTION TITLE
// ══════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.darks,
    ),
  );
}
