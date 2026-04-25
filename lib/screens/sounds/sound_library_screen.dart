import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';
import 'package:soundstatus/widgets/sound_card.dart';

const _categories = ['all', 'funny', 'meme', 'music', 'general', 'viral'];

class SoundLibraryScreen extends ConsumerWidget {
  const SoundLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sounds = ref.watch(soundLibraryProvider);
    final notifier = ref.read(soundLibraryProvider.notifier);

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  active: true,
                  onTap: () => notifier.setFilter(SoundFilter.all),
                ),
                _FilterChip(
                  label: '🔥 Trending',
                  active: false,
                  onTap: () => notifier.setFilter(SoundFilter.trending),
                ),
                _FilterChip(
                  label: 'My Uploads',
                  active: false,
                  onTap: () => notifier.setFilter(SoundFilter.myUploads),
                ),
                ..._categories
                    .skip(1)
                    .map(
                      (cat) => _FilterChip(
                        label: cat[0].toUpperCase() + cat.substring(1),
                        active: false,
                        onTap: () => notifier.setCategory(cat),
                      ),
                    ),
              ],
            ),
          ),

          // Sound list
          Expanded(
            child: sounds.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => SoundCard(sound: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: active ? Theme.of(context).colorScheme.primary : null,
        labelStyle: TextStyle(
          color: active ? Colors.white : null,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🎵', style: TextStyle(fontSize: 52)),
        SizedBox(height: 12),
        Text(
          'No sounds yet',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        SizedBox(height: 6),
        Text('Be the first to upload!', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
