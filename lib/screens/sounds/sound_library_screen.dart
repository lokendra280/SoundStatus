import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';
import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
import 'package:soundstatus/screens/sounds/widgets/chip.dart';
import 'package:soundstatus/widgets/empty_state.dart';

// const _purple = Color(0xFF534AB7);
const _purpleMid = Color(0xFFAFA9EC);
// const _dark = Color(0xFF1A1A1A);
const _teal = Color(0xFF0F6E56);
const _tealLight = Color(0xFFE1F5EE);
const _red = Color(0xFFA32D2D);

const _categories = ['all', 'funny', 'meme', 'music', 'general', 'viral'];

// ══════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════
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

  @override
  Widget build(BuildContext context) {
    final sounds = ref.watch(soundLibraryProvider);
    final notifier = ref.read(soundLibraryProvider.notifier);
    // final shareState = ref.watch(sharePresenterProvider);

    // Share error listener
    ref.listen(sharePresenterProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        _snack('Failed to share. Try again.', error: true);
        ref.read(sharePresenterProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                onChanged: (v) => notifier.setCategory(v),
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
                notifier.setCategory('all');
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
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                SoundLibaryChipWidget(
                  label: 'All',
                  active: _activeFilter == 'all',
                  onTap: () {
                    setState(() => _activeFilter = 'all');
                    notifier.setFilter(SoundFilter.all);
                  },
                ),
                SoundLibaryChipWidget(
                  label: '🔥 Trending',
                  active: _activeFilter == 'trending',
                  onTap: () {
                    setState(() => _activeFilter = 'trending');
                    notifier.setFilter(SoundFilter.trending);
                  },
                ),
                SoundLibaryChipWidget(
                  label: 'My Uploads',
                  active: _activeFilter == 'myUploads',
                  onTap: () {
                    setState(() => _activeFilter = 'myUploads');
                    notifier.setFilter(SoundFilter.myUploads);
                  },
                ),
                ..._categories
                    .skip(1)
                    .map(
                      (cat) => SoundLibaryChipWidget(
                        label: cat[0].toUpperCase() + cat.substring(1),
                        active: _activeFilter == cat,
                        onTap: () {
                          setState(() => _activeFilter = cat);
                          notifier.setCategory(cat);
                        },
                      ),
                    ),
              ],
            ),
          ),

          // Sound list
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
                      color: _red,
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
                      itemBuilder: (ctx, i) => _SoundCard(
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

  // ── In _SoundLibraryState ────────────────────────────

  void _showShareSheet(BuildContext context, WidgetRef ref, SoundModel sound) {
    final coins = ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;

    // Show coin warning if balance is low
    if (coins < kShareCoinCost) {
      _showInsufficientCoinsSheet(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareBottomSheet(
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
      builder: (_) => const _InsufficientCoinsSheet(),
    );
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? _red : _teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
}

// ══════════════════════════════════════════════════════
//  SOUND CARD
// ══════════════════════════════════════════════════════
class _SoundCard extends ConsumerWidget {
  final SoundModel sound;
  final VoidCallback onShare;
  const _SoundCard({required this.sound, required this.onShare});

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? _purpleMid : const Color(0xFFEFEFEF),
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
                            : Colors.grey[500],
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
                    color: isPlaying
                        ? AppColors.primaryColor
                        : const Color(0xFFEEEDFE),
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

          // Waveform with seek
          _WaveformSeekBar(
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
              Icon(Icons.headphones_rounded, size: 12, color: Colors.grey[400]),
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
}

// ══════════════════════════════════════════════════════
//  WAVEFORM SEEK BAR
// ══════════════════════════════════════════════════════
class _WaveformSeekBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position, duration;
  final ValueChanged<Duration> onSeek;

  const _WaveformSeekBar({
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
                        ? _purpleMid
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
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
              ),
              Text(
                _fmt(duration),
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARE BOTTOM SHEET — shares MP3 file, not link
// ══════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════
//  SHARE BOTTOM SHEET — shows coin cost
// ══════════════════════════════════════════════════════
class _ShareBottomSheet extends StatelessWidget {
  final SoundModel sound;
  final int coinCost;
  final int availableCoins;
  final VoidCallback onShareMp3;
  final ValueChanged<String> onShareToApp;
  final VoidCallback onCopyLink;

  const _ShareBottomSheet({
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
              color: Colors.grey[200],
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
            _StatusBtn(
              label: 'WhatsApp',
              sublabel: 'Send as audio',
              color: const Color(0xFF25D366),
              onTap: () => onShareToApp('whatsapp'),
            ),
            const SizedBox(width: 8),
            _StatusBtn(
              label: 'Telegram',
              sublabel: 'Send as audio',
              color: const Color(0xFF2AABEE),
              onTap: () => onShareToApp('telegram'),
            ),
            const SizedBox(width: 8),
            _StatusBtn(
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
                (app) => _AppIcon(
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
                      color: Colors.white,
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
              border: Border.all(color: _purpleMid),
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

// ══════════════════════════════════════════════════════
//  INSUFFICIENT COINS SHEET
// ══════════════════════════════════════════════════════
class _InsufficientCoinsSheet extends StatelessWidget {
  const _InsufficientCoinsSheet();

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
              _EarnOption(
                icon: Icons.play_circle_outline_rounded,
                label: 'Watch a rewarded ad',
                coins: '+10 coins',
                iconColor: const Color(0xFF185FA5),
                iconBg: const Color(0xFFE6F1FB),
              ),
              const SizedBox(height: 8),
              _EarnOption(
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
            // ref.read(bottomNavIndexProvider.notifier).state = 3;
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

// ── Earn option row inside insufficient sheet ─────────
class _EarnOption extends StatelessWidget {
  final IconData icon;
  final String label, coins;
  final Color iconColor, iconBg;

  const _EarnOption({
    required this.icon,
    required this.label,
    required this.coins,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.darks,
          ),
        ),
      ),
      Text(
        coins,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF633806),
        ),
      ),
    ],
  );
}

// ── Status Button ─────────────────────────────────────
class _StatusBtn extends StatelessWidget {
  final String label, sublabel;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── App Icon ──────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  const _AppIcon({
    required this.label,
    required this.icon,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    ),
  );
}

// ── Filter Chip ───────────────────────────────────────
