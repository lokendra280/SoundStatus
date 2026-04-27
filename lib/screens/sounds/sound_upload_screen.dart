import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/providers/sound_upload_provider.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

const _purple = Color(0xFF534AB7);
const _purpleLight = Color(0xFFEEEDFE);
const _purpleMid = Color(0xFFAFA9EC);
const _dark = Color(0xFF1A1A1A);
const _teal = Color(0xFF0F6E56);
const _tealLight = Color(0xFFE1F5EE);
const _amber = Color(0xFFBA7517);
const _amberLight = Color(0xFFFAEEDA);

const _kCategories = ['funny', 'meme', 'music', 'viral', 'general'];

const _kCategoryMeta = {
  'funny': (
    icon: Icons.sentiment_very_satisfied_rounded,
    color: Color(0xFFBA7517),
  ),
  'meme': (icon: Icons.auto_awesome_rounded, color: Color(0xFF534AB7)),
  'music': (icon: Icons.music_note_rounded, color: Color(0xFF0F6E56)),
  'viral': (
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFA32D2D),
  ),
  'general': (icon: Icons.library_music_rounded, color: Color(0xFF185FA5)),
};

class SoundUploadScreen extends ConsumerStatefulWidget {
  const SoundUploadScreen({super.key});

  @override
  ConsumerState<SoundUploadScreen> createState() => _SoundUploadScreenState();
}

class _SoundUploadScreenState extends ConsumerState<SoundUploadScreen> {
  File? _audioFile;
  String _title = '';
  String _category = 'general';
  String _tagsInput = '';
  double? _duration;
  final _player = AudioPlayer();
  bool _playing = false;
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  // AI suggested tags (simulated)
  final List<String> _suggestedTags = ['funny', 'viral', 'meme', 'trending'];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _player.dispose();
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final res = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (res == null) return;
    final path = res.files.single.path;
    if (path == null) return;
    final file = File(path);
    setState(() => _audioFile = file);
    await _player.setFilePath(path);
    final dur = _player.duration;
    if (dur != null) setState(() => _duration = dur.inSeconds.toDouble());

