/// 커버 이미지 · 색을 붙일 대상의 키. 곡 · 앨범 · 아티스트 · 재생목록이 같은 저장소를 쓴다.
/// 앨범은 곡에 저장된 앨범 이름 그대로(빈 문자열 = 알 수 없는 앨범).
abstract final class CoverKey {
  static String track(String id) => 'track:$id';
  static String album(String name) => 'album:$name';

  /// 아티스트도 곡에 저장된 이름 그대로(빈 문자열 = 알 수 없는 아티스트).
  static String artist(String name) => 'artist:$name';

  /// 장르별 기본 색 (받는 곡에 미리 채워진다).
  static String genre(String name) => 'genre:$name';
  static String playlist(String id) => 'playlist:$id';
}
