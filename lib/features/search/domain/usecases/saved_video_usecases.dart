import '../../../../core/usecase/usecase.dart';
import '../entities/media_info.dart';
import '../entities/saved_video.dart';
import '../entities/video_stream.dart';
import '../repositories/preview_player.dart';
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

/// 영상을 보관한다: 소리 · 영상 주소를 읽어 보관 저장소에 받기 시작하고 목록에 더한다.
/// 이미 보관한 영상이면 아무 일도 없다. 주소를 못 읽으면 던진다.
class SaveVideo implements UseCase<List<SavedVideo>, MediaHit> {
  const SaveVideo(this._repo, this._player, this._resolveVideo, this._resolveAudio);

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;
  final ResolveVideoStream _resolveVideo;
  final ResolveAudioStream _resolveAudio;

  @override
  Future<List<SavedVideo>> call(MediaHit hit) async {
    final list = await _repo.load();
    if (list.any((v) => v.id == hit.id)) return list;
    // 미리 듣기가 트는 것과 같은 주소를 받는다: 소리가 든 영상 형식, 없으면 소리 주소.
    VideoStream? target;
    try {
      final v = await _resolveVideo(hit.url);
      if (v.muxed) target = v;
    } on Object {
      // 영상 쪽이 안 되면 소리 주소로 간다.
    }
    if (target == null) {
      final a = await _resolveAudio(hit.url);
      target = VideoStream(url: a.url, headers: a.headers);
    }
    final streamId = await _player.saveStream(hit.id, target);
    final next = [...list, SavedVideo(hit: hit, streamId: streamId)];
    await _repo.save(next);
    await _player.setSavedStreams([
      for (final v in next)
        if (v.streamId != null) v.streamId!,
    ]);
    return next;
  }
}

/// 보관에서 뺀다: 목록에서 지우고 받아 둔 데이터도 지운다.
class RemoveSavedVideo implements UseCase<List<SavedVideo>, String> {
  const RemoveSavedVideo(this._repo, this._player);

  final SavedVideoRepository _repo;
  final PreviewPlayer _player;

  @override
  Future<List<SavedVideo>> call(String id) async {
    final list = await _repo.load();
    final target = list.where((v) => v.id == id).firstOrNull;
    if (target == null) return list;
    await _player.removeSavedStream(id, target.streamId);
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
      for (final v in await _repo.load()) v.id == id ? v.copyWith(ready: true) : v,
    ];
    await _repo.save(next);
    return next;
  }
}

/// 보관하려고 받던 영상이 끝날 때마다 (영상 id, 성공 여부).
class WatchSavedDone
    implements StreamUseCase<({String id, bool ok}), NoParams> {
  const WatchSavedDone(this._player);

  final PreviewPlayer _player;

  @override
  Stream<({String id, bool ok})> call(NoParams params) => _player.watchSaved();
}
