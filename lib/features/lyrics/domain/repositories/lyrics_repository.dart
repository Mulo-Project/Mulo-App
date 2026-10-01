import '../entities/lyrics.dart';

/// 곡별 가사 저장소: 앱 폴더 `lyrics/<곡 id>.lrc` (싱크) 또는 `.txt` (일반 글) + DB 경로.
abstract interface class LyricsRepository {
  /// 곡의 가사. 직접 저장한 가사가 먼저, 없으면 음원 파일 옆의 같은 이름 `.lrc`.
  /// 둘 다 없으면 null. [trackUri]는 재생 주소 (파일 경로가 아니면 옆 파일은 찾지 않는다).
  Future<Lyrics?> load(String trackId, String trackUri);

  /// [text]를 곡의 가사로 저장한다. 내용이 비면 가사를 지우고 null.
  Future<Lyrics?> save(String trackId, String text);

  Future<void> remove(String trackId);
}

/// 기기에서 가사 파일(.lrc · .txt) 하나를 골라 글을 읽는다.
abstract interface class LyricsFileSource {
  /// 고른 파일의 글. 취소하면 null.
  Future<String?> pickText();
}
