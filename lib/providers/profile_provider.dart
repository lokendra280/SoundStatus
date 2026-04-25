import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/profile_model.dart';

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _fetch(uid);
  }

  Future<ProfileModel?> _fetch(String uid) async {
    final res = await supabase.from('profiles').select().eq('id', uid).single();
    return ProfileModel.fromJson(res);
  }

  Future<void> refresh() async {
    final uid = currentUserId;
    if (uid == null) return;
    state = await AsyncValue.guard(() => _fetch(uid));
  }

  // Called after a share — resets daily counter if date changed
  Future<void> incrementShare() async {
    final uid = currentUserId;
    if (uid == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;

    // If date changed, reset counter
    final profile = state.valueOrNull;
    if (profile != null && profile.shareResetDate != today) {
      await supabase
          .from('profiles')
          .update({'share_count_today': 1, 'share_reset_date': today})
          .eq('id', uid);
    } else {
      await supabase.rpc('increment_share_count', params: {'uid': uid});
    }
    await refresh();
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(
  ProfileNotifier.new,
);
