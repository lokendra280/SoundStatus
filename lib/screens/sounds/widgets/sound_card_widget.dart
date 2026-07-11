import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ringtone_set_plus/ringtone_set_plus.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
import 'package:soundstatus/screens/sounds/widgets/insufficientCoinSheet.dart';
import 'package:soundstatus/screens/sounds/widgets/weakform_bar.dart';

enum _ToneType { ringtone, notification, alarm }

class SoundCard extends ConsumerWidget {
  final SoundModel sound;
  final VoidCallback onShare;
  const SoundCard({super.key, required this.sound, required this.onShare});

  // Only notification-category sounds can be set as a device tone,
  // and only on Android (iOS doesn't allow it).
  bool get _canSetAsTone =>
      Platform.isAndroid && sound.category.toLowerCase() == 'notification';

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final isDark = context.isDark;

    final playback = ref.watch(playbackPresenterProvider);
    final shareState = ref.watch(sharePresenterProvider);

    // isActive: this card owns the player (playing OR paused midway).
    // isPlaying: actually playing right now.
    final isActive = playback.playingSoundId == sound.id;
    final isPlaying = playback.isPlaying(sound.id);
    final isLoading = playback.isLoading && isActive;
    final isDownloading = shareState.isDownloading(sound.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primaryColor.withOpacity(isDark ? 0.6 : 0.45)
              : c.border,
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Top row ──────────────────────────────────────────────
          Row(
            children: [
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By ${sound.userName ?? 'unknown'}'
                      '${sound.durationSec != null ? ' · ${_formatDuration(Duration(seconds: sound.durationSec!.toInt()))}' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: sound.userName == 'Admin'
                            ? AppColors.primaryColor
                            : c.textSub,
                        fontWeight: sound.userName == 'Admin'
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Play / pause button ──────────────────────────────
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () async {
                        final result = await ref
                            .read(playbackPresenterProvider.notifier)
                            .togglePlay(sound);

                        if (!context.mounted) return;
                        if (result == PlaybackResult.insufficientCoins) {
                          _showInsufficientCoinsSheet(context);
                          return;
                        }
                        if (result == PlaybackResult.noUrl) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Audio file not available'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    // Filled purple while playing, subtle otherwise —
                    // icon is always visible now.
                    color: isPlaying
                        ? AppColors.primaryColor
                        : AppColors.primaryColor.withOpacity(
                            isDark ? 0.18 : 0.1,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? Colors.white
                              : AppColors.primaryColor,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Waveform with seek ───────────────────────────────────
          // Uses isActive (not isPlaying) so a paused track keeps its
          // position instead of snapping back to 0:00.
          WaveformSeekBar(
            isPlaying: isPlaying,
            position: isActive ? playback.position : Duration.zero,
            duration: isActive ? playback.duration : Duration.zero,
            onSeek: (pos) =>
                ref.read(playbackPresenterProvider.notifier).seek(pos),
          ),
          const SizedBox(height: 12),

          // ── Bottom row ───────────────────────────────────────────
          Row(
            children: [
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sound.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.purpleMid
                        : AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.headphones_rounded, size: 12, color: c.textMuted),
              const SizedBox(width: 3),
              Text(
                _formatCount(sound.playCount),
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
              const Spacer(),

              // ── Set-as-tone button (notification category, Android only)
              if (_canSetAsTone) ...[
                GestureDetector(
                  onTap: () => _showSetToneSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(
                        isDark ? 0.18 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 13,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Set tone',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Share button
              GestureDetector(
                onTap: isDownloading ? null : onShare,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isDownloading
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.ios_share_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 4),
                      Text(
                        isDownloading ? 'Preparing...' : 'Share',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Set-as-tone flow ─────────────────────────────────────────────

  void _showSetToneSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Set "${sound.title}" as',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _toneOption(
              sheetContext,
              context,
              icon: Icons.phone_in_talk_rounded,
              label: 'Ringtone',
              type: _ToneType.ringtone,
            ),
            _toneOption(
              sheetContext,
              context,
              icon: Icons.notifications_rounded,
              label: 'Notification sound',
              type: _ToneType.notification,
            ),
            _toneOption(
              sheetContext,
              context,
              icon: Icons.alarm_rounded,
              label: 'Alarm sound',
              type: _ToneType.alarm,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _toneOption(
    BuildContext sheetContext,
    BuildContext cardContext, {
    required IconData icon,
    required String label,
    required _ToneType type,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: cardContext.textPrimary),
      ),
      onTap: () {
        Navigator.of(sheetContext).pop();
        _applyTone(cardContext, type);
      },
    );
  }

  Future<void> _applyTone(BuildContext context, _ToneType type) async {
    // TODO: adjust to your SoundModel's audio URL field name.
    final url = sound.fileUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Blocking progress dialog while the file downloads & applies.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );

    bool success = false;
    String? error;
    try {
      switch (type) {
        case _ToneType.ringtone:
          success = await RingtoneSet.setRingtoneFromNetwork(url);
          break;
        case _ToneType.notification:
          success = await RingtoneSet.setNotificationFromNetwork(url);
          break;
        case _ToneType.alarm:
          success = await RingtoneSet.setAlarmFromNetwork(url);
          break;
      }
    } catch (e) {
      error = e.toString();
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${sound.title}" set as ${type == _ToneType.ringtone
                    ? 'ringtone'
                    : type == _ToneType.notification
                    ? 'notification sound'
                    : 'alarm'}'
              : error != null
              ? 'Could not set tone: $error'
              : 'Could not set tone. Please allow "Modify system settings" and try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void _showInsufficientCoinsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const InsufficientCoinsSheet(),
  );
}
