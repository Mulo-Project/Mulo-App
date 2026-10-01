/// 앱을 처음 쓴 날 (가입일). 재생 기록 달력은 이 날 이전을 고를 수 없다.
abstract interface class JoinDateRepository {
  /// 처음 부르면 오늘로 저장하고, 그 뒤에는 저장된 날을 돌려준다.
  Future<DateTime> joinedAt();
}
