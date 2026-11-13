import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/api_config.dart';
import '../domain/auth_exception.dart';

/// Obtient un jeton d'identité Google. fichier de l'application qui touche
/// au paquet google_sign_in
@lazySingleton
class GoogleIdTokenSource {
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance
        .initialize(serverClientId: ApiConfig.googleServerClientId)
        .catchError((Object error) {
      // On ne garde pas une initialisation ratée en cache
      _initialization = null;
      throw error;
    });
  }

  Future<String> fetchIdToken() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      debugPrint('GOOGLE_SERVER_CLIENT_ID manquant : voir le README, section Google.');
      throw AuthException.providerUnavailable('Google');
    }
    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw AuthException.providerUnavailable('Google');
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) throw AuthException.generic();
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException.cancelled();
      }
      debugPrint('Connexion Google impossible : ${error.code}');
      throw AuthException.providerUnavailable('Google');
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      debugPrint('Déconnexion Google ignorée : $error');
    }
  }
}
