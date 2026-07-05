import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundstatus/models/sound_model.dart';
import 'package:soundstatus/models/wallet_transaction_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/sound_library_provider.dart';
import 'package:soundstatus/providers/wallet_provider.dart';

const kShareCoinCost = 3;
const kPlayCoinCost = 1;

// ══════════════════════════════════════════════════════
//  PLAYBACK STATE
// ══════════════════════════════════════════════════════
class PlaybackState {
  final String? playingSoundId;
  final bool isLoading;
  final Duration position;
  final Duration duration;

  const PlaybackState({
    this.playingSoundId,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  bool isPlaying(String id) => playingSoundId == id;
  bool get hasAnySoundPlaying => playingSoundId != null;

  PlaybackState copyWith({
    String? playingSoundId,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool clearPlaying = false,
  }) => PlaybackState(
    playingSoundId: clearPlaying
        ? null
        : (playingSoundId ?? this.playingSoundId),
    isLoading: isLoading ?? this.isLoading,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}

// ── Playback result ───────────────────────────────────
enum PlaybackResult { started, stopped, failed, noUrl, insufficientCoins }

// ══════════════════════════════════════════════════════
//  SHARE STATE
// ══════════════════════════════════════════════════════
enum ShareStatus { idle, checkingCoins, downloading, done, error }

enum ShareError { insufficientCoins, downloadFailed, unknown }

class ShareState {
  final ShareStatus status;
  final String? soundId;
  final ShareError? error;
  final int availableCoins;

  const ShareState({
    this.status = ShareStatus.idle,
    this.soundId,
    this.error,
    this.availableCoins = 0,
  });

  bool isDownloading(String id) =>
      (status == ShareStatus.downloading ||
          status == ShareStatus.checkingCoins) &&
      soundId == id;

  bool get hasError => error != null;
}

// ── Share result ──────────────────────────────────────
// `dismissed` = user backed out of the share sheet. NO coins charged.
enum ShareResult { success, dismissed, insufficientCoins, error }

// ══════════════════════════════════════════════════════
//  PLAYBACK PRESENTER
// ══════════════════════════════════════════════════════
final playbackPresenterProvider =
    NotifierProvider<PlaybackPresenter, PlaybackState>(PlaybackPresenter.new);

class PlaybackPresenter extends Notifier<PlaybackState> {
  final _player = AudioPlayer();

  @override
  PlaybackState build() {
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });

    _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        state = state.copyWith(clearPlaying: true);
        _player.stop();
      }
    });

    ref.onDispose(_player.dispose);
    return const PlaybackState();
  }

  // ── Called from UI — returns result enum only ─────────
  Future<PlaybackResult> togglePlay(SoundModel sound) async {
    // Stop if already playing this sound
    if (state.isPlaying(sound.id)) {
      await _player.stop();
      state = state.copyWith(clearPlaying: true);
      return PlaybackResult.stopped;
    }

    // Guard: no file url
    final fileUrl = sound.fileUrl;
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      debugPrint('togglePlay: no fileUrl for sound ${sound.id}');
      return PlaybackResult.noUrl;
    }
    final coins = ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;
    if (coins < kPlayCoinCost) {
      debugPrint('togglePlay: insufficient coins ($coins)');
      return PlaybackResult.insufficientCoins;
    }
    // Stop any other sound first
    if (state.hasAnySoundPlaying) await _player.stop();

    // Set loading state
    state = state.copyWith(
      playingSoundId: sound.id,
      isLoading: true,
      position: Duration.zero,
    );

    try {
      await _player.setUrl(fileUrl);
      await _player.play();

      // Playback confirmed started — NOW charge, count the play, both
      // fire-and-forget so they can never interrupt audio.
      _deductPlayCoin(sound); // FIX: was passing sound.id as the "title"
      _incrementPlayCount(sound.id); // FIX: was never called at all

      state = state.copyWith(isLoading: false);
      return PlaybackResult.started;
    } catch (e) {
      debugPrint('togglePlay error: $e');
      state = state.copyWith(clearPlaying: true, isLoading: false);
      return PlaybackResult.failed;
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  void stop() {
    _player.stop();
    state = state.copyWith(clearPlaying: true);
  }

  Future<void> _deductPlayCoin(SoundModel sound) async {
    try {
      await ref
          .read(walletProvider.notifier)
          .spend(
            amount: kPlayCoinCost,
            source: TxSource.spendUnlock,
            note: 'Played: ${sound.title}',
          );
      await ref.read(profileProvider.notifier).refresh();
      debugPrint('_deductPlayCoin: success');
    } catch (e) {
      // Silent — coin failure must never break playback
      debugPrint('_deductPlayCoin error: $e');
    }
  }

  Future<void> _incrementPlayCount(String soundId) async {
    try {
      await ref.read(soundLibraryProvider.notifier).incrementPlayCount(soundId);
      debugPrint('_incrementPlayCount: success for $soundId');
    } catch (e) {
      // Silent — play count failure must never break playback
      debugPrint('_incrementPlayCount error: $e');
    }
  }
}

// ══════════════════════════════════════════════════════
//  SHARE PRESENTER
// ══════════════════════════════════════════════════════
final sharePresenterProvider = NotifierProvider<SharePresenter, ShareState>(
  SharePresenter.new,
);

class SharePresenter extends Notifier<ShareState> {
  @override
  ShareState build() {
    final coins = ref.watch(profileProvider).valueOrNull?.coinBalance ?? 0;
    return ShareState(availableCoins: coins);
  }

