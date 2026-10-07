import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../../domain/entities/media_session_info.dart';
import 'notification_texts.dart';

/// 재생 알림 · 잠금화면 · 이어폰 버튼용 audio_service 핸들러.
/// 소리는 just_audio가 내고(재생 상태는 앱의 NowPlayingCubit이 주인), 이 핸들러는 보여 주기만 한다:
/// 상태를 받아 알림에 그리고, 누른 버튼은 [commands]로 앱에 돌려준다.
class MuloAudioHandler extends BaseAudioHandler {
  static const _favoriteAction = 'favorite';

  final _commands = StreamController<MediaCommand>.broadcast();

  Stream<MediaCommand> get commands => _commands.stream;

  /// [info]를 알림에 그린다. null이면 알림을 치운다.
  void show(MediaSessionInfo? info) {
    if (info == null) {
      mediaItem.add(null);
      playbackState.add(
        PlaybackState(processingState: AudioProcessingState.idle),
      );
      return;
    }
    final art = info.artUri == null ? null : Uri.tryParse(info.artUri!);
    final item = MediaItem(
      id: info.preview ? 'mulo.preview' : 'mulo.now_playing',
      title: info.title,
      artist: info.artist.isEmpty ? null : info.artist,
      album: info.album.isEmpty ? null : info.album,
      duration: info.duration == Duration.zero ? null : info.duration,
      artUri: art,
    );
    // 곡 · 커버가 같으면 다시 보내지 않는다 (알림이 깜빡이지 않게).
    // MediaItem의 ==는 id만 비교하고 id가 늘 같으므로, 보이는 값을 직접 견준다.
    final shown = mediaItem.value;
    if (shown == null ||
        shown.title != item.title ||
        shown.artist != item.artist ||
        shown.album != item.album ||
        shown.duration != item.duration ||
        shown.artUri != item.artUri) {
      mediaItem.add(item);
    }

    // 미리 듣기: 멈추기만 있다 (누르면 앞에 듣던 곡으로 돌아간다).
    final controls = info.preview
        ? [MediaControl.stop]
        : [
            if (info.hasPrevious) MediaControl.skipToPrevious,
            info.playing ? MediaControl.pause : MediaControl.play,
            if (info.hasNext) MediaControl.skipToNext,
            // 펼친 알림에만 보이는 좋아요 · 닫기 (접힌 알림은 위 세 개만).
            MediaControl.custom(
              androidIcon: info.favorite
                  ? 'drawable/ic_notif_favorite'
                  : 'drawable/ic_notif_favorite_outline',
              label: info.favorite
                  ? systemL10n().trackMenuUnfavorite
                  : systemL10n().trackMenuFavorite,
              name: _favoriteAction,
            ),
            MediaControl.stop,
          ];
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {MediaAction.seek, MediaAction.stop},
        androidCompactActionIndices: [
          for (var i = 0; i < (info.preview ? 1 : controls.length - 2); i++) i,
        ],
        processingState: AudioProcessingState.ready,
        playing: info.playing,
        updatePosition: info.position,
        speed: 1,
      ),
    );
  }

  @override
  Future<void> play() async =>
      _commands.add(const MediaCommand(MediaCommandType.play));

  @override
  Future<void> pause() async =>
      _commands.add(const MediaCommand(MediaCommandType.pause));

  @override
  Future<void> skipToNext() async =>
      _commands.add(const MediaCommand(MediaCommandType.next));

  @override
  Future<void> skipToPrevious() async =>
      _commands.add(const MediaCommand(MediaCommandType.previous));

  @override
  Future<void> seek(Duration position) async =>
      _commands.add(MediaCommand(MediaCommandType.seek, position));

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == _favoriteAction) {
      _commands.add(const MediaCommand(MediaCommandType.favorite));
    }
  }

  /// 알림을 밀어서 지웠을 때: 재생만 멈춘다 (앱 대기열은 그대로).
  @override
  Future<void> stop() async {
    _commands.add(const MediaCommand(MediaCommandType.stop));
    await super.stop();
  }
}
