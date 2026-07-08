import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// Must be a top-level function (outside any class) for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Firebase
  await Firebase.initializeApp();

  // Crashlytics — catch Flutter framework errors
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Catch async errors outside the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Optional: disable crash reporting in debug builds
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Push notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initPushNotifications();

  // Hive
  await Hive.initFlutter();
  await loadPrefsBeforeRunApp();

  // Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  try {
    await ensureAuthenticated();
  } catch (e) {
    debugPrint('Error refreshing session: $e');
  }

  // AdMob
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: App()));
}

Future<void> _initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // Request permission (iOS + Android 13+)
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get the device token — send this to Supabase if you target users individually
  final token = await messaging.getToken();
  debugPrint('FCM token: $token');

  // Foreground messages
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Show an in-app banner / local notification here if desired
  });

  // User tapped a notification that opened the app
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to a specific screen based on message.data
  });
}
