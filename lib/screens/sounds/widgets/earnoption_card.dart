import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

class EarnOptionCard extends StatelessWidget {
  final IconData icon;
  final String label, coins;
  final Color iconColor, iconBg;

  const EarnOptionCard({
    required this.icon,
    required this.label,
    required this.coins,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.darks,
          ),
        ),
      ),
      Text(
        coins,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF633806),
        ),
      ),
    ],
  );
}
