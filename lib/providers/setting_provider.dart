import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/auth_provider.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Settings state ────────────────────────────────────
class SettingsState {
  final bool notificationsEnabled;
  final bool darkMode;
  final String soundQuality;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.soundQuality = 'High',
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    String? soundQuality,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => SettingsState(
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    darkMode: darkMode ?? this.darkMode,
    soundQuality: soundQuality ?? this.soundQuality,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

// ── Result enums ──────────────────────────────────────
enum SignOutResult { success, error }

enum NotifResult { enabled, disabled, permissionDenied, error }

enum QualityResult { success, error }

enum RateResult { opened, notAvailable, error }

enum HelpResult { opened, error }

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Sync initial values from profile
    final profile = ref.watch(profileProvider).valueOrNull;
    return SettingsState(
      notificationsEnabled: profile?.notificationsEnabled ?? true,
      soundQuality: profile?.soundQuality ?? 'High',
    );
  }

  // ── Sign out ──────────────────────────────────────────
  Future<SignOutResult> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).signOut();
      state = state.copyWith(isLoading: false);
      return SignOutResult.success;
    } catch (e) {
      debugPrint('signOut error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return SignOutResult.error;
    }
  }

  // ── Toggle notifications ──────────────────────────────
  Future<NotifResult> toggleNotifications() async {
    final newVal = !state.notificationsEnabled;

    if (newVal) {
      // Request permission when enabling
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        return NotifResult.permissionDenied;
      }
    }

    state = state.copyWith(notificationsEnabled: newVal);

    try {
      final uid = currentUserId;
      if (uid == null) return NotifResult.error;
      await supabase
          .from('profiles')
          .update({'notifications_enabled': newVal})
          .eq('id', uid);
      await ref.read(profileProvider.notifier).refresh();
      return newVal ? NotifResult.enabled : NotifResult.disabled;
    } catch (e) {
      debugPrint('toggleNotifications error: $e');
      // Revert on failure
      state = state.copyWith(notificationsEnabled: !newVal);
      return NotifResult.error;
    }
  }

  // ── Set sound quality ─────────────────────────────────
  Future<QualityResult> setSoundQuality(String quality) async {
    final prev = state.soundQuality;
    state = state.copyWith(soundQuality: quality);

    try {
      final uid = currentUserId;
      if (uid == null) return QualityResult.error;
      await supabase
          .from('profiles')
          .update({'sound_quality': quality})
          .eq('id', uid);
      await ref.read(profileProvider.notifier).refresh();
      return QualityResult.success;
    } catch (e) {
      debugPrint('setSoundQuality error: $e');
      state = state.copyWith(soundQuality: prev);
      return QualityResult.error;
    }
  }

  // ── Rate app ──────────────────────────────────────────
  Future<RateResult> rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        return RateResult.opened;
      }
      // Fallback: open store page
      await review.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID');
      return RateResult.opened;
    } catch (e) {
      debugPrint('rateApp error: $e');
      return RateResult.error;
    }
  }

  // ── Help & FAQ ────────────────────────────────────────
  Future<HelpResult> openHelp() async {
    const url = 'https://statushub.app/help'; 
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return HelpResult.opened;
      }
      return HelpResult.error;
    } catch (e) {
      debugPrint('openHelp error: $e');
      return HelpResult.error;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
