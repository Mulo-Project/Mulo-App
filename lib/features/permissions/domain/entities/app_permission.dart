/// 앱이 쓰는 권한.
enum AppPermission {
  /// 알림 (받기 진행 · 재생 알림). 받기가 뒤에서 이어지려면 필요하다 (포그라운드 서비스).
  notifications,

  /// 기기 음악 파일 읽기 (기기 음악 불러오기).
  audio,
}

/// 권한 상태.
enum PermissionLevel {
  granted,

  /// 아직 허용하지 않았다. 앱 안에서 요청 창을 띄울 수 있다.
  denied,

  /// 다시 묻지 않음으로 막혔다. 휴대폰 설정에서만 바꿀 수 있다.
  blocked,
}
