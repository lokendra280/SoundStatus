import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/models/sound_model.dart';

class AdminModerationNotifier extends AsyncNotifier<List<SoundModel>> {
  @override
  Future<List<SoundModel>> build() => _fetchPending();

  Future<List<SoundModel>> _fetchPending() async {
    final res = await supabase
        .from('sounds')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (res as List).map((e) => SoundModel.fromJson(e)).toList();
  }

  Future<void> approveSound(String soundId) async {
    final uid = currentUserId;
    if (uid == null) return;

    // Get sound to find uploader
    final sound = await supabase
        .from('sounds')
        .select()
        .eq('id', soundId)
        .single();

    // Update sound status
    await supabase
        .from('sounds')
        .update({
          'status': 'approved',
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': uid,
        })
        .eq('id', soundId);

    // Award upload coins to uploader
    final uploaderId = sound['uploaded_by'] as String?;
    if (uploaderId != null) {
      await supabase.rpc(
        'add_coins',
        params: {
          'p_user_id': uploaderId,
          'p_amount': AppConstants.uploadRewardCoins,
          'p_source': 'upload_reward',
          'p_note': 'Sound "${sound['title']}" approved',
        },
      );

      // Increment upload count
      await supabase.rpc('increment_upload_count', params: {'uid': uploaderId});
    }

    ref.invalidateSelf();
  }

  Future<void> rejectSound(String soundId, String reason) async {
    final uid = currentUserId;
    if (uid == null) return;

    await supabase
        .from('sounds')
        .update({
          'status': 'rejected',
          'reject_reason': reason,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': uid,
        })
        .eq('id', soundId);

    ref.invalidateSelf();
  }

  Future<void> toggleTrending(String soundId, bool isTrending) async {
    await supabase
        .from('sounds')
        .update({'is_trending': isTrending})
        .eq('id', soundId);
    ref.invalidateSelf();
  }
}

final adminModerationProvider =
    AsyncNotifierProvider<AdminModerationNotifier, List<SoundModel>>(
      AdminModerationNotifier.new,
    );
