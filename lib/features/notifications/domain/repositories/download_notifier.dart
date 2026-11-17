/// 받기 알림에서 누른 조작.
enum DownloadNotificationAction {
  /// 지금 받는 곡을 미리 듣는다 (받기는 그대로 이어진다).
  preview,

  /// 미리 듣는 중인 곡을 일시정지하거나 이어 듣는다.
  pausePreview,

  /// 미리 듣기를 멈춘다.
  stopPreview,

  /// 지금 받는 곡의 받기를 일시정지하거나 이어 받는다.
  toggleHold,

  /// 지금 받는 곡의 받기를 취소한다.
  cancel,
}

/// 받기 알림. 받기 큐 알림(진행 · 결과)은 네이티브가 띄우고, 여기서는 그 글과 설정을 넘기고 눌린 버튼을 받는다.
/// [showResult]는 저장한 음원 등 큐 밖의 완료 알림에 쓴다.
abstract interface class DownloadNotifier {
  /// 알림에서 누른 조작.
  Stream<DownloadNotificationAction> watchActions();

  /// 알림 본문을 눌러 열라는 요청: 그 받기 항목의 id.
  /// 앱이 이미 떠 있을 때 들어온다. 새로 켜진 경우는 [takeOpenRequest]로 받는다.
  Stream<String> watchOpenRequests();

  /// 알림을 눌러 앱이 켜졌다면 눌린 받기 항목의 id (한 번 받으면 비운다), 아니면 null.
  Future<String?> takeOpenRequest();

  /// 받기 알림에 쓸 글과 설정을 네이티브에 넘긴다. 받기 큐와 그 알림(진행 · 결과 · 다시 시도)은 네이티브가 만들어서
  /// 앱이 꺼져 있어도 뜨므로, 글(`config`)을 미리 알려 둔다.
  Future<void> configureDownloads(Map<String, Object?> config);

  /// 이 곡을 미리 듣는 중이다 (받기 알림의 버튼이 미리 듣기 중지로 바뀐다). 없으면 null.
  Future<void> setDownloadPreviewing(String? id);

  /// 받기가 끝났거나 실패했다는 알림 ([id]가 같으면 덮어쓴다).
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
    String? artUri,
  });

  /// 받기 결과 알림을 모두 치운다.
  Future<void> clearResults();
}
