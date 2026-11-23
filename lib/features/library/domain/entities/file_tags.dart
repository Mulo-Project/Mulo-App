/// 음원 파일 태그에서 읽은 곡 정보 (앱이 쓴 태그와 대칭). 없는 칸은 빈 문자열 · null.
class FileTags {
  const FileTags({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.genre = '',
    this.coverColor,
  });

  /// 읽을 수 있는 태그가 하나도 없는 파일 (지원하지 않는 형식 포함).
  static const none = FileTags();

  final String title;
  final String artist;
  final String album;
  final String genre;

  /// `COVER_COLOR`: ARGB 값.
  final int? coverColor;

  bool get isEmpty =>
      title.isEmpty &&
      artist.isEmpty &&
      album.isEmpty &&
      genre.isEmpty &&
      coverColor == null;
}
