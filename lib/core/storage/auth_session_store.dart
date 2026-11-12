import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_assets.dart';
import 'current_user_profile.dart';
import 'secure_storage_service.dart';

///  l'état de connexion.
///
/// Le jeton d'accès se trouve dans la mémoire  pour que l'intercepteur Dio le lise sans devoir
/// attendre, et il est copié dans [SecureStorageService] comme cela le jeton sera toujours dispo
/// en cas de rédémarrage.
/// pour le Le jeton de renouvellement il  est dans le cookie HttpOnly géré par le cookie jar (voir `dio_client.dart`).
///
/// Deux indicateurs gardent l'utilisateur dans le flux d'authentification alors
/// qu'il est déjà connecté : [needsIdentity] (prénom et nom pas encore saisis, par
/// exemple après une connexion Google ou Facebook) et [holdInFlow] (pour l'instant y a pas
/// d'écran suivant)
@lazySingleton
class AuthSessionStore {
  AuthSessionStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  String? _accessToken;

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  final ValueNotifier<bool> needsIdentity = ValueNotifier<bool>(false);
  final ValueNotifier<bool> holdInFlow = ValueNotifier<bool>(false);
  final ValueNotifier<CurrentUserProfile?> currentUser = ValueNotifier<CurrentUserProfile?>(null);

  String? get accessToken => _accessToken;

  void setCurrentUser(CurrentUserProfile profile) {
    currentUser.value = profile;
  }

  /// Relit la session au démarrage avant `runApp`.
  Future<void> restore() async {
    final token = await _secureStorage.read(key: AppStorageKeys.secureAuthToken);
    if (token == null || token.isEmpty) return;
    final flag = await _secureStorage.read(key: AppStorageKeys.secureNeedsIdentity);
    _accessToken = token;
    // Sans indication fiable, on redemande le nom
    needsIdentity.value = flag != '0';
    isAuthenticated.value = true;
  }

  /// Ouvre une session après une connexion réussie. L'utilisateur reste dans le
  /// flux jusqu'à [releaseFlow], pour voir l'écran suivant (je crois que c'est la partie pour compléter son profil)
  Future<void> setSession({required String accessToken, required bool needsIdentity}) async {
    _accessToken = accessToken;
    await _secureStorage.write(key: AppStorageKeys.secureAuthToken, value: accessToken);
    await _secureStorage.write(
      key: AppStorageKeys.secureNeedsIdentity,
      value: needsIdentity ? '1' : '0',
    );
    // L'indicateur d'identité passe avant celui de connexion
    this.needsIdentity.value = needsIdentity;
    holdInFlow.value = true;
    isAuthenticated.value = true;
  }

  ///
  void releaseFlow() {
    holdInFlow.value = false;
  }

  /// Remplace le jeton d'accès après un renouvellement
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await _secureStorage.write(key: AppStorageKeys.secureAuthToken, value: token);
  }

  Future<void> markIdentityDone() async {
    await _secureStorage.write(key: AppStorageKeys.secureNeedsIdentity, value: '0');
    needsIdentity.value = false;
  }

  /// déconnexion ou échec définitif du renouvellement.
  Future<void> clear() async {
    _accessToken = null;
    isAuthenticated.value = false;
    needsIdentity.value = false;
    holdInFlow.value = false;
    currentUser.value = null;
    await _secureStorage.delete(key: AppStorageKeys.secureAuthToken);
    await _secureStorage.delete(key: AppStorageKeys.secureNeedsIdentity);
  }
}
