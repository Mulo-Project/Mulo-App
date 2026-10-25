import 'track.dart';
import 'track_info.dart';

/// 곡을 묶는 기준: 아티스트 · 앨범 · 장르. 셋은 곡의 정보(태그)일 뿐이라 이름이 같은 곡들의 묶음이다.
enum TrackGroupKind {
  artist,
  album,
  genre;

  /// [t]가 이 묶음 [name]에 속하는가. 이름이 빈 문자열이면 "모르는" 묶음이다.
  bool contains(Track t, String name) => switch (this) {
    TrackGroupKind.artist => t.artist == name,
    TrackGroupKind.album => t.album == name,
    TrackGroupKind.genre => t.genre.trim() == name,
  };

  /// [t]의 정보에서 이 묶음의 값만 [name]으로 바꾼 정보.
  TrackInfo rename(Track t, String name) => TrackInfo(
    title: t.title,
    artist: this == TrackGroupKind.artist ? name : t.artist,
    album: this == TrackGroupKind.album ? name : t.album,
    genre: this == TrackGroupKind.genre ? name : t.genre,
  );
}
