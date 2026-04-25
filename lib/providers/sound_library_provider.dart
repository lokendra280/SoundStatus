import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/sound_model.dart';

enum SoundFilter { all, trending, myUploads }

class SoundLibraryNotifier extends AutoDisposeAsyncNotifier<List<SoundModel>> {
  SoundFilter _filter = SoundFilter.all;
  String _category = 'all';

  @override
  Future<List<SoundModel>> build() => _fetchSounds();

  Future<List<SoundModel>> _fetchSounds() async {
    var query = supabase
        .from('sounds')
        .select()
        .eq('status', 'approved')
        .order('created_at', ascending: false);

    if (_filter == SoundFilter.trending) {
      query = supabase
          .from('sounds')
          .select()
          .eq('status', 'approved')
          .eq('is_trending', true)
          .order('use_count', ascending: false);
    }

    if (_filter == SoundFilter.myUploads && currentUserId != null) {
      query = supabase
          .from('sounds')
          .select()
          .eq('uploaded_by', currentUserId!)
          .order('created_at', ascending: false);
    }

    if (_category != 'all') {
      query = (query as dynamic).eq('category', _category);
    }

    final res = await query;
    return (res as List).map((e) => SoundModel.fromJson(e)).toList();
  }

  void setFilter(SoundFilter f) {
    _filter = f;
    ref.invalidateSelf();
  }

  void setCategory(String cat) {
    _category = cat;
    ref.invalidateSelf();
  }

  Future<void> incrementPlayCount(String soundId) async {
    await supabase.rpc('increment_play_count', params: {'sound_id': soundId});
  }
}

final soundLibraryProvider =
    AsyncNotifierProvider.autoDispose<SoundLibraryNotifier, List<SoundModel>>(
      SoundLibraryNotifier.new,
    );
