import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/core/constants/app_assets.dart';
import 'package:loveline/core/storage/auth_session_store.dart';

import '../../support/test_di.dart';

void main() {
  test('restore ne fait rien sans jeton enregistré', () async {
    final store = AuthSessionStore(InMemorySecureStorage());
    await store.restore();
    expect(store.isAuthenticated.value, isFalse);
    expect(store.accessToken, isNull);
  });

  test('une session ouverte est relue au démarrage suivant, sans garder le flux', () async {
    final storage = InMemorySecureStorage();
    await AuthSessionStore(storage).setSession(accessToken: 'jeton', needsIdentity: true);

    final restored = AuthSessionStore(storage);
    await restored.restore();

    expect(restored.isAuthenticated.value, isTrue);
    expect(restored.needsIdentity.value, isTrue);
    expect(restored.holdInFlow.value, isFalse);
    expect(restored.accessToken, 'jeton');
  });

  test('setSession garde l’utilisateur dans le flux jusqu’à releaseFlow', () async {
    final store = AuthSessionStore(InMemorySecureStorage());
    await store.setSession(accessToken: 'jeton', needsIdentity: false);
    expect(store.holdInFlow.value, isTrue);

    store.releaseFlow();
    expect(store.holdInFlow.value, isFalse);
  });

  test('markIdentityDone est conservé au redémarrage', () async {
    final storage = InMemorySecureStorage();
    final store = AuthSessionStore(storage);
    await store.setSession(accessToken: 'jeton', needsIdentity: true);
    await store.markIdentityDone();

    final restored = AuthSessionStore(storage);
    await restored.restore();
    expect(restored.needsIdentity.value, isFalse);
  });

  test('sans indicateur fiable, l’identité est redemandée', () async {
    final storage = InMemorySecureStorage()..data[AppStorageKeys.secureAuthToken] = 'jeton';
    final store = AuthSessionStore(storage);
    await store.restore();
    expect(store.needsIdentity.value, isTrue);
  });

  test('setSession règle l’identité et le flux avant l’état connecté', () async {
    final store = AuthSessionStore(InMemorySecureStorage());
    final seen = <(bool, bool, bool)>[];
    store.isAuthenticated.addListener(
      () => seen.add((
        store.isAuthenticated.value,
        store.needsIdentity.value,
        store.holdInFlow.value,
      )),
    );

    await store.setSession(accessToken: 'jeton', needsIdentity: true);

    expect(seen, [(true, true, true)]);
  });

  test('clear efface le jeton, les indicateurs et le profil', () async {
    final storage = InMemorySecureStorage();
    final store = AuthSessionStore(storage);
    await store.setSession(accessToken: 'jeton', needsIdentity: false);

    await store.clear();

    expect(store.isAuthenticated.value, isFalse);
    expect(store.holdInFlow.value, isFalse);
    expect(store.accessToken, isNull);
    expect(storage.data, isEmpty);
  });
}
