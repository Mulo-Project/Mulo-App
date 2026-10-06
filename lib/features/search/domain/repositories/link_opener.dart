/// 주소를 이 기기의 기본 앱 · 브라우저로 여는 일.
abstract interface class LinkOpener {
  /// 열었으면 true, 열 수 없는 주소이거나 열 앱이 없으면 false.
  Future<bool> open(String url);
}
