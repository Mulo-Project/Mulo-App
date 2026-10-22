import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/download_notifier.dart';
import '../../domain/usecases/notification_usecases.dart';

/// 앱 상태(받기 대기열 · 재생 상태)를 알림창에 옮긴다. 화면이 없고 상태도 없다:
/// 바뀐 것만 골라 알림 유스케이스를 부른다.
class NotificationSyncCubit extends Cubit<void> {
  NotificationSyncCubit(this._actions) : super(null);

  final NotificationActions _actions;

  /// 알림 · 잠금화면에서 누른 조작.
  Stream<MediaCommand> get commands => _actions.watchCommands(const NoParams());

  /// 받기 알림에서 누른 조작.
  Stream<DownloadNotificationAction> get downloadActions =>
      _actions.watchDownloadActions(const NoParams());

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

  // ── 받기 ──

  Map<String, DownloadStatus> _statuses = const {};
  var _progressShown = false;
  final _batch = <String>{};
  String? _lastProgress;

  /// 받기 대기열이 바뀔 때마다. 진행 알림은 한 개(지금 받는 곡)를 갱신하고,
  /// 끝남 · 실패는 상태가 바뀐 순간 곡마다 한 번씩 알린다.
  Future<void> syncDownloads(
    List<DownloadItem> items,
    NotificationSettings settings,
    AppLocalizations l10n, {
    String? previewingId,
  }) async {
    final before = _statuses;
    _statuses = {for (final i in items) i.id: i.status};
    final hide = settings.hideSongInfo;

    if (settings.downloadResult) {
      for (final i in items) {
        if (before[i.id] == i.status) continue;
        if (i.status == DownloadStatus.done) {
          await _ensurePermission();
          await _actions.showResult(
            DownloadResultNotice(
              id: i.id,
              title: l10n.notifDownloadDoneTitle,
              body: hide
                  ? l10n.notifDownloadDoneHidden
                  : _titleLine(i.title, i.artist),
              failed: false,
              artUri: hide ? null : i.thumbnailUrl,
            ),
          );
        } else if (i.status == DownloadStatus.failed) {
          await _ensurePermission();
          await _actions.showResult(
            DownloadResultNotice(
              id: i.id,
              title: l10n.notifDownloadFailedTitle,
              body: hide
                  ? l10n.notifDownloadFailedHidden
                  : [i.title, if (i.error.isNotEmpty) i.error].join('\n'),
              failed: true,
              artUri: hide ? null : i.thumbnailUrl,
            ),
          );
        }
      }
    } else {
      await _actions.clearResults(const NoParams());
    }

    DownloadItem? current;
    for (final i in items) {
      if (i.status == DownloadStatus.downloading) {
        current = i;
        break;
      }
    }
    final active = items.where((i) => i.isActive).toList();
    // 알림이 아직 없으면 받기를 시작한 직후(대기 → 받는 중 사이)에도 첫 대기 곡으로 바로 띄운다.
    current ??= _progressShown
        ? null
        : items.where((i) => i.status == DownloadStatus.queued).firstOrNull;
    // 한 묶음 = 대기열이 비었다가 다시 채워지기 전까지. 전체 진행률은 이 묶음 기준.
    if (active.isEmpty) {
      _batch.clear();
    } else {
      _batch.addAll(active.map((i) => i.id));
    }

    final keepAlive = settings.backgroundDownload;
    if (!(settings.downloadProgress || keepAlive) ||
        (current == null && active.isEmpty)) {
      await _clearProgress();
      return;
    }
    // 다음 곡으로 넘어가는 사이(받는 곡 없음, 대기만 있음)는 알림을 그대로 둔다.
    if (current == null) return;

    final batch = items
        .where(
          (i) => _batch.contains(i.id) && i.status != DownloadStatus.failed,
        )
        .toList();
    final done = batch.where((i) => i.status == DownloadStatus.done).length;
    final overall = batch.isEmpty
        ? 0.0
        : batch
                  .map(
                    (i) => i.status == DownloadStatus.done ? 1.0 : i.progress,
                  )
                  .reduce((a, b) => a + b) /
              batch.length;
    final overallPercent = (overall * 100).round().clamp(0, 100);
    final nextItem = items
        .where((i) => i.status == DownloadStatus.queued && i.id != current!.id)
        .firstOrNull;

    final percent = (current.progress * 100).round().clamp(0, 100);
    final title = hide ? l10n.notifDownloadHiddenTitle : current.title;
    final progressLine = nextItem != null && !hide
        ? l10n.notifDownloadProgressNext(percent, nextItem.title)
        : l10n.notifDownloadProgressBody(percent);
    final body = hide || current.artist.isEmpty
        ? progressLine
        : '${current.artist} · $progressLine';
    final subText = l10n.notifDownloadOverall(
      done,
      batch.length,
      overallPercent,
    );
    // 이 곡을 미리 듣는 중이면 미리듣기 버튼 자리를 중지 버튼으로 바꾼다.
    final previewing = !hide && previewingId == current.id;
    final preview = hide || previewing ? null : l10n.notifDownloadPreview;
    final stop = previewing ? l10n.notifDownloadStopPreview : null;
    final cancel = l10n.notifDownloadCancel;
    final art = hide ? null : current.thumbnailUrl;
    final key =
        '$title|$body|$subText|$overallPercent|$keepAlive|$preview|$stop|${current.id}|$art';
    if (_progressShown && key == _lastProgress) return;
    await _ensurePermission();
    _progressShown = true;
    _lastProgress = key;
    await _actions.showProgress(
      DownloadProgressNotice(
        title: title,
        body: body,
        percent: overallPercent,
        foreground: keepAlive,
        subText: subText,
        previewLabel: preview,
        cancelLabel: cancel,
        stopLabel: stop,
        openId: current.id,
        artUri: art,
      ),
    );
  }

  Future<void> _clearProgress() async {
    if (!_progressShown) return;
    _progressShown = false;
    _lastProgress = null;
    await _actions.clearProgress(const NoParams());
  }

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
