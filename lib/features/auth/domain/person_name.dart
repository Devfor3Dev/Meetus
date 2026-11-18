/// Raison pour laquelle un prénom ou un nom est refusé.
enum NameIssue { empty, tooLong, invalidCharacters }

/// Règles d'un prénom ou d'un nom. Les mêmes que celles de l'API, :
/// ce contrôle évite seulement un aller-retour réseau inutile.
abstract final class PersonName {
  static const int maxLength = 50;

  /// Lettres de toutes les langues, séparées par un espace, une apostrophe ou un tiret.
  static final RegExp _pattern = RegExp(r"^\p{L}+(?:[ '’-]\p{L}+)*$", unicode: true);

  /// Retire les espaces en trop, au début, à la fin et au milieu.
  static String normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static NameIssue? validate(String raw) {
    final name = normalize(raw);
    if (name.isEmpty) return NameIssue.empty;
    if (name.length > maxLength) return NameIssue.tooLong;
    if (!_pattern.hasMatch(name)) return NameIssue.invalidCharacters;
    return null;
  }

  const PersonName._();
}
