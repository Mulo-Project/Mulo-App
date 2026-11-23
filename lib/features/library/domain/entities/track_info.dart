/// 사용자가 고칠 수 있는 곡 정보. 아티스트 · 앨범 · 장르는 모르면 빈 문자열.
class TrackInfo {
  const TrackInfo({
    required this.title,
    this.artist = '',
    this.album = '',
    this.genre = '',
  });

  final String title;
  final String artist;
  final String album;
  final String genre;

  /// 각 칸의 앞뒤 공백을 지운 값.
  TrackInfo trimmed() => TrackInfo(
    title: title.trim(),
    artist: artist.trim(),
    album: album.trim(),
    genre: genre.trim(),
  );
}
