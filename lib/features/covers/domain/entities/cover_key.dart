/// 커버 이미지를 붙일 대상의 키. 곡 · 재생목록이 같은 저장소를 쓴다.
abstract final class CoverKey {
  static String track(String id) => 'track:$id';
  static String playlist(String id) => 'playlist:$id';
}
