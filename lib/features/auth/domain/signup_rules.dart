/// Règles de saisie partagées par les écrans du flux.
abstract final class SignupRules {
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizeEmail(String raw) => raw.trim().toLowerCase();

  static bool isValidEmail(String value) => _email.hasMatch(value);

  const SignupRules._();
}
