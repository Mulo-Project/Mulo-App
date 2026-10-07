import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../domain/entities/google_account.dart';
import '../../domain/repositories/account_repository.dart';

/// GET 요청 하나 (테스트에서 바꿔 끼운다).
typedef AccountHttpGet = Future<({int status, String body})> Function(
  Uri uri,
  Map<String, String> headers,
);

Future<({int status, String body})> _defaultGet(
  Uri uri,
  Map<String, String> headers,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 30));
    final body = await res.transform(utf8.decoder).join();
    return (status: res.statusCode, body: body);
  } finally {
    client.close(force: true);
  }
}

/// 구글 로그인(`google_sign_in`)과 YouTube Data API v3 `playlists?mine=true`.
/// Android만 지원한다. 로그인은 서버 클라이언트 ID가 빌드에 있어야 한다.
class GoogleAccountRepository implements AccountRepository {
  GoogleAccountRepository({GoogleSignIn? signIn, AccountHttpGet? get})
    : _google = signIn ?? GoogleSignIn.instance,
      _get = get ?? _defaultGet;

  static const _scopes = ['https://www.googleapis.com/auth/youtube.readonly'];

  /// 한 번에 50개씩, 많아도 이만큼 쪽까지만 읽는다.
  static const _maxPages = 6;

  final GoogleSignIn _google;
  final AccountHttpGet _get;
  Future<void>? _init;
  GoogleSignInAccount? _account;

  @override
  AccountSupport get support => !Platform.isAndroid
      ? AccountSupport.unsupportedPlatform
      : !AppConfig.hasGoogleClient
      ? AccountSupport.notConfigured
      : AccountSupport.available;

  Future<void> _ready() {
    if (support != AccountSupport.available) {
      throw const AccountException(AccountFailure.unsupported);
    }
    return _init ??= _google.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
  }

  GoogleAccount _map(GoogleSignInAccount a) => GoogleAccount(
    id: a.id,
    email: a.email,
    displayName: a.displayName,
    photoUrl: a.photoUrl,
  );

  @override
  Future<GoogleAccount?> restore() async {
    if (support != AccountSupport.available) return null;
    try {
      await _ready();
      final a =
          await (_google.attemptLightweightAuthentication() ??
              Future<GoogleSignInAccount?>.value());
      _account = a;
      return a == null ? null : _map(a);
    } on Object {
      // 되살리지 못하면 로그아웃 상태로 둔다 (설정에서 다시 로그인).
      return null;
    }
  }

  @override
  Future<GoogleAccount> signIn() async {
    await _ready();
    try {
      final a = await _google.authenticate(scopeHint: _scopes);
      _account = a;
      return _map(a);
    } on GoogleSignInException catch (e) {
      throw AccountException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable => AccountFailure.cancelled,
        _ => AccountFailure.failed,
      }, '${e.code}');
    }
  }

  @override
  Future<void> signOut() async {
    _account = null;
    if (support != AccountSupport.available) return;
    await _ready();
    await _google.signOut();
  }

  /// 유튜브 읽기 권한이 든 접근 토큰. 이미 허락했으면 조용히, 아니면 허락 창을 띄운다.
  Future<String> _token() async {
    final account = _account;
    if (account == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    try {
      final client = account.authorizationClient;
      final auth =
          await client.authorizationForScopes(_scopes) ??
          await client.authorizeScopes(_scopes);
      return auth.accessToken;
    } on GoogleSignInException catch (e) {
      throw AccountException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AccountFailure.cancelled
            : AccountFailure.unauthorized,
        '${e.code}',
      );
    }
  }

  @override
  Future<List<PlaylistHit>> myPlaylists() async {
    final token = await _token();
    final out = <PlaylistHit>[];
    String? pageToken;
    for (var i = 0; i < _maxPages; i++) {
      final json = await _getJson(token, pageToken);
      for (final item in (json['items'] as List? ?? const [])) {
        final hit = item is Map<String, dynamic> ? parsePlaylist(item) : null;
        if (hit != null) out.add(hit);
      }
      pageToken = json['nextPageToken'] as String?;
      if (pageToken == null) break;
    }
    return out;
  }

  Future<Map<String, dynamic>> _getJson(String token, String? pageToken) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlists', {
      'part': 'snippet,contentDetails',
      'mine': 'true',
      'maxResults': '50',
      'pageToken': ?pageToken,
    });
    final ({int status, String body}) res;
    try {
      res = await _get(uri, {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
    } on SocketException catch (e) {
      throw AccountException(AccountFailure.network, e.message);
    } on TimeoutException {
      throw const AccountException(AccountFailure.network, 'timeout');
    } on HttpException catch (e) {
      throw AccountException(AccountFailure.network, e.message);
    }
    if (res.status == 401 || res.status == 403) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    if (res.status < 200 || res.status >= 300) {
      throw AccountException(AccountFailure.failed, '${res.status}');
    }
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw const AccountException(AccountFailure.failed, 'bad response');
    } on TypeError {
      throw const AccountException(AccountFailure.failed, 'bad response');
    }
  }
}

/// YouTube Data API `playlists` 항목 하나를 재생목록 결과로 (id가 없으면 null).
PlaylistHit? parsePlaylist(Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String || id.isEmpty) return null;
  final snippet = item['snippet'];
  final s = snippet is Map ? snippet : const {};
  final details = item['contentDetails'];
  final count = details is Map ? details['itemCount'] : null;
  final thumbs = s['thumbnails'];
  String? thumb;
  if (thumbs is Map) {
    for (final key in const ['medium', 'high', 'default', 'standard']) {
      final t = thumbs[key];
      if (t is Map && t['url'] is String) {
        thumb = t['url'] as String;
        break;
      }
    }
  }
  return PlaylistHit(
    id: id,
    title: s['title'] as String? ?? '',
    url: 'https://www.youtube.com/playlist?list=$id',
    channel: s['channelTitle'] as String? ?? '',
    thumbnailUrl: thumb,
    trackCount: count is num ? count.round() : null,
  );
}
