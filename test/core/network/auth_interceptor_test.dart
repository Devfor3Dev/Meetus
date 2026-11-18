import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/core/network/dio_client.dart';
import 'package:loveline/core/storage/auth_session_store.dart';

import '../../support/test_di.dart';

class _FakeServer implements HttpClientAdapter {
  int refreshCalls = 0;
  bool refreshFails = false;

  ResponseBody _json(Map<String, Object?> body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return refreshFails
          ? _json({'error': {'code': 'invalid_refresh_token'}}, 401)
          : _json({'access_token': 'nouveau'}, 200);
    }
    if (options.headers['Authorization'] == 'Bearer nouveau') {
      return _json({'ok': true}, 200);
    }
    return _json({'error': {'code': 'unauthorized'}}, 401);
  }

  @override
  void close({bool force = false}) {}
}

Future<(Dio, AuthSessionStore, _FakeServer)> _setUp() async {
  final store = AuthSessionStore(InMemorySecureStorage());
  await store.setSession(accessToken: 'ancien', needsIdentity: false);
  final server = _FakeServer();
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = server;
  dio.interceptors.add(AuthInterceptor(dio, store));
  return (dio, store, server);
}

void main() {
  test('un 401 déclenche un renouvellement puis rejoue la requête', () async {
    final (dio, store, server) = await _setUp();

    final response = await dio.get<Map<String, dynamic>>('/protege');

    expect(response.statusCode, 200);
    expect(server.refreshCalls, 1);
    expect(store.accessToken, 'nouveau');
  });

  test('plusieurs requêtes en échec partagent un seul renouvellement', () async {
    final (dio, _, server) = await _setUp();

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/a'),
      dio.get<Map<String, dynamic>>('/b'),
      dio.get<Map<String, dynamic>>('/c'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshCalls, 1);
  });

  test('un renouvellement refusé termine la session', () async {
    final (dio, store, server) = await _setUp();
    server.refreshFails = true;

    await expectLater(dio.get<Map<String, dynamic>>('/protege'), throwsA(isA<DioException>()));

    expect(store.isAuthenticated.value, isFalse);
  });

  test('une requête publique ne déclenche aucun renouvellement', () async {
    final (dio, _, server) = await _setUp();

    await expectLater(
      dio.get<Map<String, dynamic>>(
        '/public',
        options: Options(extra: {kRequiresAuthOptionKey: false}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(server.refreshCalls, 0);
  });
}
