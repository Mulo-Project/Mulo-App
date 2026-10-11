import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:path_provider/path_provider.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/design/tokens/app_palette.dart';
import '../../../../core/platform/native_playback_channel.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/repositories/media_session.dart';
import '../datasources/notification_texts.dart';

/// Android 재생 알림 · 잠금화면: 네이티브 서비스(Media3 미디어 세션)가 그린다.
/// 이 클래스는 보여 줄 내용(커버 사본 · 기본 커버 포함)을 만들어 보내고, 알림에서 누른
/// 조작(이전 · 다음 · 좋아요 · 닫기 등)을 받아 돌려준다. 재생 · 일시정지 · 이동은 네이티브가 직접 처리한다.
class NativeMediaSession implements MediaSession {
  NativeMediaSession(this._channel);

  final NativePlaybackChannel _channel;

  static const _types = {
    'play': MediaCommandType.play,
    'pause': MediaCommandType.pause,
    'next': MediaCommandType.next,
    'previous': MediaCommandType.previous,
    'seek': MediaCommandType.seek,
    'stop': MediaCommandType.stop,
    'favorite': MediaCommandType.favorite,
  };

  @override
  Stream<MediaCommand> watchCommands() => _channel.events
      .where((e) => e['type'] == 'command' && _types.containsKey(e['name']))
      .map((e) {
        final ms = e['positionMs'];
        return MediaCommand(
          _types[e['name']]!,
          ms is num ? Duration(milliseconds: ms.toInt()) : null,
        );
      });

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

  final _defaultArt = <String, String>{};

  /// 커버가 없는 곡에 보여 줄 앱 기본 커버 (테마색 그라데이션 + 음표). 색마다 한 번 그려 파일로 둔다.
  Future<String?> _defaultCover(List<int> colors) async {
    final key = colors.map((c) => c.toRadixString(16)).join('_');
    final known = _defaultArt[key];
    if (known != null) return known;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/notification_cover_$key.png');
      if (!file.existsSync()) {
        await file.writeAsBytes(await _paintDefaultCover(colors));
      }
      return _defaultArt[key] = file.uri.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _paintDefaultCover(List<int> colors) async {
    const size = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Offset.zero & const Size(size, size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(size * .2, size * .15),
          size * 1.4,
          [for (final c in colors) Color(c)],
          const [0, .5, 1],
        ),
    );
    const icon = Icons.music_note_rounded;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size * .45,
          color: AppPalette.white.withValues(alpha: .9),
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );
    final image = await recorder.endRecording().toImage(512, 512);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Future<void> updateQueueArt(Map<String, String> artById) =>
      _channel.setQueueArt(artById);

  @override
  Future<void> update(MediaSessionInfo? info) async {
    final seq = ++_seq;
    if (info == null) {
      await _channel.setSession(null);
      return;
    }
    final art =
        await _localArt(info.artUri) ??
        (info.coverColors.length == 3
            ? await _defaultCover(info.coverColors)
            : null);
    // 기다리는 사이 더 새 요청이 왔으면 이 요청은 버린다.
    if (seq != _seq) return;
    final l10n = systemL10n();
    await _channel.setSession({
      'trackId': info.trackId,
      'title': info.title,
      'artist': info.artist,
      'album': info.album,
      'artUri': art,
      'durationMs': info.duration.inMilliseconds,
      'positionMs': info.position.inMilliseconds,
      'playing': info.playing,
      'favorite': info.favorite,
      'preview': info.preview,
      'favoriteLabel': l10n.trackMenuFavorite,
      'unfavoriteLabel': l10n.trackMenuUnfavorite,
      'closeLabel': l10n.notifStop,
      'hideSongInfo': info.hidden,
      'hiddenTitle': l10n.notifHiddenTitle,
      'hiddenNote': l10n.notifHiddenNote,
      'unknownArtist': l10n.unknownArtist,
    });
  }
}
