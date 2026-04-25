import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundstatus/providers/sound_upload_provider.dart';

const _kCategories = ['funny', 'meme', 'music', 'viral', 'general'];

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

  @override
  void dispose() {
    _player.dispose();
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

    // Get duration
    await _player.setFilePath(path);
    final dur = _player.duration;
    if (dur != null) setState(() => _duration = dur.inSeconds.toDouble());
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
          setState(() => _playing = false);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_audioFile == null || _title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick an audio file and add a title'),
        ),
      );
      return;
    }

    final tags = _tagsInput
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final soundId = await ref
        .read(soundUploadProvider.notifier)
        .uploadSound(
          audioFile: _audioFile!,
          title: _title,
          category: _category,
          tags: tags,
          durationSec: _duration,
        );

    if (!mounted) return;

    if (soundId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uploaded! Pending admin approval. You\'ll earn 20 coins when approved.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      ref.read(soundUploadProvider.notifier).reset();
      setState(() {
        _audioFile = null;
        _title = '';
        _tagsInput = '';
        _duration = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(soundUploadProvider);
    final isUploading = status.state == UploadState.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Sound'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '+20 on approval',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload box
            GestureDetector(
              onTap: _pickAudio,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 140,
                decoration: BoxDecoration(
                  color: _audioFile != null
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _audioFile != null
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: _audioFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audio_file_rounded,
                              size: 44,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to pick audio file',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'MP3, WAV, AAC supported',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.audio_file_rounded,
                              size: 44,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _audioFile!.path.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_duration != null)
                              Text(
                                '${_duration!.toStringAsFixed(1)}s',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),

            // Preview button
            if (_audioFile != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _previewAudio,
                icon: Icon(
                  _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_playing ? 'Stop preview' : 'Preview audio'),
              ),
            ],

            const SizedBox(height: 20),

            // Title
            TextField(
              decoration: const InputDecoration(
                labelText: 'Sound title *',
                hintText: 'e.g. Bruh Moment',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _title = v),
            ),

            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _kCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c[0].toUpperCase() + c.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'general'),
            ),

            const SizedBox(height: 16),

            // Tags
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'e.g. funny, viral, meme',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _tagsInput = v),
            ),

            const SizedBox(height: 8),
            Text(
              'Your sound will be reviewed by admin before going live.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 24),

            // Upload progress
            if (isUploading) ...[
              LinearProgressIndicator(value: status.progress),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(status.progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isUploading ? null : _submit,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(isUploading ? 'Uploading...' : 'Submit for Review'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
