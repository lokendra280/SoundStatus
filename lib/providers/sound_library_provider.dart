import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/sound_model.dart';

enum SoundFilter { all, trending, myUploads }

// ══════════════════════════════════════════════════════
//  BASE DATA (network + cache)
// ══════════════════════════════════════════════════════
// Fetches ALL approved sounds ONCE and keeps them cached for 5 minutes.
// Every filter/category/search operation works on this in-memory list,
// so chip taps and typing never hit the network.
final _allSoundsProvider = FutureProvider.autoDispose<List<SoundModel>>((
  ref,
) async {
  const selectQuery = '''
    id,
    title,
    duration_sec,
    uploaded_by,
    category,
    is_trending,
    use_count,
    created_at,
    file_url,
    play_count,
    tags,
    profiles!sounds_uploaded_by_fkey (
      id,
      name,
      avatar_url
    )
  ''';

  final res = await supabase
      .from('sounds')
      .select(selectQuery)
      .eq('status', 'approved')
      .order('created_at'); // descending (newest first) by default

  final sounds = res.map((e) => SoundModel.fromJson(e)).toList();

  // keepAlive AFTER the await succeeds — successful results are cached,
  // but a failed fetch is NOT, so retry always re-hits the network.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  return sounds;
});

// ══════════════════════════════════════════════════════
//  FILTERED VIEW (pure in-memory, instant)
// ══════════════════════════════════════════════════════
class SoundLibraryNotifier extends AutoDisposeAsyncNotifier<List<SoundModel>> {
  SoundFilter _filter = SoundFilter.all;
  String _category = 'all';
  String _query = '';

  @override
  Future<List<SoundModel>> build() async {
    // watch = auto-rebuild when the cache refreshes/expires.
    final all = await ref.watch(_allSoundsProvider.future);
    return _applyFilters(all);
  }

  List<SoundModel> _applyFilters(List<SoundModel> all) {
    Iterable<SoundModel> result = all;

    switch (_filter) {
      case SoundFilter.trending:
        result = result.where((s) => s.isTrending == true);
      case SoundFilter.myUploads:
        result = currentUserId == null
            ? const Iterable<SoundModel>.empty()
            : result.where((s) => s.uploadedBy == currentUserId);
      case SoundFilter.all:
        break;
    }

    if (_category != 'all') {
      result = result.where(
        (s) => s.category?.toLowerCase().trim() == _category,
      );
    }

    final search = _query.trim().toLowerCase();
    if (search.isNotEmpty) {
      result = result.where((s) => s.title.toLowerCase().contains(search));
    }

    final list = result.toList();

    switch (_filter) {
      case SoundFilter.trending:
        // Trending = most USED first.
        list.sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
      case SoundFilter.myUploads:
        // Own uploads stay newest-first (base list order) — no re-sort.
        break;
      case SoundFilter.all:
        // All & category views = most PLAYED first; ties broken by newest.
        list.sort((a, b) {
          final byPlays = (b.playCount ?? 0).compareTo(a.playCount ?? 0);
          if (byPlays != 0) return byPlays;
          return b.createdAt.compareTo(a.createdAt);
        });
    }

    return list;
  }

  /// Re-filter the cached list synchronously — no loading spinner, no
  /// network. Falls back to a rebuild if the cache isn't ready yet.
  void _refilter() {
    final all = ref.read(_allSoundsProvider).valueOrNull;
    if (all != null) {
      state = AsyncData(_applyFilters(all));
    } else {
      ref.invalidateSelf();
    }
  }

  void setFilter(SoundFilter f) {
    _filter = f;
    _category = 'all'; // chips are mutually exclusive in the UI
    _refilter();
  }

  void setCategory(String cat) {
    _category = cat;
    _filter = SoundFilter.all; // chips are mutually exclusive in the UI
    _refilter();
  }

  /// Instant, client-side search — no debounce needed because filtering an
  /// in-memory list is effectively free.
  void setQuery(String q) {
    _query = q;
    _refilter();
  }

  /// Force a fresh fetch from the server (pull-to-refresh / retry / after
  /// uploading a new sound). Invalidating the base provider automatically
  /// rebuilds this notifier because build() watches it.
  Future<void> refresh() {
    ref.invalidate(_allSoundsProvider);
    return future;
  }

  Future<void> incrementPlayCount(String soundId) async {
    await supabase.rpc('increment_play_count', params: {'sound_id': soundId});
  }
}

final soundLibraryProvider =
    AsyncNotifierProvider.autoDispose<SoundLibraryNotifier, List<SoundModel>>(
      SoundLibraryNotifier.new,
    );
