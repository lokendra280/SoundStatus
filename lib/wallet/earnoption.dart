import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

class EarnOption extends StatelessWidget {
  final String emoji, title, subtitle, reward;
  final bool enabled;
  final VoidCallback onTap;
  const EarnOption({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled ? c.card : c.cardElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(
                  context.isDark ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 17)),
              ),
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
                      color: enabled ? context.textPrimary : c.textMuted,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: c.textSub),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: enabled ? AppColors.tealLight : c.cardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reward,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enabled ? AppColors.teal : c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
