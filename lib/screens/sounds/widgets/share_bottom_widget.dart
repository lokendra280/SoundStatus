import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/screens/sounds/widgets/bottomsheet_button.dart';
import 'package:soundstatus/widgets/app_icon.dart';

class ShareBottomSheetWidget extends StatelessWidget {
  final SoundModel sound;
  final int coinCost;
  final int availableCoins;
  final VoidCallback onShareMp3;
  final ValueChanged<String> onShareToApp;
  final VoidCallback onCopyLink;

  const ShareBottomSheetWidget({
    required this.sound,
    required this.coinCost,
    required this.availableCoins,
    required this.onShareMp3,
    required this.onShareToApp,
    required this.onCopyLink,
  });

  static const _socialApps = [
    (
      label: 'Telegram',
      icon: Icons.send_rounded,
      bg: Color(0xFF2AABEE),
      scheme: 'telegram',
    ),
    (
      label: 'Instagram',
      icon: Icons.camera_alt_rounded,
      bg: Color(0xFFC13584),
      scheme: 'instagram',
    ),
    (
      label: 'Facebook',
      icon: Icons.facebook_rounded,
      bg: Color(0xFF1877F2),
      scheme: 'facebook',
    ),
    (
      label: 'Twitter',
      icon: Icons.alternate_email_rounded,
      bg: Color(0xFF1DA1F2),
      scheme: 'twitter',
    ),
    (
      label: 'TikTok',
      icon: Icons.music_video_rounded,
      bg: Color(0xFF010101),
      scheme: 'tiktok',
    ),
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
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Sound preview + coin cost row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    (sound.uploadedBy ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darks,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${sound.uploadedBy ?? 'unknown'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coin cost badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF9F27)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '-$coinCost',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF633806),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Balance info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 5),
              Text(
                'Sharing costs $coinCost coins · You have $availableCoins coins',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Share to top apps
        const Text(
          'Share MP3 to',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darks,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatusBtn(
              label: 'WhatsApp',
              sublabel: 'Send as audio',
              color: const Color(0xFF25D366),
              onTap: () => onShareToApp('whatsapp'),
            ),
            const SizedBox(width: 8),
            StatusBtn(
              label: 'Telegram',
              sublabel: 'Send as audio',
              color: const Color(0xFF2AABEE),
              onTap: () => onShareToApp('telegram'),
            ),
            const SizedBox(width: 8),
            StatusBtn(
              label: 'More',
              sublabel: 'Any app',
              color: AppColors.primaryColor,
              onTap: onShareMp3,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // All apps grid
        const Text(
          'All apps',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darks,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _socialApps
              .map(
                (app) => AppIcon(
                  label: app.label,
                  icon: app.icon,
                  bg: app.bg,
                  onTap: () => onShareToApp(app.scheme),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),

        // Copy link — FREE
        Row(
          children: [
            const Text(
              'Copy link',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darks,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Free',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF085041),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'statushub.app/s/${sound.id}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCopyLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Share MP3 button
        GestureDetector(
          onTap: onShareMp3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.purpleMid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.audio_file_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Share MP3 file',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🪙 -3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF633806),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
