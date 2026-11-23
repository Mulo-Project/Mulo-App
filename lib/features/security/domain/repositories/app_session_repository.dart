/// 앱 화면이 새로 열린 것을 알려 준다.
abstract interface class AppSessionRepository {
  /// 화면을 밀어 닫았다가 다시 켜서(엔진은 살아 있어 앱 상태가 그대로일 때) 화면이 새로 열렸다.
  Stream<void> watchRelaunch();
}
