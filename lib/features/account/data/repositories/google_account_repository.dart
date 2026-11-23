import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../subscriptions/domain/entities/channel_hit.dart';
import '../../domain/entities/google_account.dart';
import '../datasources/google_auth_source.dart';
import '../datasources/google_sign_in_auth_source.dart';
import '../datasources/native_google_api.dart';
import '../../domain/repositories/account_repository.dart';

/// 구글 로그인 + YouTube Data API v3 `playlists?mine=true` (읽기 전용). API 읽기는 네이티브([NativeGoogleApi])가 한다.
/// 로그인은 Android의 `google_sign_in`이다. 빌드에 클라이언트 ID가 없으면 쓸 수 없다.
class GoogleAccountRepository implements AccountRepository {
  GoogleAccountRepository({GoogleAuthSource? auth, NativeGoogleApi? api})
    : _auth = auth ?? _platformAuth(),
      _api = api ?? NativeGoogleApi();

  /// 한 번에 50개씩, 많아도 이만큼 쪽까지만 읽는다.
  static const _maxPages = 6;

  /// 구독 채널은 끝까지(nextPageToken이 없을 때까지) 읽는다. 비정상 응답으로 끝나지 않는 일만 막는 안전 상한.
  static const _maxSubscriptionPages = 400;

  final GoogleAuthSource? _auth;
  final NativeGoogleApi _api;

  static GoogleAuthSource? _platformAuth() {
    if (Platform.isAndroid) {
      return AppConfig.hasGoogleClient ? GoogleSignInAuthSource() : null;
    }
    return null;
  }

  @override
  AccountSupport get support => _auth != null
      ? AccountSupport.available
      : Platform.isAndroid
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
  Future<List<PlaylistHit>> myPlaylists() => _playlists({
    'part': 'snippet,contentDetails',
    'mine': 'true',
  });

  @override
  Future<List<ChannelHit>> mySubscriptions({
    void Function(int loaded)? onProgress,
  }) async {
    final items = await _api.list(
      token: await _source.accessToken(),
      kind: 'subscriptions',
      query: {'part': 'snippet', 'mine': 'true', 'order': 'alphabetical'},
      maxPages: _maxSubscriptionPages,
      onProgress: onProgress,
    );
    return [
      for (final m in items)
        ChannelHit(
          id: m['id']! as String,
          name: m['name'] as String? ?? '',
          description: m['description'] as String? ?? '',
          thumbnailUrl: m['thumbnail'] as String?,
        ),
    ];
  }

  @override
  Future<List<PlaylistHit>> channelPlaylists(String channelId) => _playlists({
    'part': 'snippet,contentDetails',
    'channelId': channelId,
  });

  Future<List<PlaylistHit>> _playlists(Map<String, String> query) async {
    final items = await _api.list(
      token: await _source.accessToken(),
      kind: 'playlists',
      query: query,
      maxPages: _maxPages,
    );
    return [
      for (final m in items)
        PlaylistHit(
          id: m['id']! as String,
          title: m['title'] as String? ?? '',
          url: m['url'] as String? ?? '',
          channel: m['channel'] as String? ?? '',
          thumbnailUrl: m['thumbnail'] as String?,
          trackCount: (m['trackCount'] as num?)?.toInt(),
        ),
    ];
  }
}
