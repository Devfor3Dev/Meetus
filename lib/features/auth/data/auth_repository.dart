import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_session_store.dart';
import '../../../core/storage/current_user_profile.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_user.dart';
import 'facebook_token_source.dart';
import 'google_id_token_source.dart';

/// Résultat de `POST /auth/check-email`.
///
/// `isVerified` est indispensable, : un compte qui existe sans
/// être vérifié doit reprendre la vérification de l'e-mail,
class EmailCheckResult {
  const EmailCheckResult({required this.exists, required this.isVerified});

  final bool exists;
  final bool isVerified;
}

/// Point de contact avec les endpoints `/auth/*`,
///
/// Chaque méthode traduit une erreur Dio en [AuthException] avec un message public

@lazySingleton
class AuthRepository {
  AuthRepository(this._dio, this._sessionStore, this._google, this._facebook);

  final Dio _dio;
  final AuthSessionStore _sessionStore;
  final GoogleIdTokenSource _google;
  final FacebookTokenSource _facebook;

  Options get _public => Options(extra: const {kRequiresAuthOptionKey: false});

  /// Indique si un compte existe pour cet e-mail et s'il est vérifié.
  Future<EmailCheckResult> checkEmailExists(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/check-email',
        data: {'email': email},
        options: _public,
      );
      return EmailCheckResult(
        exists: response.data?['exists'] as bool? ?? false,
        isVerified: response.data?['is_verified'] as bool? ?? false,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Bouton « Je n'ai rien reçu ». La réponse du serveur est toujours la même, que
  /// le compte existe ou non.
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/resend-verification',
        data: {'email': email},
        options: _public,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Crée le compte, non vérifié côté serveur. On Ne connecte PAS l'utilisateur encore
  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        },
        options: _public,
      );
    } on DioException catch (error) {
      throw _mapError(error, contextRegister: true);
    }
  }

  /// Connexion par e-mail et mot de passe. Le jeton de renouvellement arrive dans
  /// un cookie HttpOnly
  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: _public,
      );
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) throw AuthException.generic();
      return await _openSession(token);
    } on DioException catch (error) {
      throw _mapError(error, contextLogin: true);
    }
  }

  Future<AuthUser> signInWithGoogle() async {
    final idToken = await _google.fetchIdToken();
    return _signInWithProvider('/auth/google', {'id_token': idToken});
  }

  Future<AuthUser> signInWithFacebook() async {
    final accessToken = await _facebook.fetchAccessToken();
    return _signInWithProvider('/auth/facebook', {'access_token': accessToken});
  }

  /// Enregistre le prénom et le nom d'un compte créé par Google ou Facebook.
  Future<AuthUser> saveIdentity({required String firstName, required String lastName}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {'first_name': firstName, 'last_name': lastName},
      );
      final user = AuthUser.fromJson(response.data ?? const {});
      _sessionStore.setCurrentUser(user.toProfile());
      await _sessionStore.markIdentityDone();
      return user;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Profil de l'utilisateur connecté, mis en cache.
  Future<CurrentUserProfile?> getCurrentUser() async {
    final cached = _sessionStore.currentUser.value;
    if (cached != null) return cached;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final profile = AuthUser.fromJson(response.data ?? const {}).toProfile();
      _sessionStore.setCurrentUser(profile);
      return profile;
    } on DioException {
      return null;
    }
  }

  /// Ferme la session côté serveur, chez Google et Facebook, puis sur l'appareil.
  /// La session locale est effacée même si le serveur est injoignable.
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout', options: _public);
    } on DioException {
      // Hors ligne : la purge locale suffit pour que l'utilisateur sorte.
    }
    await _google.signOut();
    await _facebook.signOut();
    await _sessionStore.clear();
  }

  Future<AuthUser> _signInWithProvider(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body, options: _public);
      final token = response.data?['access_token'] as String?;
      final userJson = response.data?['user'];
      if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
        throw AuthException.generic();
      }
      final user = AuthUser.fromJson(userJson);
      await _sessionStore.setSession(accessToken: token, needsIdentity: user.needsIdentity);
      _sessionStore.setCurrentUser(user.toProfile());
      return user;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Ouvre la session après un login par mot de passe. Le profil est lu avec le
  ///nouveau jeton pour qu'aucune session à moitié ouverte
  /// n'existe si cette lecture échoue.
  Future<AuthUser> _openSession(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: const {kRequiresAuthOptionKey: false},
      ),
    );
    final user = AuthUser.fromJson(response.data ?? const {});
    await _sessionStore.setSession(accessToken: token, needsIdentity: user.needsIdentity);
    _sessionStore.setCurrentUser(user.toProfile());
    return user;
  }

  AuthException _mapError(
    DioException error, {
    bool contextLogin = false,
    bool contextRegister = false,
  }) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AuthException.network();
      default:
        break;
    }

    final status = error.response?.statusCode ?? 0;
    final code = _errorCode(error.response?.data);

    switch (code) {
      case 'email_domain_not_allowed':
        return const AuthException("Utilisez l'adresse e-mail .");
      case 'email_not_verified':
        return const AuthException("Confirmez d'abord votre adresse e-mail.");
      case 'account_exists_other_method':
        return const AuthException(
          "Un compte existe déjà avec cette adresse. Connectez-vous avec l'autre méthode.",
        );
      case 'provider_email_missing':
        return const AuthException(
          "Cette connexion n'a pas fourni d'adresse e-mail. Choisissez un autre moyen.",
        );
      case 'weak_password':
        return const AuthException("Ce mot de passe n'est pas assez solide.");
    }

    if (status == 401 && contextLogin) {
      return const AuthException('E-mail ou mot de passe incorrect.');
    }
    if (status == 401) {
      return const AuthException("La connexion n'a pas pu être confirmée. Réessayez.");
    }
    if (status == 409 && contextRegister) {
      return const AuthException('Un compte existe déjà avec cet e-mail.');
    }
    if (status == 422) {
      return const AuthException('Certaines informations sont invalides. Vérifiez-les et réessayez.');
    }
    if (status == 429) {
      return const AuthException('Trop de tentatives. Réessayez dans quelques minutes.');
    }
    if (status >= 500) {
      return const AuthException('Le service rencontre un problème. Réessayez dans un instant.');
    }
    return AuthException.generic();
  }

  String? _errorCode(Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) return error['code'] as String?;
    }
    return null;
  }
}
