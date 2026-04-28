enum AuthStep { input, otp, done }

enum AuthError { invalidEmail, invalidOtp, networkError, unknown }

class AuthState {
  final AuthStep step;
  final bool isLoading;
  final String email;
  final AuthError? error;
  final String? errorMessage;

  const AuthState({
    this.step = AuthStep.input,
    this.isLoading = false,
    this.email = '',
    this.error,
    this.errorMessage,
  });

  bool get hasError => error != null;

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? email,
    AuthError? error,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
    step: step ?? this.step,
    isLoading: isLoading ?? this.isLoading,
    email: email ?? this.email,
    error: clearError ? null : (error ?? this.error),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
