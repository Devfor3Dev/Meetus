// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/auth_repository.dart' as _i726;
import '../../features/auth/data/facebook_token_source.dart' as _i950;
import '../../features/auth/data/google_id_token_source.dart' as _i293;
import '../../features/auth/data/mail_app_launcher.dart' as _i922;
import '../../features/auth/data/verification_deep_link_service.dart' as _i356;
import '../network/dio_client.dart' as _i667;
import '../storage/auth_session_store.dart' as _i861;
import '../storage/local_preferences_service.dart' as _i441;
import '../storage/secure_storage_service.dart' as _i666;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final preferencesModule = _$PreferencesModule();
    final dioModule = _$DioModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => preferencesModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i666.SecureStorageService>(
        () => _i666.SecureStorageService());
    gh.lazySingleton<_i950.FacebookTokenSource>(
        () => _i950.FacebookTokenSource());
    gh.lazySingleton<_i293.GoogleIdTokenSource>(
        () => _i293.GoogleIdTokenSource());
    gh.lazySingleton<_i922.MailAppLauncher>(() => _i922.MailAppLauncher());
    gh.lazySingleton<_i356.VerificationDeepLinkService>(
        () => _i356.VerificationDeepLinkService());
    gh.lazySingleton<_i441.LocalPreferencesService>(
        () => _i441.LocalPreferencesService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i861.AuthSessionStore>(
        () => _i861.AuthSessionStore(gh<_i666.SecureStorageService>()));
    await gh.factoryAsync<_i361.Dio>(
      () => dioModule.dio(gh<_i861.AuthSessionStore>()),
      preResolve: true,
    );
    gh.lazySingleton<_i726.AuthRepository>(() => _i726.AuthRepository(
          gh<_i361.Dio>(),
          gh<_i861.AuthSessionStore>(),
          gh<_i293.GoogleIdTokenSource>(),
          gh<_i950.FacebookTokenSource>(),
        ));
    return this;
  }
}

class _$PreferencesModule extends _i441.PreferencesModule {}

class _$DioModule extends _i667.DioModule {}
