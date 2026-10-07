/// 받기 알림에서 누른 조작.
enum DownloadNotificationAction {
  /// 지금 받는 곡을 미리 듣는다 (받기는 그대로 이어진다).
  preview,

  /// 지금 받는 곡의 받기를 취소한다.
  cancel,
}

/// 받기 알림 (진행 · 결과). 글자는 호출하는 쪽이 정해서 넘긴다.
abstract interface class DownloadNotifier {
  /// 알림에서 누른 조작.
  Stream<DownloadNotificationAction> watchActions();

  /// 받는 중 알림을 띄우거나 갱신한다. [percent]가 null이면 길이를 모르는 진행 표시.
  /// [foreground]면 앱이 뒤로 가거나 닫혀도 받기가 이어지게 붙들어 두는 알림이다.
  /// [subText]는 알림 머리말(전체 진행), [previewLabel]이 있으면 미리 듣기 버튼을 단다.
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
    String? cancelLabel,
  });

  /// 받는 중 알림을 치운다.
  Future<void> clearProgress();

  /// 받기가 끝났거나 실패했다는 알림 ([id]가 같으면 덮어쓴다).
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
  });

  /// 받기 결과 알림을 모두 치운다.
  Future<void> clearResults();
}
