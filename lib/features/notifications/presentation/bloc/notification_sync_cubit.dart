import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../library/domain/entities/track.dart';
import '../../../search/domain/entities/saved_video.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/notification_usecases.dart';

/// 앱 상태(받기 대기열 · 재생 상태)를 알림창에 옮긴다. 화면이 없고 상태도 없다:
/// 바뀐 것만 골라 알림 유스케이스를 부른다.
class NotificationSyncCubit extends Cubit<void> {
  NotificationSyncCubit(this._actions) : super(null);

  final NotificationActions _actions;

  /// 알림 · 잠금화면에서 누른 조작.
  Stream<MediaCommand> get commands => _actions.watchCommands(const NoParams());

  /// 받기 알림 본문을 눌러 열라는 요청 (받기 항목 id).
  Stream<String> get downloadOpens =>
      _actions.watchDownloadOpens(const NoParams());

  /// 알림을 눌러 앱이 켜졌다면 눌린 받기 항목 id (한 번 받으면 비운다).
  Future<String?> takeDownloadOpen() =>
      _actions.takeDownloadOpen(const NoParams());

  var _askedPermission = false;

  /// 알림을 처음 띄울 때 한 번만 시스템 권한을 묻는다 (거절하면 설정에서 안내).
  Future<void> _ensurePermission() async {
    if (_askedPermission) return;
    _askedPermission = true;
    if (!await _actions.isPermissionGranted(const NoParams())) {
      await _actions.requestPermission(const NoParams());
    }
  }

  var _queueArt = const <String, String>{};

  /// 대기열 곡별 커버 주소를 알림에 넘긴다 (앱이 꺼진 사이 넘어간 곡에도 커버가 나오게).
  /// 곡 정보 숨기기가 켜져 있으면 비운다. 바뀐 것만 보낸다.
  Future<void> syncQueueArt(
    Map<String, String> artById, {
    required NotificationSettings settings,
  }) async {
    final next = settings.playback && !settings.hideSongInfo
        ? artById
        : const <String, String>{};
    if (mapEquals(next, _queueArt)) return;
    _queueArt = next;
    await _actions.updateQueueArt(next);
  }

  // ── 저장한 음원 ──

  var _savedReady = const <String, bool>{};

  /// 저장한 음원 목록이 바뀔 때마다. 받는 중이던 곡이 다 받아지면 곡마다 한 번 완료를 알린다.
  Future<void> syncSaved(
    List<SavedVideo> videos,
    NotificationSettings settings,
    AppLocalizations l10n,
  ) async {
    final before = _savedReady;
    _savedReady = {for (final v in videos) v.id: v.ready};
    // 처음 읽을 때(앱을 켤 때)는 알리지 않는다: 받던 중이었다가 끝난 곡만.
    if (!settings.downloadResult) return;
    for (final v in videos) {
      if (before[v.id] != false || !v.ready) continue;
      await _ensurePermission();
      await _actions.showResult(
        DownloadResultNotice(
          id: 'saved:${v.id}',
          title: l10n.notifSavedDoneTitle,
          body: [
            if (settings.hideSongInfo)
              l10n.notifSavedDoneHidden
            else ...[
              _titleLine(v.hit.title, v.hit.uploader),
              l10n.notifSavedDoneNote,
            ],
            // 임시 저장은 파일이 아니라 앱 캐시다 (받기 완료의 "저장 위치"와 구분된다).
            l10n.notifSaveLocation(l10n.notifSaveLocationCache),
          ].join('\n'),
          failed: false,
          artUri: settings.hideSongInfo ? null : v.hit.thumbnailUrl,
        ),
      );
    }
  }

  // ── 받기 ──
  // 받기 큐와 그 알림(진행 · 결과 · 다시 시도)은 네이티브가 만든다 (앱이 꺼져 있어도 뜨도록). 여기서는 글과 설정만 넘긴다.

  String? _downloadConfigKey;