  // ── Called from UI ────────────────────────────────────
  Future<ShareResult> shareAsMp3(SoundModel sound) =>
      _share(sound, scheme: null);

  // NOTE: share_plus cannot target one specific app — the system share
  // sheet decides. So `scheme` currently only affects the share text.
  // To genuinely open WhatsApp directly you'd need android_intent_plus
  // with a package name (e.g. com.whatsapp) on Android. Until then the
  // per-app buttons and "More" behave the same, which is honest-but-meh UX.
  Future<ShareResult> shareToApp(SoundModel sound, String scheme) =>
      _share(sound, scheme: scheme);

  void reset() {
    final coins = ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;
    state = ShareState(availableCoins: coins);
  }

  // ── Private: full share flow ──────────────────────────
  //
  //  FIXED ORDER — charge at the END, only on confirmed success:
  //    1. guard url          (free)
  //    2. check balance      (free)
  //    3. download mp3       (free — failure costs nothing, no refund dance)
  //    4. open share sheet   (free)
  //    5. user completed it? → charge. Dismissed? → free.
  //
  //  The old order deducted at step 2, so backing out of the share
  //  sheet still cost 3 coins, and download failures needed refunds.
  Future<ShareResult> _share(
    SoundModel sound, {
    required String? scheme,
  }) async {
    // ── Step 1 — Guard file url ──────────────────────────
    final fileUrl = sound.fileUrl;
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      debugPrint('_share: fileUrl is null or empty for ${sound.id}');
      state = ShareState(
        status: ShareStatus.error,
        soundId: sound.id,
        error: ShareError.unknown,
        availableCoins: state.availableCoins,
      );
      return ShareResult.error;
    }

    // ── Step 2 — Check coin balance (pre-check only) ─────
    state = ShareState(
      status: ShareStatus.checkingCoins,
      soundId: sound.id,
      availableCoins: state.availableCoins,
    );

    final currentCoins = _currentCoins;
    if (currentCoins < kShareCoinCost) {
      debugPrint('_share: insufficient coins ($currentCoins)');
      state = ShareState(
        status: ShareStatus.error,
        soundId: sound.id,
        error: ShareError.insufficientCoins,
        availableCoins: currentCoins,
      );
      return ShareResult.insufficientCoins;
    }

    // ── Step 3 — Download MP3 (nothing charged yet) ──────
    state = ShareState(
      status: ShareStatus.downloading,
      soundId: sound.id,
      availableCoins: currentCoins,
    );

    try {
      final file = await _downloadMp3(sound, fileUrl);
      debugPrint('_share: downloaded to ${file.path}');

      // ── Step 4 — Open the share sheet & wait for outcome ─
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'audio/mpeg')],
        subject: sound.title,
        text: '🎵 ${sound.title} — shared via StatusHub',
      );

      // ── Step 5 — Charge ONLY on a completed share ────────
      switch (result.status) {
        case ShareResultStatus.dismissed:
          // User backed out — free, and no refund needed because
          // nothing was ever taken.
          debugPrint('_share: dismissed by user, no charge');
          state = ShareState(
            status: ShareStatus.idle,
            availableCoins: currentCoins,
          );
          return ShareResult.dismissed;

        case ShareResultStatus.success:
        case ShareResultStatus.unavailable:
          // success = user picked a target app.
          // unavailable = this platform can't report an outcome; the file
          // WAS handed to the system sheet, so we treat it as shared.
          // (Change `unavailable` to the dismissed branch above if you'd
          // rather those devices share free.)
          final charged = await _deductCoins(sound.title);
          state = ShareState(
            status: ShareStatus.done,
            availableCoins: charged
                ? currentCoins - kShareCoinCost
                : currentCoins,
          );
          debugPrint('_share: done, charged=$charged');
          // If charging failed AFTER a real share, the user gets a free
          // share — the correct failure direction. Never the reverse.
          return ShareResult.success;
      }
    } catch (e, st) {
      debugPrint('_share: download/share error: $e');
      debugPrint('$st');

      // Nothing was charged before this point, so there is nothing to
      // refund — the old _refundCoins step is gone by design.
      state = ShareState(
        status: ShareStatus.error,
        soundId: sound.id,
        error: ShareError.downloadFailed,
        availableCoins: currentCoins,
      );
      return ShareResult.error;
    }
  }

  Future<bool> _deductCoins(String soundTitle) async {
    try {
      await ref
          .read(walletProvider.notifier)
          .spend(
            amount: kShareCoinCost,
            source: TxSource.shareSound,
            note: 'Shared: $soundTitle',
          );
      await ref.read(profileProvider.notifier).refresh();
      debugPrint('_deductCoins: success');
      return true;
    } catch (e) {
      debugPrint('_deductCoins error: $e');
      return false;
    }
  }

  // ── Private helpers ───────────────────────────────────
  int get _currentCoins =>
      ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;

  Future<File> _downloadMp3(SoundModel sound, String fileUrl) async {
    // Validate URI before making request
    final uri = Uri.tryParse(fileUrl);
    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid file URL: $fileUrl');
    }

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Download timed out after 30s'),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Download failed with status ${response.statusCode} for $fileUrl',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('Downloaded file is empty for $fileUrl');
    }

    final dir = await getTemporaryDirectory();

    // Use sound id in filename to avoid collisions between sounds
    final safeName = sound.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/${safeName}_${sound.id}.mp3');

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
