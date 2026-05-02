import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

class WaveformSeekBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position, duration;
  final ValueChanged<Duration> onSeek;

  const WaveformSeekBar({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  static const _heights = [
    4.0,
    10.0,
    7.0,
    14.0,
    5.0,
    12.0,
    8.0,
    16.0,
    6.0,
    11.0,
    4.0,
    14.0,
    9.0,
    13.0,
    5.0,
    16.0,
    7.0,
    10.0,
    4.0,
    12.0,
    8.0,
    14.0,
    6.0,
    11.0,
    4.0,
    9.0,
    13.0,
    7.0,
    15.0,
    5.0,
  ];

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final playedBars = (progress * _heights.length).round();

    return Column(
      children: [
        GestureDetector(
          onTapDown: (details) {
            if (!isPlaying || duration == Duration.zero) return;
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = details.localPosition.dx;
            final totalWidth = box.size.width;
            final ratio = (localX / totalWidth).clamp(0.0, 1.0);
            onSeek(duration * ratio);
          },
          child: SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                _heights.length,
                (i) => Container(
                  width: 3,
                  height: _heights[i],
                  decoration: BoxDecoration(
                    color: i < playedBars
                        ? AppColors.primaryColor
                        : isPlaying
                        ? AppColors.purpleMid
                        : const Color(0xFFCECBF6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isPlaying && duration != Duration.zero) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(position),
                style: TextStyle(fontSize: 9, color: AppColors.darkGrey),
              ),
              Text(
                _fmt(duration),
                style: TextStyle(fontSize: 9, color: AppColors.darkGrey),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
