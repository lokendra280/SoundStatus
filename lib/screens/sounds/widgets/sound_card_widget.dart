import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
import 'package:soundstatus/screens/sounds/widgets/weakform_bar.dart';

class SoundCard extends ConsumerWidget {
  final SoundModel sound;
  final VoidCallback onShare;
  const SoundCard({super.key, required this.sound, required this.onShare});

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackPresenterProvider);
    final shareState = ref.watch(sharePresenterProvider);
    final isPlaying = playback.isPlaying(sound.id);
    final isLoading = playback.isLoading && playback.playingSoundId == sound.id;
    final isDownloading = shareState.isDownloading(sound.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? AppColors.purpleMid : AppColors.white,
        ),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              // Avatar
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darks,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By${sound.userName ?? 'unknown'} · Dur${sound.durationSec != null ? '${sound.durationSec}s' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: sound.userName == "Admin"
                            ? Colors.blue
                            : AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: isLoading
                    ? null
                    : () async {
                        final result = await ref
                            .read(playbackPresenterProvider.notifier)
                            .togglePlay(sound);

                        if (!context.mounted) return;
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
                    color: isPlaying ? AppColors.primaryColor : AppColors.white,
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
                              ? AppColors.white
                              : AppColors.primaryColor,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waveform with seek
          WaveformSeekBar(
            isPlaying: isPlaying,
            position: isPlaying ? playback.position : Duration.zero,
            duration: isPlaying ? playback.duration : Duration.zero,
            onSeek: (pos) =>
                ref.read(playbackPresenterProvider.notifier).seek(pos),
          ),
          const SizedBox(height: 12),

          // Bottom row
          Row(
            children: [
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sound.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.headphones_rounded,
                size: 12,
                color: AppColors.darkGrey,
              ),
              const SizedBox(width: 3),
              Text(
                _formatCount(sound.playCount),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
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
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.ios_share_rounded,
                              size: 13,
                              color: AppColors.white,
                            ),
                      const SizedBox(width: 4),
                      Text(
                        isDownloading ? 'Preparing...' : 'Share',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
}
