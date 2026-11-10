import '../../../../core/usecase/usecase.dart';
import '../entities/media_info.dart';
import '../entities/saved_video.dart';
import '../entities/video_quality.dart';
import '../entities/video_stream.dart';
import '../repositories/preview_player.dart';
import '../repositories/saved_detail_store.dart';
import '../repositories/saved_video_repository.dart';
import 'search_usecases.dart';

/// 보관한 영상 목록을 읽고, 플레이어에 보관 목록을 알린다 (앱을 켤 때 한 번).
class LoadSavedVideos implements UseCase<List<SavedVideo>, NoParams> {
  const LoadSavedVideos(this._repo, this._player);

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;

  @override
  Future<List<SavedVideo>> call(NoParams params) async {
    final list = await _repo.load();
    await _player.setSavedStreams([
      for (final v in list)
        if (v.streamId != null) v.streamId!,
    ]);
    return list;
  }
}

/// [SaveVideo]에 넘기는 값: 저장할 곡과 (유튜브 영상이면) 고른 화질. 화질이 null이면 음원만 저장한다.
class SaveVideoParams {
  const SaveVideoParams(this.hit, {this.quality});

  final MediaHit hit;
  final VideoQuality? quality;
}

/// 곡을 저장한다: 소리(유튜브는 고른 화질의 영상) 주소를 읽어 저장 저장소에 받기 시작하고 목록에 더한다.
/// 이미 저장한 곡이면 아무 일도 없다. 주소를 못 읽으면 던진다.
class SaveVideo implements UseCase<List<SavedVideo>, SaveVideoParams> {
  const SaveVideo(
    this._repo,
    this._player,
    this._resolveVideo,
    this._resolveAudio, {
    this.details,
    this.fetchInfo,
  });

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;
  final ResolveVideoStream _resolveVideo;
  final ResolveAudioStream _resolveAudio;
  final SavedDetailStore? details;

  /// 상세 정보(설명 · 조회수 · 올린 날 · 채널)가 비어 있는 곡을 저장할 때 먼저 읽는다.
  final FetchMediaInfo? fetchInfo;

  @override
  Future<List<SavedVideo>> call(SaveVideoParams params) async {
    final quality = params.quality;
    final list = await _repo.load();
    if (list.any((v) => v.id == params.hit.id)) return list;
    // 상세 정보까지 읽어서 함께 저장한다 (못 읽으면 가진 정보만 저장한다).
    final hit = await _withDetail(params.hit);
    // 미리 듣기가 트는 것과 같은 주소를 받는다. 유튜브는 고른 화질의 영상 주소:
    // 소리가 든 형식이면 그것 하나, 영상 전용이면 소리 주소도 함께 (플레이어가 따로 틀어 맞춘다).
    // 소리만 저장하는 곡(quality 없음)이나 영상이 안 읽히는 곡은 소리 주소 하나.
    final targets = await _resolveTargets(
      _resolveVideo,
      _resolveAudio,
      hit,
      quality,
    );
    return _finish(list, hit, quality, targets);
  }

  Future<MediaHit> _withDetail(MediaHit hit) async {
    final fetch = fetchInfo;
    final known =
        hit.viewCount != null &&
        hit.uploadedAt != null &&
        hit.channelUrl != null;
    if (fetch == null || known) return hit;
    try {
      final info = await fetch(hit.url);
      if (info is VideoInfo) return hit.filledFrom(info.hit);
    } on Object {
      // 상세를 못 읽어도 저장은 계속한다.
    }
    return hit;
  }

  Future<List<SavedVideo>> _finish(
    List<SavedVideo> list,
    MediaHit hit,
    VideoQuality? quality,
    List<VideoStream> targets,
  ) async {
    final streamId = await _player.saveStream(hit.id, targets);
    await details?.write(hit);
    final next = [
      ...list,
      SavedVideo(
        hit: hit,
        streamId: streamId,
        quality: quality,
        sources: targets,
      ),
    ];
    await _repo.save(next);
    await _player.setSavedStreams([
      for (final v in next)
        if (v.streamId != null) v.streamId!,
    ]);
    return next;
  }
}

