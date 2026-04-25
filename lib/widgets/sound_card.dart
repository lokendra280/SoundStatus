import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';

class SoundCard extends ConsumerStatefulWidget {
  final SoundModel sound;
  const SoundCard({super.key, required this.sound});

  @override
  ConsumerState<SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends ConsumerState<SoundCard> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      await _player.setUrl(widget.sound.fileUrl);
      await _player.play();
      setState(() => _playing = true);
      ref
          .read(soundLibraryProvider.notifier)
          .incrementPlayCount(widget.sound.id);
      _player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          setState(() => _playing = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _playing
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: _playing
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.isTrending)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('🔥', style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniChip(s.category),
                    const SizedBox(width: 6),
                    Text(
                      '${s.useCount} uses',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (s.durationSec != null) ...[
                      const Text(' · ', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${s.durationSec!.toStringAsFixed(0)}s',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (s.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.tags.take(3).map((t) => '#$t').join(' '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
