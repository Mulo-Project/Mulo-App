import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../../../../core/cache/cached_web_image.dart';
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

  var _seq = 0;
  final _artCopies = <String, String>{};

  /// 웹 커버는 저장된 사본(file 주소)으로 바꿔 준다: 오프라인에서도 뜨고 알림이 다시 받지 않는다.
  /// 오래 걸리거나 못 받으면 원래 주소를 그대로 쓴다 (알림이 직접 받는다).
  Future<String?> _localArt(String? uri) async {
    if (uri == null || !uri.startsWith('http')) return uri;
    final known = _artCopies[uri];
    if (known != null) return known;
    final file = await CachedWebImage.localCopy(uri)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (file == null) return uri;
    return _artCopies[uri] = file.uri.toString();
  }

  @override
  Future<void> update(MediaSessionInfo? info) async {
    final seq = ++_seq;
    // 아직 한 번도 보여 준 적 없는데 치우라는 요청이면 서비스를 만들지 않는다.
    final handler = info == null ? _handler : await _ensureHandler();
    if (info == null) {
      handler?.show(null);
      return;
    }
    final art = await _localArt(info.artUri);
    // 기다리는 사이 더 새 요청이 왔으면 이 요청은 버린다.
    if (seq != _seq) return;
    handler?.show(art == info.artUri ? info : info.withArtUri(art));
  }
}
