import '../../../../core/usecase/usecase.dart';
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
  const SaveLyricsParams(this.trackId, this.text);

  final String trackId;
  final String text;
}

class SaveLyrics implements UseCase<Lyrics?, SaveLyricsParams> {
  const SaveLyrics(this._repo);

  final LyricsRepository _repo;

  @override
  Future<Lyrics?> call(SaveLyricsParams p) => _repo.save(p.trackId, p.text);
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
