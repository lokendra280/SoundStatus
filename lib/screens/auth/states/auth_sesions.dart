// auth_flow_state.dart
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Enums ─────────────────────────────────────────────
enum AuthStep { input, otp, done }

enum AuthError { invalidEmail, invalidOtp, networkError, unknown }

enum SendOtpResult { success, invalidEmail, error }

enum VerifyOtpResult { success, invalidOtp, error }

// ══════════════════════════════════════════════════════
//  SESSION STATE
// ══════════════════════════════════════════════════════
class AuthSession {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthSession({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  bool get isAnonymous => user?.isAnonymous ?? false;
  bool get isRegistered => isLoggedIn && !isAnonymous;

  AuthSession loading() => AuthSession(user: user, isLoading: true);
  AuthSession withError(String e) => AuthSession(user: user, error: e);
  AuthSession loggedIn(User u) => AuthSession(user: u);
  AuthSession loggedOut() => const AuthSession();
}

// ══════════════════════════════════════════════════════
//  UI FLOW STATE
// ══════════════════════════════════════════════════════
class AuthFlowState {
  final AuthStep step;
  final bool isLoading;
  final String email;
  final AuthError? error;
  final String? errorMessage;

  const AuthFlowState({
    this.step = AuthStep.input,
    this.isLoading = false,
    this.email = '',
    this.error,
    this.errorMessage,
  });

  bool get hasError => error != null;

  AuthFlowState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? email,
    AuthError? error,
    String? errorMessage,
    bool clearError = false,
  }) => AuthFlowState(
    step: step ?? this.step,
    isLoading: isLoading ?? this.isLoading,
    email: email ?? this.email,
    error: clearError ? null : (error ?? this.error),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
