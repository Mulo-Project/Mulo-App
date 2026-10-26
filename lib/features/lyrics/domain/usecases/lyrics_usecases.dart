import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/domain/repositories/library_repository.dart';
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
class SaveLyrics implements UseCase<Lyrics?, SaveLyricsParams> {
  const SaveLyrics(this._repo, this._tags);

  final LyricsRepository _repo;
  final TrackTagRepository _tags;

  @override
  Future<Lyrics?> call(SaveLyricsParams p) async {
    final saved = await _repo.save(p.track.id, p.text);
    if (saved != null) {
      try {
        await _tags.writeLyrics(p.track, saved.raw);
      } on Object {
        // 파일 태그는 덤이라 실패해도 저장한 가사는 그대로 둔다.
      }
    }
    return saved;
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

/// 앱에만 저장해 둔 가사를 음원 파일의 가사 태그로 옮기는 일의 결과.
class LyricsFileWriteResult {
  const LyricsFileWriteResult({
    this.written = 0,
    this.alreadyThere = 0,
    this.unsupported = 0,
    this.failed = 0,
  });

  /// 파일 태그에 새로 썼다.
  final int written;

  /// 파일에 같은 가사가 이미 있어 건너뛰었다.
  final int alreadyThere;

  /// 이 곡은 태그를 쓰지 않는 환경 · 형식이라 건너뛰었다 (lite · 데스크톱 · 지원하지 않는 형식 등).
  final int unsupported;

  /// 쓰려 했지만 실패했다 (권한 · 변환 · 덮어쓰기 오류).
  final int failed;

  int get total => written + alreadyThere + unsupported + failed;

  /// 곡이 있었는데 하나도 쓸 수 없었다 (이 기기 · 빌드에서는 지원하지 않는 것으로 본다).
  bool get nothingSupported =>
      total > 0 && written == 0 && alreadyThere == 0 && failed == 0;
}

/// 앱에 저장한 가사가 있는 보관함 곡 (가사 태그로 옮길 대상 후보). 보관함에 없는 곡의 가사는 뺀다.
Future<List<Track>> _tracksWithSavedLyrics(
  LyricsRepository lyrics,
  LibraryRepository library,
) async {
  final ids = await lyrics.savedTrackIds();
  if (ids.isEmpty) return const [];
  final tracks = await library.watchTracks().first;
  return tracks.where((t) => ids.contains(t.id)).toList();
}

/// 앱에 저장한 가사가 있는 곡 수 (확인 대화상자에 보여 줄 대상 수).
class CountSavedLyricsTracks implements UseCase<int, NoParams> {
  const CountSavedLyricsTracks(this._lyrics, this._library);

  final LyricsRepository _lyrics;
  final LibraryRepository _library;

  @override
  Future<int> call(NoParams _) async =>
      (await _tracksWithSavedLyrics(_lyrics, _library)).length;
}

class WriteSavedLyricsToFilesParams {
  const WriteSavedLyricsToFilesParams({this.onProgress});

  /// 곡 하나를 끝낼 때마다 (끝낸 수, 전체 수).
  final void Function(int done, int total)? onProgress;
}

/// 앱에 저장한 가사를 곡마다 음원 파일의 가사 태그에 쓴다 ([SaveLyrics]와 같은 태그 쓰기 경로).
/// 파일에 이미 같은 가사가 있으면 건너뛰고, 태그를 못 쓴 곡은 앱 안 가사를 건드리지 않는다
/// (이 일은 앱 가사를 읽기만 한다). 태그를 쓰지 않는 곡([TagWriteResult.unsupported])은 따로 센다.
class WriteSavedLyricsToFiles
    implements UseCase<LyricsFileWriteResult, WriteSavedLyricsToFilesParams> {
  const WriteSavedLyricsToFiles(
    this._lyrics,
    this._library,
    this._tags,
    this._embedded,
  );

  final LyricsRepository _lyrics;
  final LibraryRepository _library;
  final TrackTagRepository _tags;
  final EmbeddedLyricsSource _embedded;

  @override
  Future<LyricsFileWriteResult> call(WriteSavedLyricsToFilesParams p) async {
    final tracks = await _tracksWithSavedLyrics(_lyrics, _library);
    var written = 0, same = 0, unsupported = 0, failed = 0;
    p.onProgress?.call(0, tracks.length);
    for (final (i, track) in tracks.indexed) {
      switch (await _writeOne(track)) {
        case TagWriteResult.written:
          written++;
        case TagWriteResult.unsupported:
          unsupported++;
        case TagWriteResult.denied || TagWriteResult.failed:
          failed++;
        case null:
          same++;
      }
      p.onProgress?.call(i + 1, tracks.length);
    }
    return LyricsFileWriteResult(
      written: written,
      alreadyThere: same,
      unsupported: unsupported,
      failed: failed,
    );
  }

  /// 이 곡을 처리한다. 파일에 같은 가사가 이미 있으면 null.
  Future<TagWriteResult?> _writeOne(Track track) async {
    try {
      final saved = await _lyrics.loadSaved(track.id);
      if (saved == null) return TagWriteResult.unsupported;
      final inFile = await _embedded.read(track.uri);
      if (inFile != null && _normalize(inFile) == _normalize(saved.raw)) {
        return null;
      }
      return await _tags.writeLyrics(track, saved.raw);
    } on Object {
      return TagWriteResult.failed;
    }
  }

  static String _normalize(String text) =>
      text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
}