    // Auto-suggest title from filename
    if (_titleCtrl.text.isEmpty) {
      final name = path
          .split('/')
          .last
          .replaceAll(RegExp(r'\.[^.]+$'), '')
          .replaceAll('_', ' ')
          .replaceAll('-', ' ');
      _titleCtrl.text = name;
      setState(() => _title = name);
    }
  }

  Future<void> _previewAudio() async {
    if (_audioFile == null) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      await _player.setFilePath(_audioFile!.path);
      await _player.play();
      setState(() => _playing = true);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playing = false);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_audioFile == null || _title.isEmpty) {
      _snack('Please pick an audio file and add a title', error: true);
      return;
    }
    final manualTags = _tagsInput
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final allTags = {..._selectedTags, ...manualTags}.toList();

    final soundId = await ref
        .read(soundUploadProvider.notifier)
        .uploadSound(
          audioFile: _audioFile!,
          title: _title,
          category: _category,
          tags: allTags,
          durationSec: _duration,
        );

    if (!mounted) return;
    if (soundId != null) {
      _snack(
        'Uploaded! Pending admin approval. You\'ll earn 20 coins when approved.',
      );
      ref.read(soundUploadProvider.notifier).reset();
      setState(() {
        _audioFile = null;
        _title = '';
        _tagsInput = '';
        _duration = null;
        _selectedTags.clear();
        _titleCtrl.clear();
        _tagsCtrl.clear();
      });
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? const Color(0xFFA32D2D) : _teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

  String _formatDuration(double secs) {
    final m = (secs ~/ 60).toString().padLeft(1, '0');
    final s = (secs % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatSize(File f) {
    final bytes = f.lengthSync();
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(soundUploadProvider);
    final isUploading = status.state == UploadState.uploading;
    final catMeta = _kCategoryMeta[_category]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: _dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Sound',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '+20 on approval',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amber,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFEFEFEF)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload Box ──────────────────────────────
            _audioFile == null
                ? _UploadDropZone(onTap: _pickAudio)
                : _AudioPreviewCard(
                    file: _audioFile!,
                    duration: _duration,
                    isPlaying: _playing,
                    onPlay: _previewAudio,
                    onRemove: () => setState(() {
                      _audioFile = null;
                      _duration = null;
                      _playing = false;
                    }),
                    formatDuration: _formatDuration,
                    formatSize: _formatSize,
                  ),

            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────
            _SectionLabel('Sound title', required: true),
            const SizedBox(height: 6),
            _Field(
              controller: _titleCtrl,
              hint: 'e.g. Bruh Moment',
              onChanged: (v) => setState(() => _title = v),
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),

            // ── Category ────────────────────────────────
            _SectionLabel('Category'),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kCategories.map((cat) {
                  final meta = _kCategoryMeta[cat]!;
                  final active = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? meta.color : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: active
                                ? meta.color
                                : const Color(0xFFEFEFEF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meta.icon,
                              size: 14,
                              color: active ? Colors.white : meta.color,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat[0].toUpperCase() + cat.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : _dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── AI Tags ─────────────────────────────────
            Row(
              children: [
                const _SectionLabel('Tags'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _purpleLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'AI suggested',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _suggestedTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected
                        ? _selectedTags.remove(tag)
                        : _selectedTags.add(tag);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _purple : _purpleLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _purple : _purpleMid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        Text(
                          '# $tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _Field(
              controller: _tagsCtrl,
              hint: 'Add more tags, comma separated',
              onChanged: (v) => setState(() => _tagsInput = v),
              prefixIcon: Icons.tag_rounded,
            ),
            const SizedBox(height: 16),

            // ── Review notice ───────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF5DCAA5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded, color: _teal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin review required',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF085041),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your sound will be reviewed before going live. '
                          'You\'ll earn +20 coins once approved.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.teal[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Upload progress ─────────────────────────
            if (isUploading) ...[
              _UploadProgress(progress: status.progress),
              const SizedBox(height: 16),
            ],

            // ── Submit button ───────────────────────────
            GestureDetector(
              onTap: isUploading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isUploading ? _purple.withOpacity(0.5) : _purple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      // const Icon(
                      //   Icons.upload_rounded,
                      //   color: Colors.white,
                      //   size: 20,
                      // ),
                      CommonSvgWidget(svgName: Assets.uploadMusic, height: 20),
                    const SizedBox(width: 10),
                    Text(
                      isUploading ? 'Uploading...' : 'Submit for Review',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (!isUploading) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '+20 coins',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  UPLOAD DROP ZONE
// ══════════════════════════════════════════════════════
class _UploadDropZone extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadDropZone({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _purpleMid,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: _purpleLight,
              shape: BoxShape.circle,
            ),
            child: CommonSvgWidget(
              svgName: Assets.file,
              color: _purple,
              height: 20,
              width: 20,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tap to upload audio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MP3, WAV, OGG · Max 10 MB',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 60, height: 1, color: const Color(0xFFEFEFEF)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
              Container(width: 60, height: 1, color: const Color(0xFFEFEFEF)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _purpleMid),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonSvgWidget(
                  svgName: Assets.mic,
                  color: _purple,
                  height: 16,
                  width: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Record audio',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  AUDIO PREVIEW CARD
// ══════════════════════════════════════════════════════
class _AudioPreviewCard extends StatelessWidget {
  final File file;
  final double? duration;
  final bool isPlaying;
  final VoidCallback onPlay, onRemove;
  final String Function(double) formatDuration;
  final String Function(File) formatSize;

  const _AudioPreviewCard({
    required this.file,
    required this.duration,
    required this.isPlaying,
    required this.onPlay,
    required this.onRemove,
    required this.formatDuration,
    required this.formatSize,
  });

  static const _bars = [
    5.0,
    12.0,
    8.0,
    16.0,
    6.0,
    14.0,
    10.0,
    18.0,
    7.0,
    13.0,
    5.0,
    16.0,
    9.0,
    14.0,
    6.0,
    18.0,
    8.0,
    12.0,
    5.0,
    14.0,
    10.0,
    16.0,
    7.0,
    13.0,
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _purpleMid),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File info row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.audio_file_rounded,
                color: _purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.path.split('/').last,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatSize(file)}${duration != null ? ' · ${formatDuration(duration!)}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFA32D2D),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Waveform + play
        Row(
          children: [
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _purple,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _bars
                      .map(
                        (h) => Container(
                          width: 3,
                          height: h,
                          decoration: BoxDecoration(
                            color: isPlaying ? _purple : _purpleMid,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              duration != null ? formatDuration(duration!) : '--:--',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Change file
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Change file',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  UPLOAD PROGRESS
// ══════════════════════════════════════════════════════
class _UploadProgress extends StatelessWidget {
  final double progress;
  const _UploadProgress({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _purpleLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _purpleMid),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Uploading sound...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _purple,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _purpleMid.withOpacity(0.3),
            color: _purple,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _SectionLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _dark,
        ),
      ),
      if (required)
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFA32D2D),
          ),
        ),
    ],
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final IconData prefixIcon;

  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEFEFEF)),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(prefixIcon, color: _purple, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    ),
  );
}
