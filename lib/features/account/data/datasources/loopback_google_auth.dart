import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/google_account.dart';
import 'google_auth_source.dart';

/// 요청 하나: 상태 코드와 본문 (테스트에서 바꿔 끼운다). [form]이 있으면 POST.
typedef AuthRequest = Future<({int status, String body})> Function(
  Uri uri, {
  Map<String, String>? form,
  Map<String, String> headers,
});

/// 로그인 주소를 기본 브라우저로 연다 (테스트에서 바꿔 끼운다).
typedef OpenBrowser = Future<bool> Function(Uri uri);

/// 보안 저장소의 문자열 하나 (테스트에서 바꿔 끼운다).
abstract interface class AuthStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAuthStore implements AuthStore {
  const SecureAuthStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

Future<({int status, String body})> _defaultRequest(
  Uri uri, {
  Map<String, String>? form,
  Map<String, String> headers = const {},
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = form == null
        ? await client.getUrl(uri)
        : await client.postUrl(uri);
    headers.forEach(req.headers.set);
    if (form != null) {
      req.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      req.write(Uri(queryParameters: form).query);
    }
    final res = await req.close().timeout(const Duration(seconds: 30));
    return (
      status: res.statusCode,
      body: await res.transform(utf8.decoder).join(),
    );
  } finally {
    client.close(force: true);
  }
}

Future<bool> _defaultOpen(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}

/// 데스크톱: 기본 브라우저로 구글 로그인을 열고, 이 기기(127.0.0.1)의 임시 포트로
/// 돌아오는 인증 코드를 받는다 (OAuth 2.0 "데스크톱 앱" 흐름 + PKCE).
/// 새로고침 토큰만 보안 저장소에 두고, 접근 토큰은 메모리에만 둔다.
class LoopbackGoogleAuth implements GoogleAuthSource {
  LoopbackGoogleAuth({
    String? clientId,
    String? clientSecret,
    AuthRequest? request,
    OpenBrowser? openBrowser,
    AuthStore? store,
    this.timeout = const Duration(minutes: 3),
  }) : _clientId = clientId ?? AppConfig.googleDesktopClientId,
       _clientSecret = clientSecret ?? AppConfig.googleDesktopClientSecret,
       _request = request ?? _defaultRequest,
       _open = openBrowser ?? _defaultOpen,
       _store = store ?? const SecureAuthStore();

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _revokeEndpoint = 'https://oauth2.googleapis.com/revoke';
  static const _userInfoEndpoint =
      'https://openidconnect.googleapis.com/v1/userinfo';
  static const _scope = 'openid email profile $youtubeReadonlyScope';
  static const _refreshKey = 'account.google.refreshToken';
  static const _accountKey = 'account.google.profile';

  final String _clientId;
  final String _clientSecret;
  final AuthRequest _request;
  final OpenBrowser _open;
  final AuthStore _store;

  /// 브라우저에서 로그인을 마칠 때까지 기다리는 시간.
  final Duration timeout;