  /// 받기 알림에 쓸 글과 설정을 네이티브에 넘긴다 (바뀐 것만). 글의 `{p}` `{d}` `{n}` `{t}` `{f}`는 네이티브가 채운다.
  Future<void> syncDownloadConfig(
    NotificationSettings settings,
    AppLocalizations l10n,
  ) async {
    // 정수 칸의 자리표시: 글로 만든 뒤 `{…}`로 바꿔 네이티브가 값을 채우게 한다.
    const p = 987654, d = 987653, n = 987652;
    String tpl(String s) => s
        .replaceAll('$p', '{p}')
        .replaceAll('$d', '{d}')
        .replaceAll('$n', '{n}');
    final config = <String, Object?>{
      'hide': settings.hideSongInfo,
      'results': settings.downloadResult,
      'keepAlive': settings.backgroundDownload,
      'hiddenTitle': l10n.notifDownloadHiddenTitle,
      'doneTitle': l10n.notifDownloadDoneTitle,
      'doneHidden': l10n.notifDownloadDoneHidden,
      'failedTitle': l10n.notifDownloadFailedTitle,
      'failedHidden': l10n.notifDownloadFailedHidden,
      'retry': l10n.notifDownloadRetry,
      'preview': l10n.notifDownloadPreview,
      'stopPreview': l10n.notifDownloadStopPreview,
      'cancel': l10n.notifDownloadCancel,
      'pause': l10n.notifDownloadPause,
      'resume': l10n.notifDownloadResume,
      'progress': tpl(l10n.notifDownloadProgressBody(p)),
      'paused': tpl(l10n.notifDownloadPausedBody(p)),
      'progressNext': tpl(l10n.notifDownloadProgressNext(p, '{t}')),
      'overall': tpl(l10n.notifDownloadOverall(d, n, p)),
      'saveLocation': l10n.notifSaveLocation('{f}'),
    };
    final key = config.entries.map((e) => '${e.key}=${e.value}').join('|');
    if (key == _downloadConfigKey) return;
    _downloadConfigKey = key;
    await _actions.configureDownloads(config);
  }

  String? _previewing;

  /// 받는 곡을 미리 듣는 중인지 네이티브에 알린다 (받기 알림의 버튼이 바뀐다). 바뀐 것만 보낸다.
  Future<void> syncDownloadPreviewing(String? id) async {
    if (id == _previewing) return;
    _previewing = id;
    await _actions.setDownloadPreviewing(id);
  }

  /// 받기가 시작될 때 알림 권한을 한 번 묻는다 (네이티브가 알림을 띄우기 전에).
  Future<void> ensureDownloadPermission() => _ensurePermission();

  String _titleLine(String title, String artist) =>
      artist.isEmpty ? title : '$title · $artist';

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
    bool shuffle = false,
    DateTime? sleepEndsAt,
    int queueIndex = 0,
    int queueLength = 0,
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
    // 수면 타이머가 켜져 있으면 끝나는 시각을 부제목 끝에 붙인다 (시각은 고정이라 매초 갱신하지 않는다).
    String withSleep(String artist) {
      final end = sleepEndsAt;
      if (end == null) return artist;
      final hh = end.hour.toString().padLeft(2, '0');
      final mm = end.minute.toString().padLeft(2, '0');
      return '$artist · ${l10n.notifSleepAt('$hh:$mm')}';
    }

    final next = preview != null
        ? MediaSessionInfo(
            title: hide ? l10n.notifHiddenTitle : preview.title,
            artist: () {
              final label = l10n.notifPreviewLabel;
              if (hide) return '${l10n.notifHiddenNote} · $label';
              return preview.uploader.isEmpty
                  ? label
                  : '${preview.uploader} · $label';
            }(),
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
            // 숨김 중에는 곡이 넘어가는 걸 알 수 있게 대기열 속 순번을 보여 준다.
            artist: withSleep(
              hide
                  ? (queueLength > 1
                        ? l10n.notifHiddenNotePosition(
                            '${queueIndex + 1}',
                            '$queueLength',
                          )
                        : l10n.notifHiddenNote)
                  : (track!.artist.isEmpty ? l10n.unknownArtist : track.artist),
            ),
            album: hide ? '' : track!.album,
            artUri: hide ? null : artUri,
            duration: track!.duration,
            position: position,
            playing: isPlaying,
            hasPrevious: hasPrevious,
            hasNext: hasNext,
            favorite: favorite,
            shuffle: shuffle,
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
          last.shuffle == next.shuffle &&
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
