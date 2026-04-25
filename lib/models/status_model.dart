import 'sound_model.dart';

class StatusModel {
  final String id;
  final String userId;
  final String? text;
  final String? soundId;
  final SoundModel? sound;
  final int shareCount;
  final DateTime createdAt;

  const StatusModel({
    required this.id,
    required this.userId,
    this.text,
    this.soundId,
    this.sound,
    this.shareCount = 0,
    required this.createdAt,
  });

  factory StatusModel.fromJson(Map<String, dynamic> j) => StatusModel(
    id: j['id'],
    userId: j['user_id'],
    text: j['text'],
    soundId: j['sound_id'],
    sound: j['sounds'] != null ? SoundModel.fromJson(j['sounds']) : null,
    shareCount: j['share_count'] ?? 0,
    createdAt: DateTime.parse(j['created_at']),
  );
}
