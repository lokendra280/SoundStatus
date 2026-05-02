import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

// ══════════════════════════════════════════════════════
//  AUTH STATE
// ══════════════════════════════════════════════════════
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  bool get isAuthenticated => user != null; // alias for listenManual

  AuthState loading() => AuthState(user: user, isLoading: true);
  AuthState withError(String e) => AuthState(user: user, error: e);
  AuthState loggedIn(User u) => AuthState(user: u);
  AuthState loggedOut() => const AuthState();
}

// ══════════════════════════════════════════════════════
//  AUTH NOTIFIER
// ══════════════════════════════════════════════════════
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Sync state with Supabase auth stream
    _sb.auth.onAuthStateChange.listen((event) {
      state = event.session?.user != null
          ? state.loggedIn(event.session!.user)
          : state.loggedOut();
    });
    return AuthState(user: _sb.auth.currentUser);
  }

  static const _webClientId =
      '993530550886-ut3pki685q7ieb5tn3tcst26d799delq.apps.googleusercontent.com';
  //
  // ── Sign up ───────────────────────────────────────────
  // Always stays logged-out after signup so OTP screen
  // handles verification before granting access.
  Future<String?> signUp(String email, String password) async {
    state = state.loading();
    try {
      final res = await _sb.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (res.user == null) {
        state = state.withError('Sign up failed');
        return 'Sign up failed';
      }
      // Stay logged out — OTP verification required first
      state = state.loggedOut();
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  // ── Sign in ───────────────────────────────────────────
  Future<String?> signIn(String email, String password) async {
    state = state.loading();
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      state = res.user != null
          ? state.loggedIn(res.user!)
          : state.withError('Sign in failed');
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  // ── Send OTP ──────────────────────────────────────────
  Future<String?> sendOtp(String email) async {
    try {
      await _sb.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,
      );
      return null;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // Extract seconds from rate limit message
      if (msg.contains('rate_limit') ||
          msg.contains('over_email_send_rate_limit') ||
          msg.contains('security purposes')) {
        final match = RegExp(r'(\d+)\s*second').firstMatch(msg);
        final seconds = match?.group(1) ?? '60';
        return 'rate_limit:$seconds'; // pass seconds to UI
      }
      return e.toString();
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Google Sign-In: starting authenticate()');

      // Initialize with serverClientId before authenticate()
      await GoogleSignIn.instance.initialize(serverClientId: _webClientId);

      // Use authenticate() for version 7.x
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      debugPrint('🔵 Google account: ${googleUser.email}');

      // Get authentication - returns GoogleSignInAuthentication directly
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('🔵 idToken: ${idToken != null ? "found ✅" : "NULL ❌"}');

      if (idToken == null) {
        throw Exception(
          'No ID Token. Ensure Web Client ID is configured correctly.',
        );
      }

      // For accessToken in v7.x, we need to get it from authorizationClient
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email']);
        accessToken = authorization?.accessToken;
        debugPrint(
          '🔵 accessToken: ${accessToken != null ? "found ✅" : "NULL"}',
        );
      } catch (e) {
        debugPrint('🟡 Could not get access token: $e');
      }

      // Sign in to Supabase with Google tokens
      debugPrint('🔵 Signing in to Supabase...');
      final response = await _sb.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('✅ Supabase sign-in success: ${response.user?.email}');
      return response;
    } on GoogleSignInException catch (e) {
      debugPrint(' GoogleSignInException: ${e.code} - ${e.toString()}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint(' User cancelled — returning null');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in GoogleAuthService.signIn(): $e');
      rethrow;
    }
  }

  // ── Verify OTP ────────────────────────────────────────
  Future<String?> verifyOtp(String email, String token) async {
    state = state.loading();
    try {
      final res = await _sb.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,
      );
      state = res.user != null
          ? state.loggedIn(res.user!)
          : state.withError('Invalid or expired code');
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  // ── Sign out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _sb.auth.signOut();
    state = state.loggedOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ══════════════════════════════════════════════════════
//  DERIVED PROVIDERS
// ══════════════════════════════════════════════════════
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider).user,
);

final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isLoggedIn,
);

final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'Guest';
  final meta = user.userMetadata;
  return (meta?['full_name'] as String?) ??
      (meta?['name'] as String?) ??
      user.email?.split('@').first ??
      'User';
});

final userInitialsProvider = Provider<String>((ref) {
  final name = ref.watch(userNameProvider);
  final parts = name.trim().split(' ');
  return parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
});

final userEmailProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.email ?? '',
);

final userAvatarProvider = Provider<String?>(
  (ref) =>
      ref.watch(currentUserProvider)?.userMetadata?['avatar_url'] as String?,
);
