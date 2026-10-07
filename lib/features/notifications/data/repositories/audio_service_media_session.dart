import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../../../../core/design/tokens/app_palette.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/repositories/media_session.dart';
import '../datasources/mulo_audio_handler.dart';
import '../datasources/notification_texts.dart';

/// Android 재생 알림 · 잠금화면 (audio_service). 알림은 처음 보여 줄 때 만든다.
class AudioServiceMediaSession implements MediaSession {
  MuloAudioHandler? _handler;
  Future<MuloAudioHandler>? _starting;
  final _commands = StreamController<MediaCommand>.broadcast();

  @override
  Stream<MediaCommand> watchCommands() => _commands.stream;

  Future<MuloAudioHandler> _ensureHandler() => _starting ??= () async {
    final l10n = systemL10n();
    final handler = await AudioService.init(
      builder: MuloAudioHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.mulo.app.playback',
        androidNotificationChannelName: l10n.notifChannelPlayback,
        androidNotificationIcon: 'drawable/ic_stat_mulo',
        notificationColor: AppPalette.violet,
        androidStopForegroundOnPause: true,
      ),
    );
    handler.commands.listen(_commands.add);
    return _handler = handler;
  }();

  @override
  Future<void> update(MediaSessionInfo? info) async {
    // 아직 한 번도 보여 준 적 없는데 치우라는 요청이면 서비스를 만들지 않는다.
    final handler = info == null ? _handler : await _ensureHandler();
    handler?.show(info);
  }
}
