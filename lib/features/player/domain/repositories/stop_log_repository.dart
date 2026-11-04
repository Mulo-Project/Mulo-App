/// 재생이 멈춘 이유 기록 저장소. 기록은 네이티브 재생 서비스가 남기고, 앱은 읽고 지우기만 한다.
abstract interface class StopLogRepository {
  /// 오래된 것부터 최대 20줄 (`MM-dd HH:mm:ss 이유`). 읽을 수 없으면 빈 목록.
  Future<List<String>> read();

  Future<void> clear();
}
