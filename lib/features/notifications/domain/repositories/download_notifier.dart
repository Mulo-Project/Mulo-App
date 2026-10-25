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

/// 받기 알림 (진행 · 결과). 글자는 호출하는 쪽이 정해서 넘긴다.
abstract interface class DownloadNotifier {
  /// 알림에서 누른 조작.
  Stream<DownloadNotificationAction> watchActions();

  /// 알림 본문을 눌러 열라는 요청: 그 받기 항목의 id.
  /// 앱이 이미 떠 있을 때 들어온다. 새로 켜진 경우는 [takeOpenRequest]로 받는다.
  Stream<String> watchOpenRequests();

  /// 알림을 눌러 앱이 켜졌다면 눌린 받기 항목의 id (한 번 받으면 비운다), 아니면 null.
  Future<String?> takeOpenRequest();

  /// 받는 중 알림을 띄우거나 갱신한다. [percent]가 null이면 길이를 모르는 진행 표시.
  /// [foreground]면 앱이 뒤로 가거나 닫혀도 받기가 이어지게 붙들어 두는 알림이다.
  /// [openId]는 알림을 누르면 상세 화면을 열 받기 항목의 id, [subText]는 알림 머리말(전체 진행), [previewLabel]이 있으면 미리 듣기 버튼을 단다.
  /// [artUri]는 알림의 큰 아이콘 자리에 보일 곡 이미지(웹 주소 또는 파일 경로, 없으면 null).
  /// 지금 곡을 미리 듣는 중이면 [previewLabel] 대신 [pauseLabel] · [stopLabel] 버튼을 단다.
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
    String? cancelLabel,
    String? holdLabel,
    String? pauseLabel,
    String? stopLabel,
    String? openId,
    String? artUri,
  });

  /// 받는 중 알림을 치운다.
  Future<void> clearProgress();

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
