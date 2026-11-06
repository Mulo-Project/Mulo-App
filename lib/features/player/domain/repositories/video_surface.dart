import '../entities/video_surface_info.dart';

/// 영상 화면: 소리와 영상은 네이티브 플레이어가 한 시계로 다루고, 앱은 그 화면(텍스처)을 그리기만 한다.
/// 미니 플레이어 · 상세 화면 · 플레이어가 같은 화면을 나눠 쓴다.
abstract interface class VideoSurface {
  /// 영상을 보려 한다. 영상 화면의 지금 상태를 돌려준다. 이 기기가 지원하지 않으면 null.
  Future<VideoSurfaceInfo?> attach();

  /// 영상을 더는 안 본다 (영상 해독을 끈다, 소리는 그대로).
  Future<void> detach();

  /// 영상 화면이 바뀔 때마다 (크기 · 첫 화면 그려짐).
  Stream<VideoSurfaceEvent> watch();
}