  String? _accessToken;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<GoogleAccount?> restore() async {
    try {
      if (await _store.read(_refreshKey) == null) return null;
      final raw = await _store.read(_accountKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return GoogleAccount(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['name'] as String?,
        photoUrl: j['photo'] as String?,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<GoogleAccount> signIn() async {
    final verifier = _random(64);
    final state = _random(24);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final redirect = 'http://127.0.0.1:${server.port}';
      final authUri = Uri.parse(_authEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'scope': _scope,
          'state': state,
          'code_challenge': base64Url
              .encode(sha256.convert(utf8.encode(verifier)).bytes)
              .replaceAll('=', ''),
          'code_challenge_method': 'S256',
          // 새로고침 토큰을 받으려고 매번 동의 화면을 거친다.
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      final code = _waitForCode(server, state);
      if (!await _open(authUri)) {
        code.ignore();
        throw const AccountException(AccountFailure.failed, 'browser');
      }
      await _tokenGrant({
        'grant_type': 'authorization_code',
        'code': await code,
        'code_verifier': verifier,
        'redirect_uri': redirect,
      });
      final account = await _profile();
      await _store.write(
        _accountKey,
        jsonEncode({
          'id': account.id,
          'email': account.email,
          'name': account.displayName,
          'photo': account.photoUrl,
        }),
      );
      return account;
    } finally {
      await server.close(force: true);
    }
  }

  /// 브라우저가 돌아오는 요청에서 인증 코드를 꺼내고, 사용자에게 안내 쪽을 보여 준다.
  Future<String> _waitForCode(HttpServer server, String state) async {
    final done = Completer<String>();
    final sub = server.listen((req) async {
      final q = req.uri.queryParameters;
      final ok = q['state'] == state && q['code'] != null;
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(
          '<!doctype html><meta charset="utf-8"><title>Mulo</title>'
          '<body style="font-family:sans-serif;text-align:center;margin-top:20vh">'
          '${ok ? '로그인했어요. 이 창을 닫고 앱으로 돌아가세요.' : '로그인하지 못했어요. 앱에서 다시 시도해 주세요.'}',
        );
      await req.response.close();
      if (done.isCompleted) return;
      if (ok) {
        done.complete(q['code']);
      } else if (q.containsKey('error') || q['state'] != null) {
        done.completeError(
          AccountException(
            q['error'] == 'access_denied'
                ? AccountFailure.cancelled
                : AccountFailure.failed,
            q['error'] ?? 'state',
          ),
        );
      }
    });
    try {
      return await done.future.timeout(
        timeout,
        onTimeout: () =>
            throw const AccountException(AccountFailure.cancelled, 'timeout'),
      );
    } finally {
      await sub.cancel();
    }
  }

  /// 토큰 요청 하나. 접근 토큰 · (있으면) 새로고침 토큰을 기억한다.
  Future<void> _tokenGrant(Map<String, String> form) async {
    final res = await _send(
      Uri.parse(_tokenEndpoint),
      form: {...form, 'client_id': _clientId, 'client_secret': _clientSecret},
    );
    final j = _json(res.body);
    final token = j['access_token'];
    if (res.status < 200 || res.status >= 300 || token is! String) {
      // 새로고침 토큰이 취소됐거나 만료된 경우.
      final invalid = j['error'] == 'invalid_grant';
      if (invalid) await _forget();
      throw AccountException(
        invalid ? AccountFailure.unauthorized : AccountFailure.failed,
        '${j['error'] ?? res.status}',
      );
    }
    _accessToken = token;
    final seconds = j['expires_in'];
    _expiresAt = DateTime.now().add(
      Duration(seconds: seconds is num ? seconds.round() : 3000),
    );
    final refresh = j['refresh_token'];
    if (refresh is String && refresh.isNotEmpty) {
      await _store.write(_refreshKey, refresh);
    }
  }

  Future<GoogleAccount> _profile() async {
    final res = await _send(
      Uri.parse(_userInfoEndpoint),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    final j = _json(res.body);
    final id = j['sub'];
    final email = j['email'];
    if (res.status != 200 || id is! String || email is! String) {
      throw AccountException(AccountFailure.failed, 'userinfo ${res.status}');
    }
    return GoogleAccount(
      id: id,
      email: email,
      displayName: j['name'] as String?,
      photoUrl: j['picture'] as String?,
    );
  }

  @override
  Future<String> accessToken() async {
    final cached = _accessToken;
    if (cached != null &&
        DateTime.now().isBefore(
          _expiresAt.subtract(const Duration(minutes: 1)),
        )) {
      return cached;
    }
    final refresh = await _store.read(_refreshKey);
    if (refresh == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    await _tokenGrant({
      'grant_type': 'refresh_token',
      'refresh_token': refresh,
    });
    return _accessToken!;
  }

  @override
  Future<void> signOut() async {
    final token = await _store.read(_refreshKey);
    await _forget();
    if (token == null) return;
    try {
      // 구글 쪽 허락도 거둔다. 실패해도 이 기기에서는 이미 로그아웃이다.
      await _send(Uri.parse(_revokeEndpoint), form: {'token': token});
    } on Object {
      // 무시.
    }
  }

  Future<void> _forget() async {
    _accessToken = null;
    await _store.delete(_refreshKey);
    await _store.delete(_accountKey);
  }

  Future<({int status, String body})> _send(
    Uri uri, {
    Map<String, String>? form,
    Map<String, String> headers = const {},
  }) async {
    try {
      return await _request(uri, form: form, headers: headers);
    } on SocketException catch (e) {
      throw AccountException(AccountFailure.network, e.message);
    } on TimeoutException {
      throw const AccountException(AccountFailure.timeout, 'timeout');
    } on HttpException catch (e) {
      throw AccountException(AccountFailure.network, e.message);
    }
  }

  Map<String, dynamic> _json(String body) {
    try {
      final j = jsonDecode(body);
      return j is Map<String, dynamic> ? j : const {};
    } on FormatException {
      return const {};
    }
  }

  String _random(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
