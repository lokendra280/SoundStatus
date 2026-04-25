// lib/services/sound_share_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sound_model.dart';

enum ShareTarget {
  any, // native OS share sheet — lets user pick
  whatsApp,
  messenger,
  telegram,
  instagram,
  twitter,
  sms,
  copyLink,
}

class SoundShareResult {
  final bool success;
  final String? error;
  const SoundShareResult({required this.success, this.error});
}

class SoundShareService {
  static final _supabase = Supabase.instance.client;

  /// Downloads the audio, writes to a temp file, opens the share sheet.
  /// [statusText] is shown as the share message alongside the audio file.
  static Future<SoundShareResult> shareSound({
    required SoundModel sound,
    String? statusText,
    ShareTarget target = ShareTarget.any,
    BuildContext? context,
  }) async {
    debugPrint('🔊 [ShareService] Sharing: ${sound.title}');

    try {
      // 1. Download audio bytes
      final bytes = await _downloadAudio(sound.fileUrl);
      if (bytes == null) {
        return const SoundShareResult(
          success: false,
          error: 'Failed to download audio',
        );
      }

      // 2. Write to temp file
      final tempFile = await _writeTempFile(bytes, sound);

      // 3. Build share message
      final message = _buildShareMessage(sound, statusText);

      // 4. Share via share_plus
      final xFile = XFile(
        tempFile.path,
        mimeType: _mimeType(tempFile.path),
        name: '${_sanitize(sound.title)}.${_ext(sound.fileUrl)}',
      );

      ShareResult result;

      if (target == ShareTarget.copyLink) {
        await Share.share(sound.fileUrl, subject: sound.title);
        await _recordShare(sound.id);
        return const SoundShareResult(success: true);
      }

      // For specific apps, pass sharePositionOrigin for iPad
      final shareParams = ShareParams(
        text: message,
        files: [xFile],
        subject: '🎵 ${sound.title} — StatusHub Sound',
      );

      if (target == ShareTarget.any) {
        // Use share_plus API to share files and obtain a ShareResult.
        result = await Share.shareXFiles(
          [xFile],
          text: message,
          subject: sound.title,
        );
      } else {
        // For specific targets — open the app directly
        final deepLink = _buildDeepLink(target, message, sound.fileUrl);
        if (deepLink != null && await _canLaunch(deepLink)) {
          await _launch(deepLink);
          await _recordShare(sound.id);
          return const SoundShareResult(success: true);
        }
        // Fallback to generic share sheet
        result = await Share.shareXFiles([xFile], text: message);
      }

      await _recordShare(sound.id);

      return SoundShareResult(
        success:
            result.status == ShareResultStatus.success ||
            result.status == ShareResultStatus.dismissed,
      );
    } catch (e) {
      debugPrint('❌ [ShareService] Error: $e');
      return SoundShareResult(success: false, error: e.toString());
    }
  }

  /// Share the public URL only (no file download needed)
  static Future<SoundShareResult> shareSoundLink({
    required SoundModel sound,
    String? statusText,
  }) async {
    try {
      final message = _buildShareMessage(sound, statusText);
      await Share.share(
        '$message\n\n🎵 ${sound.fileUrl}',
        subject: sound.title,
      );
      await _recordShare(sound.id);
      return const SoundShareResult(success: true);
    } catch (e) {
      return SoundShareResult(success: false, error: e.toString());
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────

  static Future<Uint8List?> _downloadAudio(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<File> _writeTempFile(Uint8List bytes, SoundModel sound) async {
    final dir = await getTemporaryDirectory();
    final ext = _ext(sound.fileUrl);
    final name = '${_sanitize(sound.title)}.$ext';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _buildShareMessage(SoundModel sound, String? statusText) {
    final parts = <String>[];
    if (statusText != null && statusText.isNotEmpty) {
      parts.add(statusText);
    }
    parts.add('🎵 ${sound.title}');
    parts.add('Shared via StatusHub Sound 🔊');
    return parts.join('\n');
  }

  static String? _buildDeepLink(
    ShareTarget target,
    String message,
    String url,
  ) {
    final encoded = Uri.encodeComponent(message);
    return switch (target) {
      ShareTarget.whatsApp => 'whatsapp://send?text=$encoded',
      ShareTarget.telegram => 'tg://msg?text=$encoded',
      ShareTarget.sms => 'sms:?body=$encoded',
      ShareTarget.twitter => 'twitter://post?message=$encoded',
      // Messenger / Instagram don't support direct text deep links reliably
      // — fall through to OS share sheet
      _ => null,
    };
  }

  static Future<bool> _canLaunch(String url) async {
    // Use url_launcher canLaunchUrl — imported where needed
    // Simplified here — always try
    return true;
  }

  static Future<void> _launch(String url) async {
    // url_launcher launchUrl — call from actual app
    // Placeholder — integrate with url_launcher in the widget
  }

  static Future<void> _recordShare(String soundId) async {
    try {
      await _supabase.rpc('increment_use_count', params: {'sound_id': soundId});
    } catch (_) {}
  }

  static String _ext(String url) {
    final path = Uri.parse(url).path;
    final parts = path.split('.');
    if (parts.length > 1) return parts.last.split('?').first.toLowerCase();
    return 'mp3';
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');

  static String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'm4a' => 'audio/mp4',
      _ => 'audio/mpeg',
    };
  }
}
