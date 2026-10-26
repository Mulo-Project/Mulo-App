import '../../../../core/usecase/usecase.dart';
import '../entities/audio_language.dart';
import '../entities/audio_stream.dart';
import '../entities/engine_exception.dart';
import '../entities/media_info.dart';
import '../entities/subtitle_track.dart';
import '../entities/preview_progress.dart';
import '../entities/preview_snapshot.dart';
import '../entities/search_source.dart';
import '../repositories/downloader_engine.dart';
import '../repositories/link_opener.dart';
import '../repositories/preview_player.dart';

class SearchParams {
  const SearchParams(
    this.query,
    this.source, {
    this.page = 0,
    this.newest = false,
  });

  final String query;
  final SearchSource source;
  final int page;

  /// 올린 날 최신 순으로 찾을지.
  final bool newest;
}

/// 키워드로 찾기 (상세 기능: 키워드 검색 #2).
class SearchTracks implements UseCase<SearchPage, SearchParams> {
  const SearchTracks(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<SearchPage> call(SearchParams p) => _engine.search(
    p.query.trim(),
    source: p.source,
    page: p.page,
    newest: p.newest,
  );
}

class PlaylistSearchParams {
  const PlaylistSearchParams(this.query, {this.page = 0});

  final String query;
  final int page;
}

/// 키워드로 유튜브 재생목록 찾기 (상세 기능: 유튜브 재생목록 가져오기 #22).
class SearchPlaylists
    implements UseCase<PlaylistSearchPage, PlaylistSearchParams> {
  const SearchPlaylists(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<PlaylistSearchPage> call(PlaylistSearchParams p) =>
      _engine.searchPlaylists(p.query.trim(), page: p.page);
}

/// URL로 곡 · 재생목록 정보 불러오기 (상세 기능: URL로 곡 정보 불러오기 #1).
class FetchMediaInfo implements UseCase<MediaInfo, String> {
  const FetchMediaInfo(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<MediaInfo> call(String url) => _engine.fetchInfo(url.trim());
}

class FetchSubtitlesParams {
  const FetchSubtitlesParams(this.url, [this.languages]);

  final String url;

  /// 우선할 언어 순서. null이면 엔진 기본(한국어 → 영어 → 첫 언어).
  final List<String>? languages;
}

/// 곡의 자막 한 벌 불러오기 (받기 전 가사 미리보기). 자막이 없으면 null.
class FetchSubtitles implements UseCase<SubtitleTrack?, FetchSubtitlesParams> {
  const FetchSubtitles(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<SubtitleTrack?> call(FetchSubtitlesParams p) => p.languages == null
      ? _engine.fetchSubtitles(p.url.trim())
      : _engine.fetchSubtitles(p.url.trim(), preferLanguages: p.languages!);
}

/// 채널 이미지 · 구독자 수 불러오기 (상세 보기).
class FetchChannelInfo implements UseCase<ChannelInfo, String> {
  const FetchChannelInfo(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<ChannelInfo> call(String url) => _engine.fetchChannel(url.trim());
}

/// 곡 · 채널 주소를 기기의 기본 앱으로 열기 (상세 보기에서 영상 보기 · 채널 보기).
class OpenLink implements UseCase<bool, String> {
  const OpenLink(this._opener);

  final LinkOpener _opener;

  @override
  Future<bool> call(String url) => _opener.open(url);
}

/// 곡 주소로 바로 들을 수 있는 오디오 스트림 주소 알아내기 (미리 듣기).
class ResolveAudioStream implements UseCase<AudioStream, String> {
  const ResolveAudioStream(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<AudioStream> call(String url, {String? audioLanguage}) =>
      _engine.resolveAudioStream(url.trim(), audioLanguage: audioLanguage);
}

/// 곡에 들어 있는 오디오 언어 트랙 목록 (여러 개일 때만 고를 수 있다). 못 읽으면 빈 목록.
class FetchAudioLanguages implements UseCase<List<AudioLanguage>, String> {
  const FetchAudioLanguages(this._engine);

  final DownloaderEngine _engine;

  @override
  Future<List<AudioLanguage>> call(String url) async {
    try {
      return await _engine.fetchAudioLanguages(url.trim());
    } on EngineException {
      return const [];
    }
  }
}

/// 미리 듣기 시작 (메인 재생과 따로 재생한다).
class PlayPreview implements UseCase<void, AudioStream> {
  const PlayPreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(AudioStream stream) => _player.play(stream);
}

/// 재생 중인 미리 듣기가 어느 곡인지 플레이어에 적어 두기.
class RememberPreview implements UseCase<void, MediaHit> {
  const RememberPreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(MediaHit hit) => _player.remember(hit);
}

/// 플레이어가 지금 내고 있는 미리 듣기 읽기 (없으면 null).
class CurrentPreview implements UseCase<PreviewSnapshot?, NoParams> {
  const CurrentPreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<PreviewSnapshot?> call(NoParams params) => _player.current();
}

/// 미리 듣기 재생 위치 옮기기.
class SeekPreview implements UseCase<void, Duration> {
  const SeekPreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(Duration position) => _player.seek(position);
}

/// 미리 듣기 잠시 멈추기.
class PausePreview implements UseCase<void, NoParams> {
  const PausePreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(NoParams params) => _player.pause();
}

/// 잠시 멈춘 미리 듣기 이어 듣기.
class ResumePreview implements UseCase<void, NoParams> {
  const ResumePreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(NoParams params) => _player.resume();
}

/// 미리 듣기 멈추기.
class StopPreview implements UseCase<void, NoParams> {
  const StopPreview(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(NoParams params) => _player.stop();
}

/// 미리 듣기가 끝까지 재생됐을 때마다 한 번씩.
class WatchPreviewCompleted implements StreamUseCase<void, NoParams> {
  const WatchPreviewCompleted(this._player);

  final PreviewPlayer _player;

  @override
  Stream<void> call(NoParams params) => _player.watchCompleted();
}

/// 미리 듣기 재생 위치 (얼마나 들었는지).
class WatchPreviewProgress implements StreamUseCase<PreviewProgress, NoParams> {
  const WatchPreviewProgress(this._player);

  final PreviewPlayer _player;

  @override
  Stream<PreviewProgress> call(NoParams params) => _player.watchProgress();
}

/// 미리 듣기가 재생 중에 실패했을 때 그 까닭.
class WatchPreviewFailures implements StreamUseCase<String, NoParams> {
  const WatchPreviewFailures(this._player);

  final PreviewPlayer _player;

  @override
  Stream<String> call(NoParams params) => _player.watchFailures();
}
