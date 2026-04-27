import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgrest/src/postgrest_builder.dart';
import 'package:postgrest/src/types.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/sound_model.dart';

enum SoundFilter { all, trending, myUploads }

class SoundLibraryNotifier extends AutoDisposeAsyncNotifier<List<SoundModel>> {
  SoundFilter _filter = SoundFilter.all;
  String _category = 'all';

  @override
  Future<List<SoundModel>> build() => _fetchSounds();
  Future<List<SoundModel>> _fetchSounds() async {
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

    PostgrestTransformBuilder<PostgrestList> query = supabase
        .from('sounds')
        .select(selectQuery)
        .eq('status', 'approved');

    if (_filter == SoundFilter.trending) {
      query = supabase
          .from('sounds')
          .select(selectQuery)
          .eq('status', 'approved')
          .eq('is_trending', true)
          .order('use_count');
    }

    if (_filter == SoundFilter.myUploads && currentUserId != null) {
      query = supabase
          .from('sounds')
          .select(selectQuery)
          .eq('status', 'approved')
          .eq('uploaded_by', currentUserId!)
          .order('created_at');
    }

    if (_category != 'all') {
      query = supabase
          .from('sounds')
          .select(selectQuery)
          .eq('status', 'approved')
          .eq('category', _category);
    }

    final res = await query;
    return (res as List).map((e) => SoundModel.fromJson(e)).toList();
  }
  // Future<List<SoundModel>> _fetchSounds() async {
  //   var query = supabase
  //       .from('sounds')
  //       .select('''
  //     id,
  //     title,
  //     duration_sec,
  //     uploaded_by,
  //     profiles!sounds_uploaded_by_fkey (
  //       id,
  //       name,
  //       avatar_url
  //     )
  //   ''')
  //       .eq('status', 'approved')
  //       .order('created_at', ascending: false);

  //   if (_filter == SoundFilter.trending) {
  //     query = supabase
  //         .from('sounds')
  //         .select()
  //         .eq('status', 'approved')
  //         .eq('is_trending', true)
  //         .order('use_count', ascending: false);
  //   }

  //   if (_filter == SoundFilter.myUploads && currentUserId != null) {
  //     query = supabase
  //         .from('sounds')
  //         .select()
  //         .eq('uploaded_by', currentUserId!)
  //         .order('created_at', ascending: false);
  //   }

  //   if (_category != 'all') {
  //     query = (query as dynamic).eq('category', _category);
  //   }

  //   final res = await query;
  //   return (res as List).map((e) => SoundModel.fromJson(e)).toList();
  // }

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
