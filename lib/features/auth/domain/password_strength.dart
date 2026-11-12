/// Niveau de solidité affiché sous le champ du mot de passe.
enum PasswordStrength {
  tooShort('Trop court', 0),
  weak('Faible', 1),
  fair('Correct', 2),
  strong('Solide', 3);

  const PasswordStrength(this.label, this.level);

  final String label;
  final int level;

  /// Estimation simple : longueur et variété des caractères. Elle
  /// guide l'utilisateur,
  static PasswordStrength evaluate(String password, {int minLength = 8}) {
    if (password.length < minLength) return PasswordStrength.tooShort;

    var points = 0;
    if (password.length >= 12) points++;
    final classes = [
      RegExp('[a-zà-ÿ]'),
      RegExp('[A-ZÀ-Þ]'),
      RegExp('[0-9]'),
      RegExp(r'[^A-Za-zà-ÿÀ-Þ0-9]'),
    ].where((pattern) => pattern.hasMatch(password)).length;
    if (classes >= 3) points++;
    if (password.length >= 16) points++;

    return switch (points) {
      0 => PasswordStrength.weak,
      1 => PasswordStrength.fair,
      _ => PasswordStrength.strong,
    };
  }
}
