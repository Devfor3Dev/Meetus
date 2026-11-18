import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Enveloppe autour de `flutter_secure_storage` (Keystore Android, Keychain iOS).
///
/// Réservé aux données sensibles et durables, comme le jeton d'accès. Les
/// indicateurs non sensibles passent par `shared_preferences`.
///
/// Chaque opération s'occuppe de  ses erreurs : le Keystore Android peut devenir illisible
/// après une restauration de sauvegarde ou un changement de verrouillage de
/// l'appareil, et l'application ne doit pas planter au démarrage pour autant.
@lazySingleton
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      debugPrint('SecureStorageService.write : échec pour "$key" : $error');
    }
  }

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      debugPrint('SecureStorageService.read : échec pour "$key" : $error');
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('SecureStorageService.delete : échec pour "$key" : $error');
    }
  }
}
