import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/auth_session_store.dart';
import 'api_config.dart';

/// Clé d'option Dio marquant les requêtes publiques (connexion, renouvellement)

const String kRequiresAuthOptionKey = 'requiresAuth';

/// Fabrique l' instance Dio de l'application.
///
/// Le cookie jar conserve sur disque le cookie `refresh_token` posé par l'API
/// (HttpOnly, SameSite=Strict, chemin /auth) et le renvoie seulement vers /auth/*.
///
///
@module
abstract class DioModule {
  @preResolve
  Future<Dio> dio(AuthSessionStore sessionStore) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json', 'Accept-Language': 'fr'},
      ),
    );

    final appDir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${appDir.path}/.cookies/'));

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(AuthInterceptor(dio, sessionStore));
    return dio;
  }
}

/// Ajoute le jeton d'accès aux requêtes protégées et le renouvelle sur un 401.
///
/// quand plusieurs requêtes échouent en même temps, ils partagent un seul renouvellement
/// et attendent son résultat, puis repartent chacune avec le nouveau jeton.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._sessionStore);

  final Dio _dio;
  final AuthSessionStore _sessionStore;

  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requiresAuth = options.extra[kRequiresAuthOptionKey] as bool? ?? true;
    final token = _sessionStore.accessToken;
    if (requiresAuth && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requiresAuth = err.requestOptions.extra[kRequiresAuthOptionKey] as bool? ?? true;
    final alreadyRetried = err.requestOptions.extra['retried'] as bool? ?? false;

    if (err.response?.statusCode != 401 || !requiresAuth || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshOnce();
    if (newToken == null) {
      handler.next(err);
      return;
    }

    try {
      final retry = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['retried'] = true;
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshOnce() {
    final running = _refreshing;
    if (running != null) return running;
    final started = _performRefresh();
    _refreshing = started;
    return started.whenComplete(() => _refreshing = null);
  }

  Future<String?> _performRefresh() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(extra: {kRequiresAuthOptionKey: false}),
      );
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) {
        await _sessionStore.clear();
        return null;
      }
      await _sessionStore.setAccessToken(token);
      return token;
    } on DioException {
      // Cookie absent, expiré ou révoqué : la session est terminée.
      await _sessionStore.clear();
      return null;
    }
  }
}
