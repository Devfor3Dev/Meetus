import '../../../core/storage/current_user_profile.dart';

/// Représentation locale de l'utilisateur authentifié.
///
/// Écrit à la main, sans `freezed` ni `json_serializable` juste parce la surface de modèles est encore petite.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isVerified,
    required this.needsIdentity,
    this.firstName,
    this.lastName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      needsIdentity: json['needs_identity'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isVerified;

  /// True tant que le prénom et le nom ne sont pas enregistrés, par exemple
  /// après une première connexion Google ou Facebook.
  final bool needsIdentity;

  CurrentUserProfile toProfile() => CurrentUserProfile(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
}
