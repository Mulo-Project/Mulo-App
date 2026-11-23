import '../../../search/domain/entities/media_info.dart';
import '../../../subscriptions/domain/entities/channel_hit.dart';
import '../entities/google_account.dart';

/// 구글 계정 로그인과 그 계정의 유튜브 재생목록 (읽기 전용).
///
/// 실패는 [AccountException]으로 던진다.
abstract interface class AccountRepository {
  AccountSupport get support;

  /// 이전에 로그인한 계정이 있으면 조용히 되살린다. 없으면 null.
  Future<GoogleAccount?> restore();

  /// 구글 로그인 창을 띄워 로그인한다 (유튜브 읽기 권한 포함).
  Future<GoogleAccount> signIn();

  Future<void> signOut();

  /// 로그인한 계정의 유튜브 재생목록들.
  Future<List<PlaylistHit>> myPlaylists();

  /// 로그인한 계정이 구독한 유튜브 채널들 (이름순, 개수 제한 없이 끝까지).
  /// 쪽마다 지금까지 읽은 개수를 [onProgress]로 알린다.
  Future<List<ChannelHit>> mySubscriptions({
    void Function(int loaded)? onProgress,
  });

  /// 채널 [channelId]가 공개한 재생목록들 (업로드 목록은 들어 있지 않다).
  Future<List<PlaylistHit>> channelPlaylists(String channelId);
}
