import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Convenience getters
String? get currentUserId => supabase.auth.currentUser?.id;
bool get isLoggedIn => supabase.auth.currentUser != null;
bool get isAnonymous => supabase.auth.currentUser?.isAnonymous ?? false;

Future<void> ensureAuthenticated() async {
  // Already authenticated (anonymous or real)
  if (supabase.auth.currentUser != null) return;

  try {
    final response = await supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw Exception('Anonymous sign-in returned null user');
    }
  } on AuthException catch (e) {
    // Supabase-specific auth error (e.g. anonymous auth not enabled)
    throw Exception('Auth error: ${e.message}');
  } on Exception catch (e) {
    // Network or unknown error
    throw Exception('ensureAuthenticated failed: $e');
  }
}