/// 저장할 주소들: 유튜브는 고른 화질의 영상 주소 (소리가 든 형식이면 그것 하나, 영상 전용이면 소리 주소도 함께),
/// 소리만 저장하는 곡(quality 없음)이나 영상이 안 읽히는 곡은 소리 주소 하나.
Future<List<VideoStream>> _resolveTargets(
  ResolveVideoStream resolveVideo,
  ResolveAudioStream resolveAudio,
  MediaHit hit,
  VideoQuality? quality,
) async {
  final targets = <VideoStream>[];
  if (quality != null) {
    try {
      final v = await resolveVideo(hit.url, quality: quality);
      targets.add(v);
      if (v.muxed) return targets;
    } on Object {
      targets.clear();
    }
  }
  final a = await resolveAudio(hit.url);
  targets.add(VideoStream(url: a.url, headers: a.headers));
  return targets;
}

/// 받다가 끊긴 저장분(앱이 꺼졌거나 네트워크가 끊긴 곡)을 이어 받는다 (앱을 켤 때 한 번).
/// 주소를 새로 읽어 받기를 다시 시작하고, 이미 받은 부분은 건너뛴다. 한 곡이 실패해도 나머지는 계속한다.
class ResumeSavedVideos implements UseCase<List<SavedVideo>, NoParams> {
  const ResumeSavedVideos(
    this._repo,
    this._player,
    this._resolveVideo,
    this._resolveAudio,
  );

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;
  final ResolveVideoStream _resolveVideo;
  final ResolveAudioStream _resolveAudio;

  @override
  Future<List<SavedVideo>> call(NoParams params) async {
    var list = await _repo.load();
    for (final v in List.of(list)) {
      if (v.ready) continue;
      try {
        final targets = await _resolveTargets(
          _resolveVideo,
          _resolveAudio,
          v.hit,
          v.quality,
        );
        final streamId = await _player.saveStream(v.hit.id, targets);
        list = [
          for (final x in await _repo.load())
            x.id == v.id
                ? SavedVideo(
                    hit: x.hit,
                    streamId: streamId,
                    ready: x.ready,
                    quality: x.quality,
                    sources: targets,
                  )
                : x,
        ];
        await _repo.save(list);
      } on Object {
        continue;
      }
    }
    return list;
  }
}

/// 보관에서 뺀다: 목록에서 지우고 받아 둔 데이터도 지운다.
class RemoveSavedVideo implements UseCase<List<SavedVideo>, String> {
  const RemoveSavedVideo(this._repo, this._player, {this.details});

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;
  final SavedDetailStore? details;

  @override
  Future<List<SavedVideo>> call(String id) async {
    final list = await _repo.load();
    final target = list.where((v) => v.id == id).firstOrNull;
    if (target == null) return list;
    await _player.removeSavedStream(id, target.streamId);
    await details?.delete(id);
    final next = [
      for (final v in list)
        if (v.id != id) v,
    ];
    await _repo.save(next);
    await _player.setSavedStreams([
      for (final v in next)
        if (v.streamId != null) v.streamId!,
    ]);
    return next;
  }
}

/// 받기가 끝난 영상을 "받아 둠"으로 표시한다.
class MarkSavedVideoReady implements UseCase<List<SavedVideo>, String> {
  const MarkSavedVideoReady(this._repo);

  final SavedVideoRepository _repo;

  @override
  Future<List<SavedVideo>> call(String id) async {
    final next = [
      for (final v in await _repo.load())
        v.id == id ? v.copyWith(ready: true) : v,
    ];
    await _repo.save(next);
    return next;
  }
}

/// 보관하려고 받는 영상의 진행률 (영상 id, 0~100).
class WatchSavedProgress
    implements StreamUseCase<({String id, int percent}), NoParams> {
  const WatchSavedProgress(this._player);

  final PreviewPlayer _player;

  @override
  Stream<({String id, int percent})> call(NoParams params) =>
      _player.watchSavedProgress();
}

/// 보관하려고 받던 영상이 끝날 때마다 (영상 id, 성공 여부).
class WatchSavedDone
    implements StreamUseCase<({String id, bool ok}), NoParams> {
  const WatchSavedDone(this._player);

  final PreviewPlayer _player;

  @override
  Stream<({String id, bool ok})> call(NoParams params) => _player.watchSaved();
}
