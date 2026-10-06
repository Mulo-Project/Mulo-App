/// 받기 알림 (진행 · 결과). 글자는 호출하는 쪽이 정해서 넘긴다.
abstract interface class DownloadNotifier {
  /// 받는 중 알림을 띄우거나 갱신한다. [percent]가 null이면 길이를 모르는 진행 표시.
  /// 받는 동안 앱이 꺼지지 않게 붙들어 두는 알림이다.
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
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
