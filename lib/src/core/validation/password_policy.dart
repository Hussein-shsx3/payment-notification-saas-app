/// Matches server [getPasswordPolicyMessage]: ≥8 chars, letter, digit, special char.
/// Example: example2026$
bool isStrongPassword(String password) {
  if (password.length < 8) return false;
  if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) return false;
  return true;
}
