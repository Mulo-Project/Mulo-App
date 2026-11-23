import '../entities/media_session_info.dart';

/// 재생 알림 · 잠금화면 · 이어폰 버튼.
abstract interface class MediaSession {
  /// 알림 · 잠금화면에서 누른 조작.
  Stream<MediaCommand> watchCommands();

  /// 보여 줄 재생 상태를 갱신한다. null이면 알림을 치운다.
  Future<void> update(MediaSessionInfo? info);

  /// 대기열의 곡별 커버 주소 (곡 id → 주소). 지금 곡이 아닌 곡의 알림 커버로 쓰인다:
  /// 앱이 꺼진 사이 곡이 넘어가도 커버가 나오게 한다. 빈 맵이면 지운다.
  Future<void> updateQueueArt(Map<String, String> artById);
}
