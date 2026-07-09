import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global key so the service can show in-app snackbars without a BuildContext.
/// Register this on your MaterialApp: `scaffoldMessengerKey: scaffoldMessengerKey`
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Must be a top-level function (outside any class) for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// Call this once, right after `main()`. Registers the background handler.
  /// Must happen before runApp for background messages to work reliably.
  void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call this after runApp (fire-and-forget). Handles permission, token,
  /// foreground display, and tap navigation. Never throws.
  Future<void> init() async {
    try {
      // 1. Permission (required on Android 13+ and iOS).
      final settings = await _messaging.requestPermission();
      debugPrint('Notification permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // User declined — skip token registration.
      }

      // 2. Local notifications setup (for foreground display).
      await _initLocalNotifications();

      // 3. FCM token.
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM token: $token');
        // TODO: register token with your backend
      }

      _messaging.onTokenRefresh.listen((newToken) {
        // TODO: update token on your backend
      }, onError: (e) => debugPrint('Token refresh error: $e'));

      // 4. Foreground messages — show system notification + in-app snackbar.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 5. Taps on background notifications that open the app.
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

      // 6. Notification that launched the app from a terminated state.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onNotificationTap(initialMessage);
      }
    } on FirebaseException catch (e, stack) {
      // TOO_MANY_REGISTRATIONS, SERVICE_NOT_AVAILABLE, etc. — device-side,
      // app continues without push.
      debugPrint('FCM unavailable: ${e.message}');
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    } catch (e, stack) {
      debugPrint('Unexpected notification error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifs.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
        _navigateFromPayload(response.payload);
      },
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('Foreground message: ${notification.title}');

    // System notification (heads-up banner + tray).
    _localNotifs.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );

    // In-app snackbar.
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          [
            if (notification.title != null) notification.title!,
            if (notification.body != null) notification.body!,
          ].join('\n'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateFromPayload(message.data['route']),
        ),
      ),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    _navigateFromPayload(message.data['route']);
  }

  void _navigateFromPayload(String? route) {
    if (route == null || route.isEmpty) return;
    // TODO: navigate using your router, e.g. with a global navigatorKey:
    // navigatorKey.currentState?.pushNamed(route);
    debugPrint('Navigate to: $route');
  }
}
