import '../entities/audio_stream.dart';
import '../entities/media_info.dart';
import '../entities/preview_progress.dart';
import '../entities/preview_snapshot.dart';
import '../entities/stream_cache_info.dart';
import '../entities/video_stream.dart';

/// 미리 듣기 전용 플레이어. 메인 재생(대기열 · 미니 플레이어)과는 따로 움직이며 한 번에 한 곡만 낸다.
///
/// 불러오지 못하면 [EngineException]으로 던진다.
abstract interface class PreviewPlayer {
  /// [stream]을 불러와 재생을 시작한다. 이미 재생 중이면 바꿔 끼운다.
  Future<void> play(AudioStream stream);

  /// 지금 재생 중인 미리 듣기의 영상을 소리와 같은 시계로 튼다 (화면은 영상 화면으로 나간다).
  /// 같은 영상이면 아무 일도 없다. 영상은 덤이라 못 열어도 소리에는 영향이 없다.
  Future<void> playVideo(VideoStream stream);

  /// 재생 위치를 [position]으로 옮긴다 (재생 중이 아니면 아무 일도 없다).
  Future<void> seek(Duration position);

  /// 소리를 잠시 멈춘다 (자리는 그대로).
  Future<void> pause();

  /// 잠시 멈춘 자리에서 다시 재생한다.
  Future<void> resume();

  /// 재생을 멈추고 놓는다.
  Future<void> stop();

  /// 지금 재생 중인 미리 듣기가 어느 곡인지 플레이어에 적어 둔다 (앱이 꺼졌다 켜져도 되살리려고).
  Future<void> remember(MediaHit hit);

  /// 플레이어가 지금 내고 있는 미리 듣기. 소리를 내는 게 없으면 null.
  Future<PreviewSnapshot?> current();

  /// 끝까지 재생했을 때마다 한 번씩.
  Stream<void> watchCompleted();

  /// 재생이 시작된 뒤에 소리가 끊기는 오류(주소가 중간에 막힘 등)가 났을 때 그 까닭.
  Stream<String> watchFailures();

  /// 재생 위치가 바뀔 때마다 (재생 중에만).
  Stream<PreviewProgress> watchProgress();

  /// 들은 스트리밍을 임시로 쌓아 두는 저장소의 사용량과 한도.
  Future<StreamCacheInfo> cacheInfo();

  /// 임시 저장소 용량 한도를 바꾼다 (재생 중이던 미리 듣기는 멈춘다).
  Future<void> setCacheLimit(int bytes);

  /// 임시 저장소를 모두 비운다 (재생 중이던 미리 듣기는 멈춘다).
  Future<void> clearCache();

  /// 보관한 영상의 스트림 id 목록을 플레이어에 알린다 (이 영상은 임시 저장소가 아니라 보관 저장소에 쌓인다).
  Future<void> setSavedStreams(List<String> streamIds);

  /// [streams](소리가 든 영상 하나, 또는 영상 전용 + 소리 전용)를 통째로 보관 저장소에 받아 둔다. [id]는 영상 id.
  /// 받는 건 따로 돌고 끝나면 [watchSaved]로 알린다. 보관 여부를 가르는 스트림 id를 돌려준다 (모르면 null).
  Future<String?> saveStream(String id, List<VideoStream> streams);

  /// 보관한 영상의 데이터를 지운다 (받던 중이면 멈춘다).
  Future<void> removeSavedStream(String id, String? streamId);

  /// 보관하려고 받던 영상이 끝났을 때 (영상 id, 성공 여부).
  Stream<({String id, bool ok})> watchSaved();
}
