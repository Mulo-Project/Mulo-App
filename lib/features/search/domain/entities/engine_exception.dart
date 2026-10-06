/// 엔진 오류가 난 까닭. 화면은 이것만 보고 안내 문구를 고른다.
enum EngineFailure {
  /// 쓸 수 있는 엔진이 없다 (서버 주소 없음 · yt-dlp 없음).
  unavailable,

  /// 서버에 닿지 못했다.
  network,

  /// 서버가 로그인(토큰)을 요구한다.
  unauthorized,

  /// 찾을 수 없는 주소.
  notFound,

  /// 그 밖의 실패.
  failed,
}

class EngineException implements Exception {
  const EngineException(this.failure, [this.message = '']);

  final EngineFailure failure;
  final String message;

  @override
  String toString() => 'EngineException($failure, $message)';
}
