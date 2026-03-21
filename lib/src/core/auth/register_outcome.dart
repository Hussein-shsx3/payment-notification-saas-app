class RegisterOutcome {
  const RegisterOutcome({
    required this.success,
    this.needsEmailVerification = false,
    this.errorMessage,
  });

  final bool success;
  /// Server asked the user to verify email before login.
  final bool needsEmailVerification;
  final String? errorMessage;
}
