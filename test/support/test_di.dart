import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/core/di/injection.dart';
import 'package:loveline/core/storage/auth_session_store.dart';
import 'package:loveline/core/storage/current_user_profile.dart';
import 'package:loveline/core/storage/local_preferences_service.dart';
import 'package:loveline/core/storage/secure_storage_service.dart';
import 'package:loveline/features/auth/data/auth_repository.dart';
import 'package:loveline/features/auth/data/mail_app_launcher.dart';
import 'package:loveline/features/auth/data/verification_deep_link_service.dart';
import 'package:loveline/features/auth/domain/auth_exception.dart';
import 'package:loveline/features/auth/domain/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage sécurisé en mémoire : les tests n'ont pas accès au Keystore.
class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<void> write({required String key, required String value}) async => data[key] = value;

  @override
  Future<String?> read({required String key}) async => data[key];

  @override
  Future<void> delete({required String key}) async => data.remove(key);
}

/// Doublure du dépôt d'authentification : ouvre une vraie session dans le magasin,
/// comme le ferait le dépôt réel, pour que le routeur réagisse comme en production.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.store);

  final AuthSessionStore store;

  EmailCheckResult emailCheck = const EmailCheckResult(exists: false, isVerified: false);
  AuthUser socialUser = const AuthUser(
    id: 'social-1',
    email: 'awa@exemple.tg',
    isVerified: true,
    needsIdentity: true,
  );

  AuthException? checkError;
  AuthException? registerError;
  AuthException? loginError;
  AuthException? socialError;
  AuthException? identityError;

  final List<String> loginPasswords = [];
  int registerCalls = 0;
  int resendCalls = 0;
  int saveIdentityCalls = 0;
  int logoutCalls = 0;
  String? lastRegisterPassword;

  @override
  Future<EmailCheckResult> checkEmailExists(String email) async {
    if (checkError != null) throw checkError!;
    return emailCheck;
  }

  @override
  Future<void> resendVerificationEmail(String email) async => resendCalls++;

  @override
  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    registerCalls++;
    lastRegisterPassword = password;
    if (registerError != null) throw registerError!;
  }

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    loginPasswords.add(password);
    if (loginError != null) throw loginError!;
    final user = AuthUser(
      id: 'user-1',
      email: email,
      firstName: 'Awa',
      lastName: 'Koffi',
      isVerified: true,
      needsIdentity: false,
    );
    await store.setSession(accessToken: 'jeton', needsIdentity: false);
    store.setCurrentUser(user.toProfile());
    return user;
  }

  Future<AuthUser> _social() async {
    if (socialError != null) throw socialError!;
    await store.setSession(accessToken: 'jeton', needsIdentity: socialUser.needsIdentity);
    store.setCurrentUser(socialUser.toProfile());
    return socialUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() => _social();

  @override
  Future<AuthUser> signInWithFacebook() => _social();

  @override
  Future<AuthUser> saveIdentity({required String firstName, required String lastName}) async {
    saveIdentityCalls++;
    if (identityError != null) throw identityError!;
    final user = AuthUser(
      id: socialUser.id,
      email: socialUser.email,
      firstName: firstName,
      lastName: lastName,
      isVerified: true,
      needsIdentity: false,
    );
    store.setCurrentUser(user.toProfile());
    await store.markIdentityDone();
    return user;
  }

  @override
  Future<CurrentUserProfile?> getCurrentUser() async => store.currentUser.value;

  @override
  Future<void> logout() async {
    logoutCalls++;
    await store.clear();
  }
}

class FakeMailAppLauncher implements MailAppLauncher {
  bool result = true;
  int calls = 0;

  @override
  Future<bool> openMailApp() async {
    calls++;
    return result;
  }
}

class FakeDeepLinkService implements VerificationDeepLinkService {
  VoidCallback? _onVerified;
  int stopCalls = 0;

  bool get isListening => _onVerified != null;

  /// Simule l'ouverture de `loveline://verified`.
  void simulateVerified() => _onVerified?.call();

  @override
  void startListening({required VoidCallback onVerified}) => _onVerified = onVerified;

  @override
  void stopListening() {
    stopCalls++;
    _onVerified = null;
  }
}

class TestDependencies {
  TestDependencies({
    required this.preferences,
    required this.secureStorage,
    required this.sessionStore,
    required this.repository,
    required this.mailLauncher,
    required this.deepLinks,
  });

  final LocalPreferencesService preferences;
  final InMemorySecureStorage secureStorage;
  final AuthSessionStore sessionStore;
  final FakeAuthRepository repository;
  final FakeMailAppLauncher mailLauncher;
  final FakeDeepLinkService deepLinks;
}

/// Remplace le conteneur d'injection par des doublures, et le vide à la fin du test.
Future<TestDependencies> setUpTestDependencies({bool seenOnboarding = false}) async {
  await getIt.reset();
  SharedPreferences.setMockInitialValues({if (seenOnboarding) 'has_seen_onboarding': true});
  final prefs = LocalPreferencesService(await SharedPreferences.getInstance());
  final secure = InMemorySecureStorage();
  final store = AuthSessionStore(secure);
  final repository = FakeAuthRepository(store);
  final mail = FakeMailAppLauncher();
  final links = FakeDeepLinkService();

  getIt
    ..registerSingleton<LocalPreferencesService>(prefs)
    ..registerSingleton<AuthSessionStore>(store)
    ..registerSingleton<AuthRepository>(repository)
    ..registerSingleton<MailAppLauncher>(mail)
    ..registerSingleton<VerificationDeepLinkService>(links);
  addTearDown(getIt.reset);

  return TestDependencies(
    preferences: prefs,
    secureStorage: secure,
    sessionStore: store,
    repository: repository,
    mailLauncher: mail,
    deepLinks: links,
  );
}
