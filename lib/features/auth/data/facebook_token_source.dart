import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:injectable/injectable.dart';

import '../domain/auth_exception.dart';

/// Obtient un jeton d'accès Facebook. Sfichier de l'application qui touche
/// au paquet flutter_facebook_auth.
///
/// L'identifiant d'application Facebook se déclare côté natif
/// (voir le README, section Facebook).
@lazySingleton
class FacebookTokenSource {
  Future<String> fetchAccessToken() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: const ['public_profile', 'email']);
      switch (result.status) {
        case LoginStatus.success:
          final token = result.accessToken?.tokenString;
          if (token == null || token.isEmpty) throw AuthException.generic();
          return token;
        case LoginStatus.cancelled:
          throw AuthException.cancelled();
        default:
          debugPrint('Connexion Facebook impossible : ${result.status} ${result.message}');
          throw AuthException.providerUnavailable('Facebook');
      }
    } on AuthException {
      rethrow;
    } catch (error) {
      debugPrint('Connexion Facebook impossible : $error');
      throw AuthException.providerUnavailable('Facebook');
    }
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (error) {
      debugPrint('Déconnexion Facebook ignorée : $error');
    }
  }
}
