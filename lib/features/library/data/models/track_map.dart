import '../../../../core/database/native_db.dart';
import '../../domain/entities/track.dart';

/// 네이티브 DB가 돌려준 곡 맵을 앱 모델로.
Track trackFromMap(Map<Object?, Object?> m) => Track(
  id: m['id']! as String,
  title: m['title']! as String,
  artist: m['artist']! as String,
  album: m['album']! as String,
  genre: m['genre']! as String,
  duration: Duration(milliseconds: (m['durationMs']! as num).toInt()),
  addedAt: dateOfSec(m['addedAtSec']),
  uri: m['uri']! as String,
  folder: m['folder']! as String,
  source: TrackSource.values.asNameMap()[m['source']] ?? TrackSource.device,
  mime: m['mime']! as String,
);

/// 앱 모델을 네이티브 DB에 넘길 맵으로 (시각은 초 단위).
Map<String, Object?> trackToMap(Track t) => {
  'id': t.id,
  'title': t.title,
  'artist': t.artist,
  'album': t.album,
  'genre': t.genre,
  'durationMs': t.duration.inMilliseconds,
  'uri': t.uri,
  'folder': t.folder,
  'source': t.source.name,
  'addedAtSec': t.addedAt.millisecondsSinceEpoch ~/ 1000,
  'mime': t.mime,
};
