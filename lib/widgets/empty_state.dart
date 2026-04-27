import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundstatus/core/widget/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.purpleLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: AppColors.primaryColor,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No sounds yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darks,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Be the first to upload!',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    ),
  );
}
