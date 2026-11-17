/// 영상 파일로 저장하기. 받기 · 합치기 · 태그 · 저장은 모두 받기 큐(네이티브 `DownloadEngine`)가 하므로,
/// 앱은 요청을 큐에 넣을 뿐이고 여기서는 이 빌드 · 기기가 영상 저장을 지원하는지만 묻는다.
abstract interface class VideoSaveRepository {
  /// 이 빌드 · 기기에서 영상 파일을 저장할 수 있는지 (Android full 빌드만).
  Future<bool> isAvailable();
}
