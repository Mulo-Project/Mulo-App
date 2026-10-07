import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/data/datasources/loopback_google_auth.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';

class _MemoryStore implements AuthStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// 브라우저가 돌아오는 것을 흉내 낸다: 로그인 주소의 redirect_uri로 [query]를 붙여 요청한다.
OpenBrowser _browser(Map<String, String> Function(Uri auth) query) =>
    (uri) async {
      final redirect = Uri.parse(uri.queryParameters['redirect_uri']!);
      final back = redirect.replace(queryParameters: query(uri));
      final client = HttpClient();
      try {
        final res = await (await client.getUrl(back)).close();
        await res.drain<void>();
      } finally {
        client.close(force: true);
      }
      return true;
    };

void main() {
  late _MemoryStore store;
  late List<(Uri, Map<String, String>?)> requests;

  AuthRequest request({int tokenStatus = 200, String tokenBody = ''}) =>
      (uri, {form, headers = const {}}) async {
        requests.add((uri, form));
        if (uri.path == '/token') {
          return (
            status: tokenStatus,
            body: tokenBody.isEmpty
                ? jsonEncode({
                    'access_token': 'access-1',
                    'expires_in': 3600,
                    'refresh_token': 'refresh-1',
                  })
                : tokenBody,
          );
        }
        if (uri.path.endsWith('/userinfo')) {
          expect(headers['Authorization'], 'Bearer access-1');
          return (
            status: 200,
            body: jsonEncode({
              'sub': 'u1',
              'email': 'me@example.com',
              'name': '나',
              'picture': 'pic',
            }),
          );
        }
        return (status: 200, body: '{}');
      };

  LoopbackGoogleAuth auth(OpenBrowser open, {AuthRequest? req}) =>
      LoopbackGoogleAuth(
        clientId: 'cid',
        clientSecret: 'secret',
        request: req ?? request(),
        openBrowser: open,
        store: store,
        timeout: const Duration(seconds: 5),
      );

  setUp(() {
    store = _MemoryStore();
    requests = [];
  });

  test('브라우저가 돌려준 코드로 로그인하고 새로고침 토큰만 저장한다', () async {
    late Uri authUri;
    final source = auth(
      _browser((uri) {
        authUri = uri;
        return {'code': 'the-code', 'state': uri.queryParameters['state']!};
      }),
    );
    final account = await source.signIn();

    expect(account.email, 'me@example.com');
    expect(authUri.queryParameters['code_challenge_method'], 'S256');
    expect(authUri.queryParameters['scope'], contains('youtube.readonly'));
    final grant = requests.firstWhere((r) => r.$1.path == '/token').$2!;
    expect(grant['code'], 'the-code');
    expect(grant['code_verifier'], isNotEmpty);
    expect(grant['client_secret'], 'secret');
    expect(store.values['account.google.refreshToken'], 'refresh-1');
    expect(await source.accessToken(), 'access-1');

    // 다시 열면 저장된 계정을 되살린다.
    final again = auth(_browser((_) => {}));
    expect((await again.restore())?.email, 'me@example.com');
  });

  test('로그인 창에서 거절하면 취소로 알린다', () async {
    final source = auth(
      _browser(
        (uri) => {
          'error': 'access_denied',
          'state': uri.queryParameters['state']!,
        },
      ),
    );
    await expectLater(
      source.signIn(),
      throwsA(
        isA<AccountException>().having(
          (e) => e.failure,
          'failure',
          AccountFailure.cancelled,
        ),
      ),
    );
  });

  test('새로고침 토큰이 취소됐으면 저장한 로그인을 지우고 다시 로그인하라고 알린다', () async {
    store.values['account.google.refreshToken'] = 'old';
    store.values['account.google.profile'] = '{}';
    final source = auth(
      _browser((_) => {}),
      req: request(tokenStatus: 400, tokenBody: '{"error":"invalid_grant"}'),
    );
    await expectLater(
      source.accessToken(),
      throwsA(
        isA<AccountException>().having(
          (e) => e.failure,
          'failure',
          AccountFailure.unauthorized,
        ),
      ),
    );
    expect(store.values, isEmpty);
  });

  test('로그아웃하면 저장한 토큰을 지운다', () async {
    store.values['account.google.refreshToken'] = 'r';
    await auth(_browser((_) => {})).signOut();
    expect(store.values, isEmpty);
    expect(requests.any((r) => r.$1.path == '/revoke'), isTrue);
  });
}
