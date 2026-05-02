import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
import 'package:soundstatus/screens/sounds/widgets/earnoption_card.dart';

class InsufficientCoinsSheet extends ConsumerStatefulWidget {
  const InsufficientCoinsSheet();

  @override
  ConsumerState<InsufficientCoinsSheet> createState() =>
      _InsufficientCoinsSheetState();
}

class _InsufficientCoinsSheetState
    extends ConsumerState<InsufficientCoinsSheet> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
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
        const SizedBox(height: 24),

        // Icon
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Color(0xFFFAEEDA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🪙', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Not enough coins',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darks,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sharing a sound costs $kShareCoinCost coins.\nWatch an ad or upload a sound to earn more.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Earn options
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              EarnOptionCard(
                icon: Icons.play_circle_outline_rounded,
                label: 'Watch a rewarded ad',
                coins: '+10 coins',
                iconColor: const Color(0xFF185FA5),
                iconBg: const Color(0xFFE6F1FB),
              ),
              const SizedBox(height: 8),
              EarnOptionCard(
                icon: Icons.upload_rounded,
                label: 'Upload a sound',
                coins: '+20 coins',
                iconColor: AppColors.primaryColor,
                iconBg: AppColors.purpleLight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Go to wallet button
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            // Navigate to wallet tab — adjust index to match your bottom nav
            //  ref.read(bottomNavIndexProvider.notifier).state = 3;
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Go to Wallet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Maybe later',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
