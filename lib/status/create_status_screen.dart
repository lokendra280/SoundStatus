import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';
import 'package:soundstatus/providers/status_provider.dart';
import 'package:soundstatus/widgets/ad_reward_button.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  String _text = '';
  SoundModel? _selectedSound;
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _createStatus() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;

    if (!profile.canShareFree) {
      _showShareLimitDialog();
      return;
    }

    final status = await ref
        .read(statusProvider.notifier)
        .createStatus(
          text: _text.isEmpty ? null : _text,
          soundId: _selectedSound?.id,
        );

    if (!mounted) return;

    if (status != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Status created!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showShareLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daily limit reached'),
        content: const Text(
          'You\'ve used your 5 free shares for today.\n'
          'Watch an ad to earn coins and unlock more shares.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AdRewardButton(
            onRewarded: () {
              Navigator.pop(context);
              // Refresh profile to check if share limit has been unlocked
              ref.read(profileProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _previewSound(SoundModel sound) async {
    await _player.setUrl(sound.fileUrl);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final sounds = ref.watch(soundLibraryProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${5 - (profile?.shareCountToday ?? 0)} shares left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
                labelText: 'Status text',
              ),
              onChanged: (v) => setState(() => _text = v),
            ),

            const SizedBox(height: 20),

            const Text(
              'Attach a Sound',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            // Sound picker
            if (sounds.isEmpty)
              const Text(
                'No sounds available yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final s = sounds[i];
                    final isSelected = _selectedSound?.id == s.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSound = isSelected ? null : s);
                        if (!isSelected) _previewSound(s);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 130,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note_rounded, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              s.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              s.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Selected sound preview
            if (_selectedSound != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedSound!.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _selectedSound = null),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _createStatus,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Post Status'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
