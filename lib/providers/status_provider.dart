import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/status_model.dart';
import 'package:soundstatus/providers/profile_provider.dart';

class StatusNotifier extends AsyncNotifier<List<StatusModel>> {
  @override
  Future<List<StatusModel>> build() => _fetch();

  Future<List<StatusModel>> _fetch() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final res = await supabase
        .from('statuses')
        .select('*, sounds(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((e) => StatusModel.fromJson(e)).toList();
  }

  Future<StatusModel?> createStatus({String? text, String? soundId}) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return null;

    // Check share limit
    if (!profile.canShareFree) return null; // caller should show ad prompt

    final res = await supabase
        .from('statuses')
        .insert({'user_id': uid, 'text': text, 'sound_id': soundId})
        .select('*, sounds(*)')
        .single();

    // Increment share count
    await ref.read(profileProvider.notifier).incrementShare();

    // Increment sound use count
    if (soundId != null) {
      await supabase.rpc('increment_use_count', params: {'sound_id': soundId});
    }

    ref.invalidateSelf();
    return StatusModel.fromJson(res);
  }

  Future<void> deleteStatus(String statusId) async {
    await supabase.from('statuses').delete().eq('id', statusId);
    ref.invalidateSelf();
  }
}

final statusProvider = AsyncNotifierProvider<StatusNotifier, List<StatusModel>>(
  StatusNotifier.new,
);
