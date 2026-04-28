import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/dashboard/pages/dashboard_page.dart';
import 'package:soundstatus/providers/auth_provider.dart';
import 'package:soundstatus/screens/auth/otp_screen.dart';
import 'package:soundstatus/widgets/button.dart';
import 'package:soundstatus/widgets/input_textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _State();
}

class _State extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _otpSent = false;
  bool _isSignUp = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // ── Listen to auth state — navigate when signed in ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(authProvider, (prev, next) {
        // Navigate to dashboard when auth succeeds
        if (!next.isLoading && next.isAuthenticated && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _cooldownSeconds = 0;
  bool get _inCooldown => _cooldownSeconds > 0;

  void _startCooldown(int seconds) {
    setState(() => _cooldownSeconds = seconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _cooldownSeconds--);
      return _cooldownSeconds > 0;
    });
  }

  String _friendlyError(String raw) {
    if (raw.startsWith('rate_limit:')) return ''; // handled separately
    final r = raw.toLowerCase();
    if (r.contains('not confirmed') || r.contains('email not confirmed')) {
      return 'Please verify your email first.\nTap "Resend verification" below.';
    }
    if (r.contains('invalid login') ||
        r.contains('invalid credentials') ||
        r.contains('wrong password') ||
        r.contains('user not found')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (r.contains('already registered') ||
        r.contains('already exists') ||
        r.contains('email address is already')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (r.contains('rate limit') || r.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (r.contains('network') ||
        r.contains('socket') ||
        r.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ── Validation ────────────────────────────────────────
  static final _emailRx = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String? _validate() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (!_emailRx.hasMatch(email)) return 'Enter a valid email address';
    if (pass.length < 6) return 'Password must be at least 6 characters';
    if (_isSignUp && pass != _confirmCtrl.text) return 'Passwords do not match';
    return null;
  }

  bool get _isEmailNotConfirmed =>
      _error?.contains('verify your email') == true ||
      _error?.contains('not confirmed') == true;

  // ── Submit ────────────────────────────────────────────
  // add to state
  Future<void> _submit() async {
    if (_inCooldown) return; // block submit during cooldown

    final validErr = _validate();
    if (validErr != null) {
      setState(() => _error = validErr);
      return;
    }
    setState(() => _error = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    final notifier = ref.read(authProvider.notifier);

    if (_isSignUp) {
      final err = await notifier.signUp(email, password);
      if (err != null) {
        setState(() => _error = _friendlyError(err));
        return;
      }

      final otpErr = await notifier.sendOtp(email);
      if (otpErr != null) {
        // Handle rate limit
        if (otpErr.startsWith('rate_limit:')) {
          final seconds = int.tryParse(otpErr.split(':').last) ?? 60;
          _startCooldown(seconds);
          return;
        }
        setState(() => _error = _friendlyError(otpErr));
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } else {
      final err = await notifier.signIn(email, password);
      if (err != null) {
        setState(() => _error = _friendlyError(err));
      }
      // Navigation handled by listenManual in initState
    }
  }

  // ── Resend verification ───────────────────────────────
  Future<void> _resendVerification() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!_emailRx.hasMatch(email)) {
      setState(() => _error = 'Enter your email address first');
      return;
    }

    final otpErr = await ref.read(authProvider.notifier).sendOtp(email);
    if (!mounted) return;

    if (otpErr != null) {
      setState(() => _error = 'Could not send verification email. Try again.');
      return;
    }

    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final authState = ref.watch(authProvider);
    final loading = authState.isLoading;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // Background orb
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryColor, Color(0xFF818CF8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(Assets.applogo, height: 20),
                  ),
                  const SizedBox(height: 24),

                  // Heading — fixed text
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Sign up to get started'
                        : 'Sign in to continue',
                    style: TextStyle(fontSize: 14, color: c.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  InputField(
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboard: TextInputType.emailAddress,
                    prefix: Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  InputField(
                    hint: 'Password',
                    controller: _passCtrl,
                    obscure: _obscure,
                    prefix: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: c.textMuted,
                    ),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: c.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // Confirm password (signup only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    InputField(
                      hint: 'Confirm password',
                      controller: _confirmCtrl,
                      obscure: _obscure,
                      prefix: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Toggle sign in / sign up
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Sign up",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAccent.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: kAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kAccent,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isEmailNotConfirmed) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: loading ? null : _resendVerification,
                              child: const Text(
                                'Resend verification email →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Primary CTA
                  PrimaryButton(
                    title: _isSignUp ? 'Create Account' : 'Sign In',
                    onPressed: (loading || _inCooldown || _otpSent)
                        ? () {}
                        : _submit,
                    widget: loading || _otpSent
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : _inCooldown
                        ? Text(
                            'Wait ${_cooldownSeconds}s',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
