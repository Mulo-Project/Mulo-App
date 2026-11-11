import '../../../../core/usecase/usecase.dart';
import '../entities/audio_language.dart';
import '../entities/audio_stream.dart';
import '../entities/engine_exception.dart';
import '../entities/media_info.dart';
import '../entities/subtitle_track.dart';
import '../entities/video_quality.dart';
import '../entities/video_stream.dart';
import '../entities/preview_progress.dart';
import '../entities/preview_snapshot.dart';
import '../entities/stream_cache_info.dart';
import '../entities/search_source.dart';
import '../repositories/downloader_engine.dart';
import '../repositories/link_opener.dart';
import '../entities/saved_video.dart';
import '../repositories/preview_player.dart';
import '../repositories/saved_video_repository.dart';
import '../repositories/video_quality_repository.dart';

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
  const ResolveAudioStream(this._engine, [this._saved]);

  final DownloaderEngine _engine;

  /// 저장한 곡이면 링크를 풀지 않고 저장할 때 받은 주소를 쓴다.
  final SavedVideoRepository? _saved;

  @override
  Future<AudioStream> call(String url, {String? audioLanguage}) async {
    final page = url.trim();
    if (audioLanguage == null) {
      final audio = (await _savedReady(_saved, page))?.audioSource;
      if (audio != null) {
        return AudioStream(url: audio.url, headers: audio.headers);
      }
    }
    try {
      return await _engine.resolveAudioStream(page, audioLanguage: audioLanguage);
    } on Object {
      // 링크를 못 풀었다 (오프라인 등): 받다 만 곡이라도 지금까지 받은 데이터만큼은 튼다.
      final audio = audioLanguage == null
          ? (await _savedReady(_saved, page, requireReady: false))?.audioSource
          : null;
      if (audio == null) rethrow;
      return AudioStream(url: audio.url, headers: audio.headers);
    }
  }
}

/// [page] 주소의 곡을 저장해 두었고 받기가 끝났으면 그 곡 (주소 정보가 없는 옛 저장분은 null).
Future<SavedVideo?> _savedReady(
  SavedVideoRepository? repo,
  String page, {
  bool requireReady = true,
}) async {
  if (repo == null) return null;
  try {
    for (final v in await repo.load()) {
      if ((v.ready || !requireReady) &&
          v.sources.isNotEmpty &&
          v.hit.url == page) {
        return v;
      }
    }
  } on Object {
    // 읽지 못하면 저장하지 않은 곡처럼 링크를 푼다.
  }
  return null;
}

/// 곡 주소로 소리 없는 낮은 화질 영상 스트림 주소 알아내기 (영상 표시).
class ResolveVideoStream implements UseCase<VideoStream, String> {
  const ResolveVideoStream(this._engine, [this._quality, this._saved]);

  final DownloaderEngine _engine;

  /// 설정한 화질 (없으면 기본 화질).
  final VideoQualityRepository? _quality;

  /// 저장한 곡이면 링크를 풀지 않고 저장할 때 받은 주소를 쓴다.
  final SavedVideoRepository? _saved;

  @override
  Future<VideoStream> call(
    String url, {
    VideoQuality? quality,

    /// 소리만 저장한 곡도 (오프라인이 아니면) 링크를 풀어 영상을 읽는다. 상세 화면에서 영상을 같이 볼 때만 켠다.
    bool online = false,
  }) async {
    final saved = await _savedReady(_saved, url.trim());
    if (saved != null && !(online && saved.videoSource == null)) {
      final video = saved.videoSource;
      if (video != null && quality != null && quality == saved.quality) {
        return video;
      }
      // 소리만 저장한 곡은 영상 주소를 따로 읽지 않는다 (소리를 저장한 데이터로 튼다).
      if (video == null) {
        throw const EngineException(EngineFailure.notFound, 'saved audio only');
      }
    }
    final q = quality ?? await _quality?.load() ?? VideoQuality.standard;
    try {
      return await _engine.resolveVideoStream(url.trim(), maxHeight: q.maxHeight);
    } on Object {
      // 링크를 못 풀었다 (오프라인 등): 받다 만 영상이라도 받은 데이터만큼은 튼다.
      final partial = await _savedReady(
        _saved,
        url.trim(),
        requireReady: false,
      );
      final video = partial?.videoSource;
      if (video == null || quality != partial?.quality) rethrow;
      return video;
    }
  }
}

/// 미리 듣기 영상 화질 설정 읽기 · 저장.
class LoadVideoQuality implements UseCase<VideoQuality, NoParams> {
  const LoadVideoQuality(this._repo);

  final VideoQualityRepository _repo;

  @override
  Future<VideoQuality> call(NoParams _) => _repo.load();
}

class SaveVideoQuality implements UseCase<void, VideoQuality> {
  const SaveVideoQuality(this._repo);

  final VideoQualityRepository _repo;

  @override
  Future<void> call(VideoQuality value) => _repo.save(value);
}

/// 자동 화질(낮게 시작해 높임) 설정 읽기 · 저장.
class LoadAutoVideoQuality implements UseCase<bool, NoParams> {
  const LoadAutoVideoQuality(this._repo);

  final VideoQualityRepository _repo;

  @override
  Future<bool> call(NoParams _) => _repo.loadAuto();
}

class SaveAutoVideoQuality implements UseCase<void, bool> {
  const SaveAutoVideoQuality(this._repo);

  final VideoQualityRepository _repo;

  @override
  Future<void> call(bool value) => _repo.saveAuto(value);
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

/// 미리 듣는 곡의 영상을 소리와 같은 시계로 틀기 (네이티브가 화면까지 맡는다).
class PlayPreviewVideo implements UseCase<void, VideoStream> {
  const PlayPreviewVideo(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(VideoStream stream) => _player.playVideo(stream);
}

/// 메인 재생 소리(임시 저장한 음원)에 맞춰 스트림 영상을 틀기. null이면 그 영상을 멈춘다.
class PlayMainVideo implements UseCase<void, VideoStream?> {
  const PlayMainVideo(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(VideoStream? stream) => _player.playMainVideo(stream);
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

/// 스트리밍 임시 저장소의 사용량과 한도.
class GetStreamCacheInfo implements UseCase<StreamCacheInfo, NoParams> {
  const GetStreamCacheInfo(this._player);

  final PreviewPlayer _player;

  @override
  Future<StreamCacheInfo> call(NoParams params) => _player.cacheInfo();
}

/// 영상을 작은 창(PiP)으로 띄우기. 못 띄우면 false.
class EnterPictureInPicture implements UseCase<bool, NoParams> {
  const EnterPictureInPicture(this._player);

  final PreviewPlayer _player;

  @override
  Future<bool> call(NoParams params) => _player.enterPip();
}

/// 스트리밍 임시 저장소 용량 한도 바꾸기 (바이트).
class SetStreamCacheLimit implements UseCase<void, int> {
  const SetStreamCacheLimit(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(int bytes) => _player.setCacheLimit(bytes);
}

/// 스트리밍 임시 저장소 비우기.
class ClearStreamCache implements UseCase<void, NoParams> {
  const ClearStreamCache(this._player);

  final PreviewPlayer _player;

  @override
  Future<void> call(NoParams params) => _player.clearCache();
}
