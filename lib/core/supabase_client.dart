import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Convenience getters
String? get currentUserId => supabase.auth.currentUser?.id;
bool get isLoggedIn => supabase.auth.currentUser != null;
