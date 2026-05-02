import 'package:flutter/material.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

class BalanceCard extends StatelessWidget {
  final int coins;
  final VoidCallback onEarn, onSpend;
  const BalanceCard({
    super.key,
    required this.coins,
    required this.onEarn,
    required this.onSpend,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total balance',
          style: TextStyle(fontSize: 12, color: Color(0xAAFFFFFF)),
        ),
        const SizedBox(height: 6),
        Row(
          // crossAxisAlignment: CrossAxisAlignment.baseline,
          // textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            CommonSvgWidget(
              svgName: Assets.bank,
              height: 30,
              width: 30,
              color: AppColors.yellow,
            ),
            const SizedBox(width: 8),
            Text(
              '$coins',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'coins',
              style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
            ),
          ],
        ),

        const SizedBox(height: 3),
        Text(
          '≈ \$${(coins / 1000).toStringAsFixed(2)} equivalent',
          style: const TextStyle(fontSize: 11, color: AppColors.primaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSpend,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withOpacity(0.2)),
                  ),
                  child: const Center(
                    child: Text(
                      'Spend coins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onEarn,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      '+ Earn more',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
