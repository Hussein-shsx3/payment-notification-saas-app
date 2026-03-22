class RegisterOutcome {
  const RegisterOutcome({
    required this.success,
    this.needsEmailVerification = false,
    this.verificationEmailSent = true,
    this.errorMessage,
  });

  final bool success;
  /// Server asked the user to verify email before login.
  final bool needsEmailVerification;
  /// False when the server could not send mail (check Brevo env on the API).
  final bool verificationEmailSent;
  final String? errorMessage;
}
