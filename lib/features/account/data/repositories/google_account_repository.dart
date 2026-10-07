import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../domain/entities/google_account.dart';
import '../datasources/google_auth_source.dart';
import '../datasources/google_sign_in_auth_source.dart';
import '../datasources/loopback_google_auth.dart';
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

/// 구글 로그인 + YouTube Data API v3 `playlists?mine=true` (읽기 전용).
/// 로그인 방식은 기기에 따라 다르다: Android는 `google_sign_in`, 데스크톱은 브라우저
/// 로그인([LoopbackGoogleAuth]). 빌드에 해당 클라이언트 ID가 없으면 쓸 수 없다.
class GoogleAccountRepository implements AccountRepository {
  GoogleAccountRepository({GoogleAuthSource? auth, AccountHttpGet? get})
    : _auth = auth ?? _platformAuth(),
      _get = get ?? _defaultGet;

  /// 한 번에 50개씩, 많아도 이만큼 쪽까지만 읽는다.
  static const _maxPages = 6;

  final GoogleAuthSource? _auth;
  final AccountHttpGet _get;

  static GoogleAuthSource? _platformAuth() {
    if (Platform.isAndroid) {
      return AppConfig.hasGoogleClient ? GoogleSignInAuthSource() : null;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return AppConfig.hasGoogleDesktopClient ? LoopbackGoogleAuth() : null;
    }
    return null;
  }

  @override
  AccountSupport get support => _auth != null
      ? AccountSupport.available
      : Platform.isAndroid ||
            Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS
      ? AccountSupport.notConfigured
      : AccountSupport.unsupportedPlatform;

  GoogleAuthSource get _source =>
      _auth ?? (throw const AccountException(AccountFailure.unsupported));

  @override
  Future<GoogleAccount?> restore() async => _auth?.restore();

  @override
  Future<GoogleAccount> signIn() => _source.signIn();

  @override
  Future<void> signOut() async => _auth?.signOut();

  @override
  Future<List<PlaylistHit>> myPlaylists() async {
    final token = await _source.accessToken();
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
    // 유튜브 채널이 없는 구글 계정은 `mine=true`에 404(channelNotFound)가 온다.
    if (res.status == 404) {
      throw AccountException(AccountFailure.noChannel, _errorDetail(res.body));
    }
    if (res.status < 200 || res.status >= 300) {
      final detail = '${res.status} ${_errorDetail(res.body)}'.trim();
      // API를 켜지 않았거나 할당량 문제인 403은 로그인이 풀린 것이 아니다.
      final notAuth =
          res.status == 401 ||
          (res.status == 403 &&
              !RegExp(
                'accessNotConfigured|SERVICE_DISABLED|has not been used|quota',
                caseSensitive: false,
              ).hasMatch(res.body));
      throw AccountException(
        notAuth ? AccountFailure.unauthorized : AccountFailure.failed,
        detail,
      );
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

/// 구글 API 오류 본문에서 사람이 읽을 한 줄을 뽑는다 (없으면 빈 문자열).
String _errorDetail(String body) {
  try {
    final error = (jsonDecode(body) as Map)['error'];
    if (error is Map) {
      final reason =
          error['errors'] is List && (error['errors'] as List).isNotEmpty
          ? ((error['errors'] as List).first as Map)['reason']
          : error['status'];
      return '${reason ?? ''} ${error['message'] ?? ''}'.trim();
    }
  } on Object {
    // 본문이 JSON이 아니면 그대로 쓰지 않는다.
  }
  return '';
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
