/// 받기 결과 알림 (끝남 · 실패). 글자는 호출하는 쪽이 정해서 넘긴다.
abstract interface class DownloadNotifier {
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
