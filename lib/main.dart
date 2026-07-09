import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soundstatus/core/notification_service.dart';
import 'package:soundstatus/core/supabase_client.dart';
import 'package:soundstatus/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

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
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Push notifications — background handler must be registered before runApp
  NotificationService.instance.registerBackgroundHandler();

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

  runApp(const ProviderScope(child: App()));

  // Fire-and-forget: never block or crash startup
  unawaited(NotificationService.instance.init());
  unawaited(MobileAds.instance.initialize());
}
