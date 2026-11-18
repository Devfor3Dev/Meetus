import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';

/// Préférences locales non sensibles.
/// Attention, mettez pas de données sensibles, ni de jeton, ni tout autre secret
/// voir [SecureStorageService].
@lazySingleton
class LocalPreferencesService {
  const LocalPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  bool get hasSeenOnboarding => _prefs.getBool(AppStorageKeys.hasSeenOnboarding) ?? false;

  Future<void> setOnboardingSeen() => _prefs.setBool(AppStorageKeys.hasSeenOnboarding, true);
}

/// Fournit l'instance SharedPreferences au conteneur d'injection. L'attente est
/// faite avant `runApp`, dans `configureDependencies()`.
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
