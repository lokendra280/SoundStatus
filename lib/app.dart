import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/providers/theme_provider.dart';
import 'package:soundstatus/screens/splash/splash_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'StatusHub Sound',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(false), // light
      darkTheme: buildTheme(true), // dark
      // home: Supabase.instance.client.auth.currentUser != null
      //     ? const DashboardPage()
      //     : const LoginScreen(),
      home: SplashScreen(),
    );
  }
}
