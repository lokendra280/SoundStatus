import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';
import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
import 'package:soundstatus/screens/sounds/widgets/chip.dart';
import 'package:soundstatus/screens/sounds/widgets/insufficientCoinSheet.dart';
import 'package:soundstatus/screens/sounds/widgets/share_bottom_widget.dart';
import 'package:soundstatus/screens/sounds/widgets/sound_card_widget.dart';
import 'package:soundstatus/widgets/empty_state.dart';

class SoundLibraryScreen extends ConsumerStatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  ConsumerState<SoundLibraryScreen> createState() => _SoundLibraryState();
}

class _SoundLibraryState extends ConsumerState<SoundLibraryScreen> {
  String _activeFilter = 'all';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    ref.read(playbackPresenterProvider.notifier).stop();
    super.dispose();
  }

  void _applyFilter(String filter) {
    setState(() => _activeFilter = filter);
    final notifier = ref.read(soundLibraryProvider.notifier);
    switch (filter) {
      case 'all':
        notifier.setFilter(SoundFilter.all);
      case 'trending':
        notifier.setFilter(SoundFilter.trending);
      case 'myUploads':
        notifier.setFilter(SoundFilter.myUploads);
      default:
        notifier.setCategory(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sounds = ref.watch(soundLibraryProvider);
    final notifier = ref.read(soundLibraryProvider.notifier);

    // Share error listener
    ref.listen(sharePresenterProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        _snack('Failed to share. Try again.', error: true);
        ref.read(sharePresenterProvider.notifier).reset();
      }
    });

    // ── Derive dynamic categories from loaded sound data ───────────────────
    // Extract unique non-null categories, preserve insertion order, put
    // 'all' / 'trending' / 'myUploads' always first.
    final dynamicCategories =
        sounds.whenData((list) {
          final seen = <String>{};
          return list
              .map((s) => s.category?.toLowerCase().trim())
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .where((c) => seen.add(c)) // unique, order-preserving
              .toList();
        }).valueOrNull ??
        const [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search sounds...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                ),
                // FIX 3: search query goes to setQuery, not setCategory
                //   onChanged: (v) => notifier.setFilter(v),
              )
            : const Text(
                'Sound Library',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darks,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.darks,
              size: 22,
            ),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                // FIX: clear the search query AND reset to 'all' filter
                // notifier.setQuery('');
                _applyFilter('all');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFEFEFEF)),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                // Always-present fixed filters
                SoundLibaryChipWidget(
                  label: 'All',
                  active: _activeFilter == 'all',
                  onTap: () => _applyFilter('all'),
                ),
                SoundLibaryChipWidget(
                  label: '🔥 Trending',
                  active: _activeFilter == 'trending',
                  onTap: () => _applyFilter('trending'),
                ),
                SoundLibaryChipWidget(
                  label: 'My Uploads',
                  active: _activeFilter == 'myUploads',
                  onTap: () => _applyFilter('myUploads'),
                ),

                // FIX 1 & 2: Dynamic category chips from loaded sound data
                ...dynamicCategories.map(
                  (cat) => SoundLibaryChipWidget(
                    label: cat[0].toUpperCase() + cat.substring(1),
                    active: _activeFilter == cat,
                    onTap: () => _applyFilter(cat),
                  ),
                ),
              ],
            ),
          ),

          // ── Sound list ────────────────────────────────────────────────────
          Expanded(
            child: sounds.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load sounds',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => ref.invalidate(soundLibraryProvider),
                      child: const Text(
                        'Tap to retry',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  ? const EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => SoundCard(
                        sound: list[i],
                        onShare: () => _showShareSheet(context, ref, list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Share sheet (unchanged) ────────────────────────────────────────────────

  void _showShareSheet(BuildContext context, WidgetRef ref, SoundModel sound) {
    final coins = ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;
    if (coins < kShareCoinCost) {
      _showInsufficientCoinsSheet(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareBottomSheetWidget(
        sound: sound,
        coinCost: kShareCoinCost,
        availableCoins: coins,
        onShareMp3: () async {
          Navigator.pop(context);
          final result = await ref
              .read(sharePresenterProvider.notifier)
              .shareAsMp3(sound);
          if (!context.mounted) return;
          _handleShareResult(context, result);
        },
        onShareToApp: (scheme) async {
          Navigator.pop(context);
          final result = await ref
              .read(sharePresenterProvider.notifier)
              .shareToApp(sound, scheme);
          if (!context.mounted) return;
          _handleShareResult(context, result);
        },
        onCopyLink: () {
          Clipboard.setData(
            ClipboardData(text: 'https://statushub.app/s/${sound.id}'),
          );
          Navigator.pop(context);
          _snack('Link copied! (free)');
        },
      ),
    );
  }

  void _handleShareResult(BuildContext context, ShareResult result) {
    switch (result) {
      case ShareResult.success:
        _snack('-$kShareCoinCost coins · Sound shared!');
      case ShareResult.insufficientCoins:
        _showInsufficientCoinsSheet(context);
      case ShareResult.error:
        _snack('Share failed. Coins refunded.', error: true);
    }
  }

  void _showInsufficientCoinsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const InsufficientCoinsSheet(),
    );
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? AppColors.red : AppColors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
}
