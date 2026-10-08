import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/notification_usecases.dart';

/// 앱 상태(재생 상태)를 알림창에 옮긴다. 화면이 없고 상태도 없다:
/// 바뀐 것만 골라 알림 유스케이스를 부른다.
class NotificationSyncCubit extends Cubit<void> {
  NotificationSyncCubit(this._actions) : super(null);

  final NotificationActions _actions;

  /// 알림 · 잠금화면에서 누른 조작.
  Stream<MediaCommand> get commands => _actions.watchCommands(const NoParams());

  var _askedPermission = false;

  /// 알림을 처음 띄울 때 한 번만 시스템 권한을 묻는다 (거절하면 설정에서 안내).
  Future<void> _ensurePermission() async {
    if (_askedPermission) return;
    _askedPermission = true;
    if (!await _actions.isPermissionGranted(const NoParams())) {
      await _actions.requestPermission(const NoParams());
    }
  }

  // ── 재생 ──

  MediaSessionInfo? _session;
  DateTime? _sessionAt;

  /// 재생 상태가 바뀔 때마다. [track]이 없거나 재생 알림이 꺼져 있으면 알림을 치운다.
  /// [preview]가 있으면 재생 알림을 그 곡의 미리 듣기로 바꿔 보여 주고(알림은 늘 하나),
  /// 끝나면 [track]으로 돌아간다.
  /// 위치는 알림이 흘러가는 대로 따라가므로, 예상과 크게 어긋날 때(이동)만 다시 보낸다.
  Future<void> syncPlayback({
    required Track? track,
    required bool isPlaying,
    required Duration position,
    required bool hasPrevious,
    required bool hasNext,
    required String? artUri,
    bool favorite = false,
    PreviewNotice? preview,
    List<int> coverColors = const [],
    required NotificationSettings settings,
    required AppLocalizations l10n,
    DateTime? now,
  }) async {
    if ((track == null && preview == null) || !settings.playback) {
      if (_session == null) return;
      _session = null;
      _sessionAt = null;
      await _actions.updateSession(null);
      return;
    }
    final hide = settings.hideSongInfo;
    final next = preview != null
        ? MediaSessionInfo(
            title: hide ? l10n.notifHiddenTitle : preview.title,
            artist: hide
                ? '${l10n.notifHiddenNote} · ${l10n.notifPreviewLabel}'
                : preview.uploader.isEmpty
                ? l10n.notifPreviewLabel
                : '${preview.uploader} · ${l10n.notifPreviewLabel}',
            artUri: hide ? null : preview.artUri,
            duration: preview.duration ?? Duration.zero,
            position: preview.position,
            playing: !preview.paused,
            hasPrevious: false,
            hasNext: false,
            preview: true,
            coverColors: hide ? const [] : coverColors,
          )
        : MediaSessionInfo(
            title: hide ? l10n.notifHiddenTitle : track!.title,
            artist: hide
                ? l10n.notifHiddenNote
                : (track!.artist.isEmpty ? l10n.unknownArtist : track.artist),
            album: hide ? '' : track!.album,
            artUri: hide ? null : artUri,
            duration: track!.duration,
            position: position,
            playing: isPlaying,
            hasPrevious: hasPrevious,
            hasNext: hasNext,
            favorite: favorite,
            trackId: track.id,
            hidden: hide,
            coverColors: hide ? const [] : coverColors,
          );
    final at = now ?? DateTime.now();
    final last = _session;
    if (last != null && _sessionAt != null) {
      final sameExceptPosition =
          last.title == next.title &&
          last.artist == next.artist &&
          last.album == next.album &&
          last.artUri == next.artUri &&
          last.duration == next.duration &&
          last.playing == next.playing &&
          last.hasPrevious == next.hasPrevious &&
          last.hasNext == next.hasNext &&
          last.favorite == next.favorite &&
          last.trackId == next.trackId &&
          last.hidden == next.hidden &&
          last.preview == next.preview &&
          listEquals(last.coverColors, next.coverColors);
      final expected = last.playing
          ? last.position + at.difference(_sessionAt!)
          : last.position;
      final drift = (expected - next.position).abs();
      if (sameExceptPosition && drift < const Duration(milliseconds: 1500)) {
        return;
      }
    }
    _session = next;
    _sessionAt = at;
    await _ensurePermission();
    await _actions.updateSession(next);
  }
}
