import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

class SoundLibaryChipWidget extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const SoundLibaryChipWidget({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            // Active: brand color in both modes.
            // Inactive: card surface — white in light mode, dark panel in dark.
            color: active ? AppColors.primaryColor : c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.primaryColor : c.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // White on the brand color always reads fine; inactive text
              // uses the theme's secondary text color.
              color: active ? AppColors.white : c.textSub,
            ),
          ),
        ),
      ),
    );
  }
}
