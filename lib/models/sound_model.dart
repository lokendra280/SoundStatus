enum SoundStatus { pending, approved, rejected }

class SoundModel {
  final String id;
  final String title;
  final String fileUrl;
  final double? durationSec;
  final String category;
  final List<String> tags;
  final String? uploadedBy;
  final SoundStatus status;
  final String? rejectReason;
  final int playCount;
  final int useCount;
  final bool isTrending;
  final DateTime createdAt;
  final String? userName;

  const SoundModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.durationSec,
    this.category = 'general',
    this.tags = const [],
    this.uploadedBy,
    this.status = SoundStatus.pending,
    this.rejectReason,
    this.playCount = 0,
    this.useCount = 0,
    this.userName,

    this.isTrending = false,
    required this.createdAt,
  });

  factory SoundModel.fromJson(Map<String, dynamic> j) => SoundModel(
    id: j['id'],
    title: j['title'],
    fileUrl: j['file_url'],
    durationSec: (j['duration_sec'] as num?)?.toDouble(),
    category: j['category'] ?? 'general',
    tags: List<String>.from(j['tags'] ?? []),
    uploadedBy: j['uploaded_by'],
    status: _statusFromString(j['status']),
    rejectReason: j['reject_reason'],
    playCount: j['play_count'] ?? 0,
    useCount: j['use_count'] ?? 0,
    userName: j['profiles']?['name'],
    isTrending: j['is_trending'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
  );

  static SoundStatus _statusFromString(String? s) => switch (s) {
    'approved' => SoundStatus.approved,
    'rejected' => SoundStatus.rejected,
    _ => SoundStatus.pending,
  };

  Map<String, dynamic> toInsertJson({required String userId}) => {
    'title': title,
    'file_url': fileUrl,
    'duration_sec': durationSec,
    'category': category,
    'tags': tags,
    'uploaded_by': userId,
    'status': 'pending',
  };
}
