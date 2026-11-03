import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/repositories/track_tag_repository.dart';
import '../entities/lyrics.dart';
import '../repositories/lyrics_repository.dart';

class LoadLyricsParams {
  const LoadLyricsParams(this.trackId, this.trackUri);

  final String trackId;
  final String trackUri;
}

class LoadLyrics implements UseCase<Lyrics?, LoadLyricsParams> {
  const LoadLyrics(this._repo);

  final LyricsRepository _repo;

  @override
  Future<Lyrics?> call(LoadLyricsParams p) => _repo.load(p.trackId, p.trackUri);
}

class SaveLyricsParams {
  const SaveLyricsParams(this.track, this.text);

  final Track track;
  final String text;
}

/// 곡의 가사를 앱에 저장하고, 음원 파일의 가사 태그에도 같이 써 넣는다 (받을 때 가사를 넣는 것과 같게).
/// 파일에 못 써도(권한 · 형식 · 파일 없음) 앱에 저장한 가사는 그대로 쓰인다.
/// 가사를 비워 지울 때는 앱 저장본만 지우고 파일 태그는 그대로 둔다.
/// 가사 저장 결과: 앱에 저장한 가사와, 음원 파일 가사 태그에 쓴 결과 (태그를 쓰려 하지 않았으면 null).
class SavedLyrics {
  const SavedLyrics(this.lyrics, this.tag);

  final Lyrics? lyrics;
  final TagWriteResult? tag;
}

class SaveLyrics implements UseCase<SavedLyrics, SaveLyricsParams> {
  const SaveLyrics(this._repo, this._tags);

  final LyricsRepository _repo;
  final TrackTagRepository _tags;

  @override
  Future<SavedLyrics> call(SaveLyricsParams p) async {
    final saved = await _repo.save(p.track.id, p.text);
    if (saved == null) return const SavedLyrics(null, null);
    try {
      return SavedLyrics(saved, await _tags.writeLyrics(p.track, saved.raw));
    } on Object {
      // 파일 태그는 덤이라 실패해도 저장한 가사는 그대로 둔다.
      return SavedLyrics(saved, TagWriteResult.failed);
    }
  }
}

class ClearLyrics implements UseCase<void, String> {
  const ClearLyrics(this._repo);

  final LyricsRepository _repo;

  @override
  Future<void> call(String trackId) => _repo.remove(trackId);
}

/// 기기에서 가사 파일을 골라 글을 읽는다 (저장은 편집 후 [SaveLyrics]). 취소하면 null.
class PickLyricsFile implements UseCase<String?, NoParams> {
  const PickLyricsFile(this._source);

  final LyricsFileSource _source;

  @override
  Future<String?> call(NoParams _) => _source.pickText();
}
