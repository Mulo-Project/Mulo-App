/// "다른 앱과 함께 재생" 설정 저장소. 켜면 다른 앱이 소리를 내도 멈추지 않고 같이 들린다.
abstract interface class MixWithOthersRepository {
  Future<bool> load();

  /// 저장하고 재생 엔진에 바로 반영한다.
  Future<void> save(bool value);

  /// 저장된 값을 재생 엔진에 반영한다 (앱 시작 때).
  Future<void> apply(bool value);
}
