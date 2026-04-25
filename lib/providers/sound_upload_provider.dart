import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constants.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum UploadState { idle, uploading, success, error }

class UploadStatus {
  final UploadState state;
  final double progress;
  final String? error;
  final String? uploadedSoundId;

  const UploadStatus({
    this.state = UploadState.idle,
    this.progress = 0,
    this.error,
    this.uploadedSoundId,
  });

  UploadStatus copyWith({
    UploadState? state,
    double? progress,
    String? error,
    String? uploadedSoundId,
  }) => UploadStatus(
    state: state ?? this.state,
    progress: progress ?? this.progress,
    error: error ?? this.error,
    uploadedSoundId: uploadedSoundId ?? this.uploadedSoundId,
  );
}

class SoundUploadNotifier extends Notifier<UploadStatus> {
  @override
  UploadStatus build() => const UploadStatus();

  Future<String?> uploadSound({
    required File audioFile,
    required String title,
    required String category,
    required List<String> tags,
    double? durationSec,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      state = state.copyWith(state: UploadState.error, error: 'Not logged in');
      return null;
    }

    state = state.copyWith(state: UploadState.uploading, progress: 0.1);

    try {
      // 1. Upload file to Supabase Storage
      final fileExt = audioFile.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final storagePath = 'uploads/$uid/$fileName';

      await supabase.storage
          .from(AppConstants.soundsBucket)
          .upload(
            storagePath,
            audioFile,
            fileOptions: const FileOptions(upsert: false),
          );

      state = state.copyWith(progress: 0.6);

      final fileUrl = supabase.storage
          .from(AppConstants.soundsBucket)
          .getPublicUrl(storagePath);

      // 2. Insert metadata into sounds table
      final res = await supabase
          .from('sounds')
          .insert({
            'title': title,
            'file_url': fileUrl,
            'duration_sec': durationSec,
            'category': category,
            'tags': tags,
            'uploaded_by': uid,
            'status': 'pending',
          })
          .select()
          .single();

      state = state.copyWith(
        state: UploadState.success,
        progress: 1.0,
        uploadedSoundId: res['id'],
      );

      return res['id'] as String;
    } catch (e) {
      state = state.copyWith(state: UploadState.error, error: e.toString());
      return null;
    }
  }

  void reset() => state = const UploadStatus();
}

final soundUploadProvider = NotifierProvider<SoundUploadNotifier, UploadStatus>(
  SoundUploadNotifier.new,
);
