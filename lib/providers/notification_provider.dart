import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/profile_provider.dart';

class NotificationState {
  final bool enabled;
  final bool rankUpAlert;
  final bool overtakenAlert;
  final bool dailyResetAlert;
  final bool rewardAlert;
  final bool isLoading;

  const NotificationState({
    this.enabled = true,
    this.rankUpAlert = true,
    this.overtakenAlert = true,
    this.dailyResetAlert = true,
    this.rewardAlert = true,
    this.isLoading = false,
  });

  NotificationState copyWith({
    bool? enabled,
    bool? rankUpAlert,
    bool? overtakenAlert,
    bool? dailyResetAlert,
    bool? rewardAlert,
    bool? isLoading,
  }) => NotificationState(
    enabled: enabled ?? this.enabled,
    rankUpAlert: rankUpAlert ?? this.rankUpAlert,
    overtakenAlert: overtakenAlert ?? this.overtakenAlert,
    dailyResetAlert: dailyResetAlert ?? this.dailyResetAlert,
    rewardAlert: rewardAlert ?? this.rewardAlert,
    isLoading: isLoading ?? this.isLoading,
  );
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationState>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends Notifier<NotificationState> {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  NotificationState build() {
    _init();
    final profile = ref.watch(profileProvider).valueOrNull;
    return NotificationState(enabled: profile?.notificationsEnabled ?? true);
  }

  Future<void> _init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
    );
  }

  // ── Toggle master switch ──────────────────────────────
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value, isLoading: true);
    try {
      final uid = currentUserId;
      if (uid != null) {
        await supabase
            .from('profiles')
            .update({'notifications_enabled': value})
            .eq('id', uid);
        await ref.read(profileProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('setEnabled error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Toggle individual types ───────────────────────────
  void setRankUpAlert(bool v) => state = state.copyWith(rankUpAlert: v);
  void setOvertakenAlert(bool v) => state = state.copyWith(overtakenAlert: v);
  void setDailyResetAlert(bool v) => state = state.copyWith(dailyResetAlert: v);
  void setRewardAlert(bool v) => state = state.copyWith(rewardAlert: v);

  // ── Show local notification ───────────────────────────
  Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!state.enabled) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'statushub_main',
          'StatusHub',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Predefined alerts ─────────────────────────────────
  Future<void> rankUpNotif(int newRank) async {
    if (!state.rankUpAlert) return;
    await show(
      title: 'You moved up!',
      body: 'You are now ranked #$newRank on the leaderboard',
      id: 1,
    );
  }

  Future<void> overtakenNotif(String byUser) async {
    if (!state.overtakenAlert) return;
    await show(
      title: 'You were overtaken',
      body: '@$byUser just passed you on the leaderboard',
      id: 2,
    );
  }

  Future<void> rewardReadyNotif() async {
    if (!state.rewardAlert) return;
    await show(
      title: 'Reward available!',
      body: 'Your leaderboard reward is ready to claim',
      id: 3,
    );
  }

  Future<void> dailyResetNotif() async {
    if (!state.dailyResetAlert) return;
    await show(
      title: 'Daily leaderboard reset',
      body: 'A new day, a new chance to reach #1!',
      id: 4,
    );
  }
}
