import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/providers/ad_reward_provider.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

enum AdButtonStyle { filled, outlined }

class AdRewardButton extends ConsumerWidget {
  final VoidCallback? onRewarded;
  final AdButtonStyle style;
  const AdRewardButton({
    super.key,
    this.onRewarded,
    this.style = AdButtonStyle.filled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(adRewardProvider);

    Future<void> onTap() async {
      if (!isReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready yet, please try again.')),
        );
        ref.read(adRewardProvider.notifier).reload();
        return;
      }

      final canWatch = await ref.read(adRewardProvider.notifier).canWatchAd();
      if (!canWatch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Daily ad limit reached (10/day). Come back tomorrow!',
              ),
            ),
          );
        }
        return;
      }

      await ref.read(adRewardProvider.notifier).showAd();
      onRewarded?.call();
    }

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        CommonSvgWidget(svgName: Assets.tv, height: 30, width: 30),
        SizedBox(width: 6),
        Text('Watch Ad · Earn 10 coins'),
      ],
    );

    return style == AdButtonStyle.filled
        ? FilledButton(onPressed: onTap, child: label)
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              foregroundColor: Colors.white,
            ),
            child: label,
          );
  }
}
