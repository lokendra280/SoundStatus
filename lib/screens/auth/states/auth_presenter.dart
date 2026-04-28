import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/streak_provider.dart';
import 'package:soundstatus/screens/auth/states/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

final authPresenterProvider = NotifierProvider<AuthPresenter, AuthState>(
  AuthPresenter.new,
);

class AuthPresenter extends Notifier<AuthState> {
  final _supabase = Supabase.instance.client;

  @override
  AuthState build() => const AuthState();

  // ── Send OTP ──────────────────────────────────────────
  Future<SendOtpResult> sendOtp(String email) async {
    final trimmed = email.trim().toLowerCase();

    // Validate email
    if (!_isValidEmail(trimmed)) {
      state = state.copyWith(
        error: AuthError.invalidEmail,
        errorMessage: 'Please enter a valid email address',
      );
      return SendOtpResult.invalidEmail;
    }

    state = state.copyWith(isLoading: true, email: trimmed, clearError: true);

    try {
      await _supabase.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: true, // auto-create account if not exists
        emailRedirectTo: null,
      );

      state = state.copyWith(isLoading: false, step: AuthStep.otp);

      debugPrint('AuthPresenter: OTP sent to $trimmed');
      return SendOtpResult.success;
    } on AuthException catch (e) {
      debugPrint('AuthPresenter: sendOtp AuthException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: AuthError.unknown,
        errorMessage: e.message,
      );
      return SendOtpResult.error;
    } catch (e) {
      debugPrint('AuthPresenter: sendOtp error: $e');
      state = state.copyWith(
        isLoading: false,
        error: AuthError.networkError,
        errorMessage: 'Network error. Please try again.',
      );
      return SendOtpResult.error;
    }
  }

  // ── Verify OTP ────────────────────────────────────────
  Future<VerifyOtpResult> verifyOtp(String otp) async {
    final code = otp.trim();

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      state = state.copyWith(
        error: AuthError.invalidOtp,
        errorMessage: 'Enter the 6-digit code from your email',
      );
      return VerifyOtpResult.invalidOtp;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _supabase.auth.verifyOTP(
        email: state.email,
        token: code,
        type: OtpType.email,
      );

      // Trigger streak on first login of the day
      await ref.read(streakProvider.notifier).recordActivity();
      await ref.read(profileProvider.notifier).refresh();

      state = state.copyWith(isLoading: false, step: AuthStep.done);

      debugPrint('AuthPresenter: OTP verified for ${state.email}');
      return VerifyOtpResult.success;
    } on AuthException catch (e) {
      debugPrint('AuthPresenter: verifyOtp AuthException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: AuthError.invalidOtp,
        errorMessage: e.message,
      );
      return VerifyOtpResult.invalidOtp;
    } catch (e) {
      debugPrint('AuthPresenter: verifyOtp error: $e');
      state = state.copyWith(
        isLoading: false,
        error: AuthError.networkError,
        errorMessage: 'Network error. Please try again.',
      );
      return VerifyOtpResult.error;
    }
  }

  // ── Resend OTP ────────────────────────────────────────
  Future<SendOtpResult> resendOtp() async {
    debugPrint('AuthPresenter: resending OTP to ${state.email}');
    return sendOtp(state.email);
  }

  // ── Go back to email input ────────────────────────────
  void backToEmail() {
    state = state.copyWith(step: AuthStep.input, clearError: true);
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Private ───────────────────────────────────────────
  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// ── Result enums ──────────────────────────────────────
enum SendOtpResult { success, invalidEmail, error }

enum VerifyOtpResult { success, invalidOtp, error }
