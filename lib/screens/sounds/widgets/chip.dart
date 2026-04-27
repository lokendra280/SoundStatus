import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryColor : const Color(0xFFEFEFEF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.white : Colors.grey[600],
          ),
        ),
      ),
    ),
  );
}
