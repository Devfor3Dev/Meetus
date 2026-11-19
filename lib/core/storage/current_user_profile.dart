/// Profil minimal de l'utilisateur quand il est  connecté, actuellement on se trouve dans  `core/`, il boose sans
/// dépendre de `features/`. C'est le dépôt d'authentification qui traduit son
/// type complet vers celui-ci au moment de le ranger dans [AuthSessionStore].
class CurrentUserProfile {
  const CurrentUserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  String get fullName => [firstName, lastName].whereType<String>().join(' ');
}
